class User {
  final String id;
  final String name;
  /// Optional URL to the user's avatar image (network URL or data URL)
  final String? avatarUrl;
  final int totalHassanat;
  final int currentLevel;
  final int streak;
  final DateTime lastActivityDate;
  final bool isPremium;

  User({
    String? id,
    required this.name,
    this.avatarUrl,
    required this.totalHassanat,
    required this.currentLevel,
    required this.streak,
    required this.lastActivityDate,
    this.isPremium = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  String get spiritualLevel {
    if (totalHassanat < 100) return "Serviteur dévoué";
    if (totalHassanat < 500) return "Aspirant";
    if (totalHassanat < 1500) return "Pieux";
    if (totalHassanat < 5000) return "Bienfaisant";
    return "Rapproché d'Allah";
  }

  int get progressInCurrentLevel {
    if (totalHassanat < 100) return totalHassanat;
    if (totalHassanat < 500) return totalHassanat - 100;
    if (totalHassanat < 1500) return totalHassanat - 500;
    if (totalHassanat < 5000) return totalHassanat - 1500;
    return totalHassanat - 5000;
  }

  int get nextLevelTarget {
    if (totalHassanat < 100) return 100;
    if (totalHassanat < 500) return 500;
    if (totalHassanat < 1500) return 1500;
    if (totalHassanat < 5000) return 5000;
    return totalHassanat + 1000;
  }

  double get levelProgress {
    if (totalHassanat < 100) return totalHassanat / 100.0;
    if (totalHassanat < 500) return (totalHassanat - 100) / 400.0;
    if (totalHassanat < 1500) return (totalHassanat - 500) / 1000.0;
    if (totalHassanat < 5000) return (totalHassanat - 1500) / 3500.0;
    return 1.0;
  }

  User copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    int? totalHassanat,
    int? currentLevel,
    int? streak,
    DateTime? lastActivityDate,
    bool? isPremium,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalHassanat: totalHassanat ?? this.totalHassanat,
      currentLevel: currentLevel ?? this.currentLevel,
      streak: streak ?? this.streak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'totalHassanat': totalHassanat,
      'currentLevel': currentLevel,
      'streak': streak,
      // Stocke les dates sous forme de chaînes ISO pour rester 100% locales
      'lastActivityDate': lastActivityDate.toIso8601String(),
      'isPremium': isPremium,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  static User fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }
    return User(
      id: json['id'],
      // Avoid placeholder label; prefer empty string when unknown
      name: (json['name'] as String?)?.trim() ?? '',
      avatarUrl: json['avatarUrl'],
      totalHassanat: json['totalHassanat'] ?? 0,
      currentLevel: json['currentLevel'] ?? 0,
      streak: json['streak'] ?? 0,
      lastActivityDate: parseDate(json['lastActivityDate']),
      isPremium: json['isPremium'] ?? false,
    );
  }
}