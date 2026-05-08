import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// All OpenAI related code must live in this file.

// Resolved at runtime from environment variables (Dreamflow handles configuration)
const apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
const endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');

class OpenAIClient {
  OpenAIClient._();
  static final OpenAIClient instance = OpenAIClient._();

  /// Ask the assistant about the app or religion. Answers should be concise and cite reputable Islamic sources.
  /// Locale should be 'fr' or 'ar' to shape the answer language.
  Future<String> askAppAndReligion({
    required String question,
    required String locale,
  }) async {
    if (apiKey.isEmpty || endpoint.isEmpty) {
      throw Exception('Configuration OpenAI manquante.');
    }

    // Build a careful system instruction. We use the Responses API (not chat/completions).
    final lang = (locale == 'ar') ? 'ar' : 'fr';
    final systemPrompt = _systemPromptFor(lang);

    final url = _buildUrl(endpoint, 'responses');
    final body = {
      'model': 'gpt-4o',
      // Single-turn input with a light system preamble. The Responses API accepts a string in `input`.
      'input': 'SYSTEM:\n$systemPrompt\n\nUSER:\n$question',
      'temperature': 0.2,
      'max_output_tokens': 700,
    };

    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $apiKey',
      'Accept': 'application/json',
    };

    try {
      final resp = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 35));

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        // Try to extract error message from body if possible
        String message = 'Erreur OpenAI (${resp.statusCode})';
        try {
          final obj = json.decode(utf8.decode(resp.bodyBytes));
          if (obj is Map && obj['error'] != null) {
            message = obj['error'].toString();
          }
        } catch (_) {}
        throw Exception(message);
      }

      final raw = utf8.decode(resp.bodyBytes);
      final data = json.decode(raw);

      // Try multiple known shapes to extract text safely.
      String? text = _extractText(data);

      if (text != null && text.isNotEmpty) {
        return text;
      }

      // If Responses returns no text, try a compatibility fallback with chat/completions
      if (kDebugMode) {
        // ignore: avoid_print
        print('OpenAI responses returned empty. Trying chat/completions fallback. Raw: ${raw.substring(0, raw.length > 350 ? 350 : raw.length)}');
      }
      final fallback = await _askViaChatCompletions(systemPrompt: systemPrompt, question: question, headers: headers);
      if (fallback != null && fallback.trim().isNotEmpty) {
        return fallback.trim();
      }

      // Still nothing; surface a normalized error for the UI to localize.
      throw Exception('EMPTY_OUTPUT');
    } on TimeoutException {
      throw Exception('Délai dépassé. Vérifiez votre connexion et réessayez.');
    }
  }

  // Extract text from a variety of possible payload shapes
  String? _extractText(dynamic data) {
    String? text;

    if (data is Map && data['output_text'] is String) {
      text = (data['output_text'] as String).trim();
      if (text.isNotEmpty) return text;
    }

    if (data is Map && data['output'] is List) {
      final output = data['output'] as List;
      final buffer = StringBuffer();
      for (final item in output) {
        if (item is Map && item['content'] is List) {
          for (final c in (item['content'] as List)) {
            if (c is Map) {
              // responses: {type: 'output_text', text: '...'} or {type: 'text', text: '...'}
              final t1 = c['text'];
              if (t1 is String && t1.trim().isNotEmpty) buffer.write(t1);
              if (c['type'] == 'output_text' && c['text'] is String && (c['text'] as String).trim().isNotEmpty) {
                buffer.write(c['text']);
              }
              // messages-like: {type:'message', content:[{type:'text', text:'...'}]}
              final content = c['content'];
              if (content is List) {
                for (final cc in content) {
                  if (cc is Map && cc['type'] == 'text' && cc['text'] is String) {
                    final t2 = (cc['text'] as String).trim();
                    if (t2.isNotEmpty) buffer.write(t2);
                  }
                }
              }
            }
          }
        }
      }
      final s = buffer.toString().trim();
      if (s.isNotEmpty) return s;
    }

    // Some proxies map responses to chat/completions structure
    if (data is Map && data['choices'] is List) {
      final choices = data['choices'] as List;
      if (choices.isNotEmpty) {
        final ch0 = choices.first;
        if (ch0 is Map) {
          final message = ch0['message'];
          if (message is Map) {
            final content = message['content'];
            if (content is String) {
              final s = content.trim();
              if (s.isNotEmpty) return s;
            } else if (content is List) {
              // Newer content array format
              final buf = StringBuffer();
              for (final part in content) {
                if (part is Map && part['type'] == 'text' && part['text'] is String) {
                  final s = (part['text'] as String).trim();
                  if (s.isNotEmpty) buf.write(s);
                }
              }
              final out = buf.toString().trim();
              if (out.isNotEmpty) return out;
            }
          }
          if (ch0['text'] is String) {
            final s = (ch0['text'] as String).trim();
            if (s.isNotEmpty) return s;
          }
        }
      }
    }

    // Generic top-level content
    if (data is Map && data['content'] is List) {
      final content = data['content'] as List;
      for (final c in content) {
        if (c is Map && c['text'] is String) {
          final s = (c['text'] as String).trim();
          if (s.isNotEmpty) return s;
        }
      }
    }

    // Nothing found
    return null;
  }

  // Compatibility fallback: try chat/completions with messages
  Future<String?> _askViaChatCompletions({
    required String systemPrompt,
    required String question,
    required Map<String, String> headers,
  }) async {
    final url = _buildUrl(endpoint, 'chat/completions');
    final body = {
      'model': 'gpt-4o',
      'temperature': 0.2,
      'messages': [
        {
          'role': 'system',
          'content': systemPrompt,
        },
        {
          'role': 'user',
          'content': question,
        },
      ],
    };

    try {
      final resp = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 35));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return null;
      }
      final raw = utf8.decode(resp.bodyBytes);
      final data = json.decode(raw);
      final extracted = _extractText(data);
      return extracted?.trim();
    } catch (_) {
      return null;
    }
  }

  static Uri _buildUrl(String base, String path) {
    // Ensure single slash joining and allow base to contain path already.
    final normalized = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return Uri.parse('$normalized/$path');
  }

  static String _systemPromptFor(String lang) {
    if (lang == 'ar') {
      return (
        'أنت مساعد ودود داخل تطبيق "سجدة".\n'
        '- أجب بإيجاز وباللغة العربية الفصحى الواضحة.\n'
        '- لأسئلة التطبيق: اشرح الميزات، الملاحة، الاشتراكات، الإعدادات، وإصلاح المشاكل بخطوات دقيقة.\n'
        '- لأسئلة الدين: استند إلى مصادر إسلامية موثوقة فقط (مثل islamqa.info، al-islam.com، quran.com، sunnah.com، dorar.net، islamweb.net، alukah.net).\n'
        '- اذكر 2–4 مراجع/روابط عند الإمكان. إذا لم تكن واثقًا، قل أنك غير متأكد ولا تؤلف.\n'
        '- تجنب الفتاوى الحساسة: إن لزم، اقترح الرجوع لعالِم/إمام موثوق.'
      );
    }
    // default FR
    return (
      'Tu es un assistant bienveillant intégré à l’app “Sajda”.\n'
      '- Réponds de façon concise en français clair.\n'
      '- Pour les questions sur l’app: explique les fonctionnalités, la navigation, les abonnements, les réglages et les dépannages en étapes précises.\n'
      '- Pour les questions religieuses: base-toi uniquement sur des sources islamiques fiables (ex. islamqa.info, al-islam.com, quran.com, sunnah.com, dorar.net, islamweb.net, alukah.net).\n'
      '- Cite 2–4 sources/liens quand c’est pertinent. Si tu n’es pas certain, dis-le honnêtement et n’invente rien.\n'
      '- Évite les avis juridiques sensibles: le cas échéant, conseille de consulter un imam/érudit.'
    );
  }
}
