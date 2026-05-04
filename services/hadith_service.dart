import 'dart:math';

/// Modèle d'un hadith.
class Hadith {
  final String text;
  final String source;
  final String? narrator;

  const Hadith({
    required this.text,
    required this.source,
    this.narrator,
  });
}

/// Service qui fournit un hadith du jour (rotation quotidienne).
class HadithService {
  HadithService._();

  static const List<Hadith> _hadiths = [
    Hadith(
      text:
          "Les actions ne valent que par les intentions, et chaque homme n'aura que ce qu'il a eu l'intention de faire.",
      source: "Sahih Al-Bukhari & Muslim",
      narrator: "Omar ibn Al-Khattab (رضي الله عنه)",
    ),
    Hadith(
      text:
          "Le musulman est celui dont les musulmans sont préservés de sa langue et de sa main.",
      source: "Sahih Al-Bukhari",
      narrator: "Abdallah ibn Amr (رضي الله عنه)",
    ),
    Hadith(
      text:
          "Facilitez et ne compliquez pas, annoncez la bonne nouvelle et ne faites pas fuir.",
      source: "Sahih Al-Bukhari & Muslim",
      narrator: "Anas ibn Malik (رضي الله عنه)",
    ),
    Hadith(
      text:
          "Aucun de vous ne croit vraiment tant qu'il n'aime pas pour son frère ce qu'il aime pour lui-même.",
      source: "Sahih Al-Bukhari & Muslim",
      narrator: "Anas ibn Malik (رضي الله عنه)",
    ),
    Hadith(
      text:
          "Le meilleur d'entre vous est celui qui a le meilleur caractère.",
      source: "Sahih Al-Bukhari",
      narrator: "Abdallah ibn Amr (رضي الله عنه)",
    ),
    Hadith(
      text:
          "Souriez à votre frère, c'est une aumône. Ordonner le bien et interdire le mal, c'est une aumône.",
      source: "Sunan At-Tirmidhi",
      narrator: "Abu Dharr Al-Ghifari (رضي الله عنه)",
    ),
    Hadith(
      text:
          "Celui qui croit en Allah et au Jour Dernier doit dire du bien ou se taire.",
      source: "Sahih Al-Bukhari & Muslim",
      narrator: "Abu Hurayra (رضي الله عنه)",
    ),
    Hadith(
      text:
          "La force n'est pas dans la lutte physique. La vraie force est de se maîtriser soi-même dans la colère.",
      source: "Sahih Al-Bukhari & Muslim",
      narrator: "Abu Hurayra (رضي الله عنه)",
    ),
    Hadith(
      text:
          "Cherchez la connaissance, même en Chine.",
      source: "Hadith rapporté par Ibn Adiy",
      narrator: "Anas ibn Malik (رضي الله عنه)",
    ),
    Hadith(
      text:
          "Soyez dans ce monde comme un étranger ou un voyageur de passage.",
      source: "Sahih Al-Bukhari",
      narrator: "Abdallah ibn Omar (رضي الله عنه)",
    ),
    Hadith(
      text:
          "Profitez de cinq choses avant cinq autres : ta jeunesse avant ta vieillesse, ta santé avant ta maladie, ta richesse avant ta pauvreté, ton temps libre avant tes occupations, et ta vie avant ta mort.",
      source: "Mustadrak Al-Hakim",
      narrator: "Ibn Abbas (رضي الله عنه)",
    ),
    Hadith(
      text:
          "La meilleure des aumônes est celle que donne celui qui a peu.",
      source: "Sunan Abu Dawud",
      narrator: "Abu Hurayra (رضي الله عنه)",
    ),
    Hadith(
      text:
          "Celui qui suit un chemin pour acquérir la connaissance, Allah lui facilitera un chemin vers le Paradis.",
      source: "Sahih Muslim",
      narrator: "Abu Hurayra (رضي الله عنه)",
    ),
    Hadith(
      text:
          "Remettez-vous en à Allah et vous verrez que les choses s'arrangeront.",
      source: "Sunan At-Tirmidhi",
      narrator: "Omar ibn Al-Khattab (رضي الله عنه)",
    ),
    Hadith(
      text:
          "Parmi les bonnes choses de l'Islam d'un homme, c'est de délaisser ce qui ne le concerne pas.",
      source: "Sunan At-Tirmidhi",
      narrator: "Abu Hurayra (رضي الله عنه)",
    ),
  ];

  /// Retourne le hadith du jour (change chaque jour).
  static Hadith getHadithForToday() {
    final now = DateTime.now();
    // Utilise le numéro du jour de l'année pour la rotation
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _hadiths.length;
    return _hadiths[index];
  }

  /// Retourne un hadith aléatoire.
  static Hadith getRandomHadith() {
    final rng = Random();
    return _hadiths[rng.nextInt(_hadiths.length)];
  }
}
