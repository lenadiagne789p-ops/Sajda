import 'dart:convert';

class NpmSalatMedia {
  final List<String> imageUrls;
  final List<NpmAudioItem> audios;
  final DateTime fetchedAt;

  NpmSalatMedia({required this.imageUrls, required this.audios, required this.fetchedAt});

  Map<String, dynamic> toJson() => {
        'imageUrls': imageUrls,
        'audios': audios.map((e) => e.toJson()).toList(),
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  static NpmSalatMedia fromJson(Map<String, dynamic> json) {
    return NpmSalatMedia(
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      audios: (json['audios'] as List<dynamic>? ?? const []).map((e) => NpmAudioItem.fromJson(e as Map<String, dynamic>)).toList(),
      fetchedAt: DateTime.tryParse(json['fetchedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static String encode(NpmSalatMedia data) => jsonEncode(data.toJson());
  static NpmSalatMedia decode(String source) => fromJson(jsonDecode(source) as Map<String, dynamic>);
}

class NpmAudioItem {
  final String url;
  final String title;

  NpmAudioItem({required this.url, required this.title});

  Map<String, dynamic> toJson() => {
        'url': url,
        'title': title,
      };

  static NpmAudioItem fromJson(Map<String, dynamic> json) {
    return NpmAudioItem(
      url: json['url']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
    );
  }
}
