import 'package:flutter/material.dart';

class DhikrItem {
  final String id;
  final String arabic;
  final String transliteration;
  final String french;
  final String meaning;
  final String benefit; // Spiritual benefit/virtue description
  final String? reference; // Optional hadith/source reference
  final int targetCount;
  final int currentCount;
  final int hassanatPerRecitation;
  final IconData icon;
  final Color color;

  DhikrItem({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.french,
    required this.meaning,
    required this.benefit,
    this.reference,
    required this.targetCount,
    this.currentCount = 0,
    required this.hassanatPerRecitation,
    required this.icon,
    required this.color,
  });

  DhikrItem copyWith({
    String? id,
    String? arabic,
    String? transliteration,
    String? french,
    String? meaning,
    String? benefit,
    String? reference,
    int? targetCount,
    int? currentCount,
    int? hassanatPerRecitation,
    IconData? icon,
    Color? color,
  }) {
    return DhikrItem(
      id: id ?? this.id,
      arabic: arabic ?? this.arabic,
      transliteration: transliteration ?? this.transliteration,
      french: french ?? this.french,
      meaning: meaning ?? this.meaning,
      benefit: benefit ?? this.benefit,
      reference: reference ?? this.reference,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      hassanatPerRecitation: hassanatPerRecitation ?? this.hassanatPerRecitation,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  double get progress => currentCount / targetCount;
  bool get isCompleted => currentCount >= targetCount;
  int get totalHassanat => currentCount * hassanatPerRecitation;
  int get remainingCount => (targetCount - currentCount).clamp(0, targetCount);

  static List<DhikrItem> getDefaultDhikrList() {
    return [
      DhikrItem(
        id: 'subhanallah',
        arabic: 'سُبْحَانَ اللَّهِ',
        transliteration: 'Subhān Allāh',
        french: 'Gloire à Allah',
        meaning: 'Allah est exempt de tout défaut',
        benefit: '''Exalte la perfection d'Allah et purifie la langue. Ce tasbih apaise le cœur et compte parmi les paroles les plus aimées d'Allah.''',
        reference: 'Muslim',
        targetCount: 33,
        hassanatPerRecitation: 1,
        icon: Icons.eco,
        color: const Color(0xFF4CAF50),
      ),
      DhikrItem(
        id: 'alhamdulillah',
        arabic: 'الْحَمْدُ لِلَّهِ',
        transliteration: 'Al-hamdu li-llāh',
        french: 'Louange à Allah',
        meaning: 'Toute louange appartient à Allah',
        benefit: '''Ancre la gratitude et attire davantage de bienfaits. «Al-ḥamdu li-llāh remplit la Balance» (le Jour du Jugement).''',
        reference: 'Muslim',
        targetCount: 33,
        hassanatPerRecitation: 1,
        icon: Icons.favorite,
        color: const Color(0xFFE91E63),
      ),
      DhikrItem(
        id: 'allahu_akbar',
        arabic: 'اللَّهُ أَكْبَرُ',
        transliteration: 'Allāhu akbar',
        french: 'Allah est le plus grand',
        meaning: 'Allah est le plus grand',
        benefit: '''Renforce la conscience de la grandeur d'Allah au-dessus de toute chose et dissipe la peur et l'angoisse.''',
        reference: 'Bukhari',
        targetCount: 34,
        hassanatPerRecitation: 1,
        icon: Icons.star,
        color: const Color(0xFFFF9800),
      ),
      DhikrItem(
        id: 'la_ilaha_illa_allah',
        arabic: 'لَا إِلَهَ إِلَّا اللَّهُ',
        transliteration: 'Lā ilāha illā-llāh',
        french: "Il n'y a de divinité qu'Allah",
        meaning: "Il n'y a de divinité digne d'adoration qu'Allah",
        benefit: '''La meilleure parole. Renouvelle l'allégeance (tawḥīd), allège les péchés et ouvre les portes du Paradis pour celui qui la dit sincèrement.''',
        reference: 'Tirmidhī, Aḥmad',
        targetCount: 100,
        hassanatPerRecitation: 2,
        icon: Icons.auto_awesome,
        color: const Color(0xFF673AB7),
      ),
      DhikrItem(
        id: 'istighfar',
        arabic: 'أَسْتَغْفِرُ اللَّهَ',
        transliteration: 'Astaghfiru-llāh',
        french: 'Je demande pardon à Allah',
        meaning: "Je cherche le pardon d'Allah",
        benefit: '''Efface les fautes, attire la subsistance et la miséricorde. Le Prophète ﷺ demandait pardon plus de 70 fois par jour.''',
        reference: 'Bukhari',
        targetCount: 100,
        hassanatPerRecitation: 1,
        icon: Icons.healing,
        color: const Color(0xFF009688),
      ),
      DhikrItem(
        id: 'salawat',
        arabic: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
        transliteration: 'Allāhumma salli wa-sallim ʿalā nabiyyinā Muhammad',
        french: 'Ô Allah, bénis et salue notre Prophète Muhammad',
        meaning: 'Invocation de bénédictions sur le Prophète',
        benefit: '''Pour chaque prière sur le Prophète ﷺ, Allah prie sur toi dix fois, élève tes degrés et efface tes péchés.''',
        reference: 'Muslim',
        targetCount: 10,
        hassanatPerRecitation: 10,
        icon: Icons.favorite_border,
        color: const Color(0xFF3F51B5),
      ),
      DhikrItem(
        id: 'la_hawla',
        arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
        transliteration: 'Lā hawla wa-lā quwwata illā bi-llāh',
        french: "Il n'y a de pouvoir et de force qu'en Allah",
        meaning: "Toute force et tout pouvoir viennent d'Allah seul",
        benefit: '''Réduit l'anxiété et renforce la confiance en Allah. Elle fait partie des trésors du Paradis.''',
        reference: 'Bukhari, Muslim',
        targetCount: 10,
        hassanatPerRecitation: 5,
        icon: Icons.diamond,
        color: const Color(0xFF795548),
      ),
      DhikrItem(
        id: 'hasbi_allah',
        arabic: 'حَسْبِيَ اللَّهُ وَنِعْمَ الْوَكِيلُ',
        transliteration: 'Hasbiya-llāhu wa-niʿma-l-wakīl',
        french: 'Allah me suffit, Il est le meilleur garant',
        meaning: "Je m'en remets entièrement à Allah",
        benefit: '''Renforce le tawakkul (confiance) et apporte la suffisance divine face aux épreuves.''',
        reference: 'Coran 3:173',
        targetCount: 7,
        hassanatPerRecitation: 3,
        icon: Icons.security,
        color: const Color(0xFF607D8B),
      ),
      DhikrItem(
        id: 'ayat_kursi',
        arabic: 'آيَة الْكُرْسِيّ',
        transliteration: 'Āyat al-Kursī',
        french: 'Verset du Trône',
        meaning: 'Le plus grand verset du Coran (2:255)',
        benefit: '''Protection contre le mal, élévation du rang et garde d'un ange jusqu'au matin/soir selon le moment.''',
        reference: 'Bukhari',
        targetCount: 3,
        hassanatPerRecitation: 50,
        icon: Icons.castle,
        color: const Color(0xFF1B5E20),
      ),
      DhikrItem(
        id: 'morning_adhkar',
        arabic: 'أَذْكَار الصَّبَاح',
        transliteration: 'Adhkār al-sabāh',
        french: 'Invocations du matin',
        meaning: "Ensemble d'invocations à réciter le matin",
        benefit: '''Série prophétique assurant protection, sérénité et bénédictions jusqu'au soir.''',
        reference: 'Sunan',
        targetCount: 1,
        hassanatPerRecitation: 100,
        icon: Icons.wb_sunny,
        color: const Color(0xFFFFEB3B),
      ),
      DhikrItem(
        id: 'evening_adhkar',
        arabic: 'أَذْكَار الْمَسَاء',
        transliteration: 'Adhkār al-masāʾ',
        french: 'Invocations du soir',
        meaning: "Ensemble d'invocations à réciter le soir",
        benefit: '''Protège jusqu'au matin, apaise le cœur et clôture la journée dans le rappel d'Allah.''',
        reference: 'Sunan',
        targetCount: 1,
        hassanatPerRecitation: 100,
        icon: Icons.nights_stay,
        color: const Color(0xFF3F51B5),
      ),
      // Additions
      DhikrItem(
        id: 'subhan_bihamdihi_100',
        arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
        transliteration: 'Subḥānallāhi wa bi-ḥamdih',
        french: 'Gloire et louange à Allah',
        meaning: 'Dhikr très méritoire effaçant les péchés',
        benefit: '''Efface les péchés même s'ils sont comme l'écume de la mer.''',
        reference: 'Bukhari, Muslim',
        targetCount: 100,
        hassanatPerRecitation: 1,
        icon: Icons.water_drop,
        color: const Color(0xFF4CAF50),
      ),
      DhikrItem(
        id: 'subhan_bihamdihi_azim',
        arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
        transliteration: 'Subḥānallāhi wa bi-ḥamdih, subḥānallāhi-l-ʿaẓīm',
        french: 'Gloire et louange à Allah, gloire à Allah le Suprême',
        meaning: 'Deux phrases aimées du Tout Miséricordieux',
        benefit: '''Paroles légères sur la langue, lourdes dans la Balance et aimées du Tout Miséricordieux.''',
        reference: 'Bukhari, Muslim',
        targetCount: 100,
        hassanatPerRecitation: 2,
        icon: Icons.auto_awesome_mosaic,
        color: const Color(0xFF8BC34A),
      ),
      DhikrItem(
        id: 'sayyid_istighfar',
        arabic: 'اللّهُمَّ أَنْتَ رَبِّي لا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي، فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
        transliteration: '''Allāhumma anta rabbī, lā ilāha illā anta, khalaqtanī wa-anā ʿabduka, wa-anā ʿalā ʿahdika wa-waʿdika mā istaṭaʿtu, aʿūdhu bika min sharri mā ṣanaʿtu, abū'u laka bi niʿmatika ʿalayya, wa abū'u bi dhanbī, faghfir lī, fa innahu lā yaghfiru adh-dhunūba illā anta.''',
        french: 'Maître des implorations du pardon (formule complète)',
        meaning: 'La meilleure formule pour demander pardon',
        benefit: '''Qui le dit le matin ou le soir avec conviction et meurt ce jour-là, entrera au Paradis.''',
        reference: 'Bukhari',
        targetCount: 1,
        hassanatPerRecitation: 50,
        icon: Icons.healing,
        color: const Color(0xFF00796B),
      ),
      DhikrItem(
        id: 'bismillah_protection',
        arabic: 'بِسْمِ اللَّهِ الَّذِي لا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
        transliteration: 'Bismi-llāhi alladhī lā yaḍurru maʿa-smihi shayʾun fī-l-arḍi wa-lā fī-s-samāʾ',
        french: "Au nom d'Allah, avec le Nom duquel rien ne peut nuire sur terre ni au ciel; Il est l'Audient, l'Omniscient",
        meaning: 'Formule de protection recommandée matin et soir',
        benefit: '''Par la permission d'Allah, rien ne nuira à celui qui la dit trois fois le matin et le soir.''',
        reference: 'Abū Dāwūd',
        targetCount: 3,
        hassanatPerRecitation: 5,
        icon: Icons.shield,
        color: const Color(0xFF009688),
      ),
      DhikrItem(
        id: 'la_ilaha_wahdahu_100',
        arabic: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
        transliteration: 'Lā ilāha illā Allāhu waḥdahu lā sharīka lah, lahu al-mulku wa lahu al-ḥamd, wa huwa ʿalā kulli shayʾin qadīr',
        french: "Nulle divinité autre qu'Allah, Seul sans associé; à Lui la royauté et la louange, et Il est capable de toute chose",
        meaning: 'Formule de tawhid à répéter 100 fois',
        benefit: '''Équivaut à affranchir dix esclaves, inscrit cent bonnes actions et efface cent mauvaises, et protège toute la journée.''',
        reference: 'Bukhari, Muslim',
        targetCount: 100,
        hassanatPerRecitation: 2,
        icon: Icons.workspace_premium,
        color: const Color(0xFF33691E),
      ),
      DhikrItem(
        id: 'dua_yunus',
        arabic: 'لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
        transliteration: 'Lā ilāha illā anta subḥānaka innī kuntu mina-ẓ-ẓālimīn',
        french: "Nul autre dieu que Toi, gloire à Toi ! J'étais certes parmi les injustes",
        meaning: 'Invocation de Yūnus (as) pour les détresses',
        benefit: '''Invocation des affligés: Allah dissipe les épreuves de celui qui l'invoque par cette formule.''',
        reference: 'Aḥmad, Tirmidhī',
        targetCount: 40,
        hassanatPerRecitation: 3,
        icon: Icons.waves,
        color: const Color(0xFF3F51B5),
      ),
      // New adhkar
      DhikrItem(
        id: 'astaghfirullah_wa_atubu',
        arabic: 'أَسْتَغْفِرُ اللهَ وَأَتُوبُ إِلَيْهِ',
        transliteration: 'Astaghfiru-llāha wa atūbu ilayh',
        french: 'Je demande pardon à Allah et je me repens vers Lui',
        meaning: 'Formule de repentir complète et insistante',
        benefit: '''Le repentir sincère est aimé d'Allah et transforme les fautes en bonnes actions par Sa grâce.''',
        reference: 'Bukhari, Muslim',
        targetCount: 100,
        hassanatPerRecitation: 2,
        icon: Icons.healing,
        color: const Color(0xFF00695C),
      ),
      DhikrItem(
        id: 'tasbih_tahmid_tahlil_takbir',
        arabic: 'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
        transliteration: 'Subḥānallāh, wal-ḥamdu li-llāh, wa lā ilāha illā Allāh, wa-llāhu akbar',
        french: 'Gloire à Allah, louange à Allah, il n’y a de divinité qu’Allah, et Allah est le plus grand',
        meaning: 'Formule globale très méritoire',
        benefit: '''Plantent des palmiers au Paradis et sont parmi les formules les plus aimées d'Allah.''',
        reference: 'Tirmidhī',
        targetCount: 100,
        hassanatPerRecitation: 2,
        icon: Icons.park,
        color: const Color(0xFF2E7D32),
      ),
    ];
  }
}

class DhikrSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final List<DhikrItem> dhikrItems;
  final int totalHassanat;
  final Duration duration;

  DhikrSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.dhikrItems,
    this.totalHassanat = 0,
    this.duration = Duration.zero,
  });

  bool get isCompleted => endTime != null;
  
  DhikrSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    List<DhikrItem>? dhikrItems,
    int? totalHassanat,
    Duration? duration,
  }) {
    return DhikrSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dhikrItems: dhikrItems ?? this.dhikrItems,
      totalHassanat: totalHassanat ?? this.totalHassanat,
      duration: duration ?? this.duration,
    );
  }
}