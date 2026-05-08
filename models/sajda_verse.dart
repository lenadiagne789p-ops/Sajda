class SajdaVerse {
  final int number;
  final String text;
  final int surahNumber;
  final String surahName;
  final String surahEnglishName;
  final String revelation;
  final int juz;
  final int manzil;
  final int page;
  final int ruku;
  final int hizbQuarter;
  final bool sajda;
  final String edition;

  SajdaVerse({
    required this.number,
    required this.text,
    required this.surahNumber,
    required this.surahName,
    required this.surahEnglishName,
    required this.revelation,
    required this.juz,
    required this.manzil,
    required this.page,
    required this.ruku,
    required this.hizbQuarter,
    required this.sajda,
    required this.edition,
  });

  factory SajdaVerse.fromJson(Map<String, dynamic> json) {
    return SajdaVerse(
      number: json['numberInSurah'] ?? json['number'] ?? 0,
      text: json['text'] ?? '',
      surahNumber: json['surah']?['number'] ?? 0,
      surahName: json['surah']?['name'] ?? '',
      surahEnglishName: json['surah']?['englishName'] ?? '',
      revelation: json['surah']?['revelationType'] ?? '',
      juz: json['juz'] ?? 0,
      manzil: json['manzil'] ?? 0,
      page: json['page'] ?? 0,
      ruku: json['ruku'] ?? 0,
      hizbQuarter: json['hizbQuarter'] ?? 0,
      sajda: json['sajda'] ?? false,
      edition: json['edition']?['identifier'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'text': text,
      'surah': {
        'number': surahNumber,
        'name': surahName,
        'englishName': surahEnglishName,
        'revelationType': revelation,
      },
      'juz': juz,
      'manzil': manzil,
      'page': page,
      'ruku': ruku,
      'hizbQuarter': hizbQuarter,
      'sajda': sajda,
      'edition': {
        'identifier': edition,
      },
    };
  }
}

class SajdaResponse {
  final int code;
  final String status;
  final List<SajdaVerse> data;

  SajdaResponse({
    required this.code,
    required this.status,
    required this.data,
  });

  factory SajdaResponse.fromJson(Map<String, dynamic> json) {
    return SajdaResponse(
      code: json['code'] ?? 200,
      status: json['status'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((verse) => SajdaVerse.fromJson(verse))
              .toList() ??
          [],
    );
  }
}