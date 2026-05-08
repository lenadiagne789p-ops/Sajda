import 'package:flutter/material.dart';
import 'package:sajda/openai/openai_config.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/widgets/ui/sparkle_icon.dart';
import 'package:sajda/utils/language_controller.dart';

class ChatAssistantSheet extends StatefulWidget {
  const ChatAssistantSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      builder: (ctx) {
        return const FractionallySizedBox(
          heightFactor: 0.9,
          child: ChatAssistantSheet(),
        );
      },
    );
  }

  @override
  State<ChatAssistantSheet> createState() => _ChatAssistantSheetState();
}

class _ChatAssistantSheetState extends State<ChatAssistantSheet> {
  final List<_Msg> _messages = <_Msg>[
    _Msg(
      role: _Role.assistant,
      textFR: 'Salam, je suis votre assistant. Posez une question sur l’app ou la religion. Je citerai des sources islamiques fiables lorsque c’est possible.',
      textAR: 'السلام عليكم، أنا مساعدكم. اطرح أي سؤال عن التطبيق أو عن الدين. سأذكر مصادر إسلامية موثوقة عندما يكون ذلك ممكنًا.',
    ),
  ];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _lang => LanguageController.locale.value.languageCode == 'ar' ? 'ar' : 'fr';

  Future<void> _send() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _messages.add(_Msg(role: _Role.user, text: raw));
    });
    _controller.clear();
    _autoScroll();

    try {
      final answer = await OpenAIClient.instance.askAppAndReligion(question: raw, locale: _lang);
      final safe = (answer).trim();
      setState(() {
        _messages.add(_Msg(
          role: _Role.assistant,
          text: safe.isNotEmpty
              ? safe
              : (_lang == 'ar'
                  ? 'عذرًا، لم أتمكّن من توليد إجابة هذه المرة. حاول إعادة الصياغة.'
                  : 'Désolé, je n’ai pas pu générer de réponse cette fois. Reformulez votre question.'),
        ));
        _sending = false;
      });
    } catch (e) {
      // Log the original error to the console for debugging, but keep the UI friendly.
      // ignore: avoid_print
      print('ChatAssistant error: ${e.toString()}');
      final friendly = _lang == 'ar'
          ? 'عذرًا، تعذّر الحصول على الرد الآن. حاول مرة أخرى أو أعد صياغة سؤالك.'
          : 'Désolé, impossible d’obtenir une réponse pour le moment. Réessayez ou reformulez votre question.';
      setState(() {
        _messages.add(_Msg(role: _Role.assistant, text: friendly));
        _sending = false;
      });
    }
    _autoScroll();
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = _lang == 'ar';

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: const BoxDecoration(
            gradient: AppGradients.emeraldAurora,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SparkleIcon(
                  icon: Icons.auto_awesome_rounded,
                  size: 22,
                  color: Colors.white,
                  haloColor: IslamicColors.roseGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'مساعد سجدة' : 'Assistant Sajda',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic ? 'يركز على مصادر إسلامية موثوقة' : 'Guidé par des sources islamiques fiables',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final m = _messages[index];
              final isUser = m.role == _Role.user;
              final t = m.textFor(_lang);
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                  decoration: BoxDecoration(
                    color: isUser
                        ? IslamicColors.emeraldGreen
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isUser
                          ? Colors.transparent
                          : IslamicColors.emeraldGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    t,
                    textAlign: isUser ? TextAlign.right : TextAlign.left,
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                  ),
                ),
              );
            },
          ),
        ),
        // Input
        Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            top: 4,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: isArabic ? 'اكتب سؤالك هنا...' : 'Écrivez votre question...',
                    prefixIcon: const Icon(Icons.edit, color: IslamicColors.emeraldGreen),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                label: Text(isArabic ? 'إرسال' : 'Envoyer', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _Role { user, assistant }

class _Msg {
  final _Role role;
  final String? text; // used for dynamic messages
  final String? textFR; // default greeting FR
  final String? textAR; // default greeting AR

  _Msg({required this.role, this.text, this.textFR, this.textAR});

  String textFor(String lang) {
    if (text != null) return text!;
    if (lang == 'ar') return textAR ?? '';
    return textFR ?? '';
  }
}
