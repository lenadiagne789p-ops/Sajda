import 'package:flutter/material.dart';
import 'package:sajda/models/morning_evening_dhikr.dart';
import 'package:sajda/models/rabbana_duas.dart';
import 'package:sajda/services/invocations_repository.dart';
import 'package:sajda/theme.dart';

class InvocationCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<DhikrItem> items;

  const InvocationCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class InvocationsCatalog {
  // Map a category id/title hint to a consistent icon and color
  static (IconData, Color) _iconColorFor(String idOrTitle) {
    final t = idOrTitle.toLowerCase();
    if (t.contains('salawat') ||
        t.contains('salawât') ||
        t.contains('prophète') ||
        t.contains('prophete') ||
        t.contains('muhammad') ||
        t.contains('prière sur le prophète') ||
        t.contains('prières sur le prophète')) {
      return (Icons.auto_awesome, IslamicColors.amethystPurple);
    }
    if (t.contains('rabbana')) return (Icons.menu_book, IslamicColors.emeraldGreen);
    if (t.contains('maison') || t.contains('home') || t.contains('house')) {
      return (Icons.home, IslamicColors.roseGold);
    }
    if (t.contains('mal') || t.contains('ruqy') || t.contains('protection')) {
      return (Icons.shield, IslamicColors.mysticBlue);
    }
    if (t.contains('prière') || t.contains('salat') || t.contains('salât')) {
      return (Icons.self_improvement, IslamicColors.emeraldGreen);
    }
    if (t.contains('mosquée') || t.contains('mosquee') || t.contains('mosque')) {
      return (Icons.mosque, IslamicColors.mysticBlue);
    }
    if (t.contains('voyage') || t.contains('travel') || t.contains('trajet')) {
      return (Icons.flight_takeoff, IslamicColors.softViolet);
    }
    if (t.contains('sommeil') || t.contains('dormir') || t.contains('sleep')) {
      return (Icons.bedtime, IslamicColors.quartz);
    }
    if (t.contains('repas') || t.contains('manger') || t.contains('food')) {
      return (Icons.restaurant, IslamicColors.topaz);
    }
    if (t.contains('marché') || t.contains('marche') || t.contains('market')) {
      return (Icons.store_mall_directory, IslamicColors.amethystPurple);
    }
    if (t.contains('colère') || t.contains('colere') || t.contains('anger')) {
      return (Icons.whatshot, IslamicColors.rubyRed);
    }
    if (t.contains('peur') || t.contains('tristesse') || t.contains('anxi')) {
      return (Icons.sentiment_dissatisfied, IslamicColors.quartz);
    }
    if (t.contains('istikh') || t.contains('choix')) {
      return (Icons.help_center, IslamicColors.opalIridescent);
    }
    if (t.contains('matin') || t.contains('soir') || t.contains('morning') || t.contains('evening')) {
      return (Icons.wb_sunny, IslamicColors.topaz);
    }
    if (t.contains('mariage') || t.contains('mari') || t.contains('nikah')) {
      return (Icons.favorite, IslamicColors.roseGold);
    }
    if (t.contains('étud') || t.contains('etud') || t.contains('study') || t.contains('apprent') || t.contains('savoir')) {
      return (Icons.school, IslamicColors.topaz);
    }
    if (t.contains('diffic') || t.contains('épreuve') || t.contains('epreuve') || t.contains('detresse')) {
      return (Icons.report_problem, IslamicColors.rubyRed);
    }
    if (t.contains('business') || t.contains('commerce') || t.contains('travail') || t.contains('rizq') || t.contains('subsist')) {
      return (Icons.trending_up, IslamicColors.opalIridescent);
    }
    if (t.contains('probl') || t.contains('souci') || t.contains('ennui')) {
      return (Icons.sos, IslamicColors.mysticBlue);
    }
    if (t.contains('pardon') || t.contains('istighfar') || t.contains('maghfir') || t.contains('forgive')) {
      return (Icons.clean_hands, IslamicColors.opalIridescent);
    }
    // default
    return (Icons.menu_book, IslamicColors.emeraldGreen);
  }

  static List<DhikrItem> _protectionDuas() {
    return [
      DhikrItem(
        id: 'prot_kalimat_tammat',
        arabicText: 'أَعُوذُ بِكَلِمَاتِ اللّٰهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
        transliteration: "A'ūdhu bikalimāti Allāhi at-tāmmāti min sharri mā khalaq",
        meaning: "Je cherche refuge auprès des paroles parfaites d'Allah contre le mal de ce qu'Il a créé",
        repetitions: 3,
        benefit: 'Bouclier global contre les maux visibles et invisibles (matin/soir, lieu nouveau).',
        reward: 'Protection divine étendue',
        audioUrl: 'https://example.com/audio/kalimat_tammat.mp3',
        icon: Icons.shield,
        color: IslamicColors.mysticBlue,
        category: 'Protection',
        source: 'Sahih Muslim',
        hadithReference: 'Réciter 3x matin et soir',
      ),
      DhikrItem(
        id: 'prot_bismillah_no_harm',
        arabicText:
            'بِسْمِ اللّٰهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
        transliteration:
            'Bismi-llāhi alladhī lā yaḍurru maʿa-smihi shayʾun fī-l-arḍi wa-lā fī-s-samāʾ, wa huwa as-samīʿu al-ʿalīm',
        meaning:
            "Au nom d'Allah, avec le Nom duquel rien ne peut nuire sur terre ni au ciel; Il est l'Audient, l'Omniscient",
        repetitions: 3,
        benefit: 'Assurance quotidienne contre les nuisances; recommandé matin et soir.',
        reward: 'Aucun mal ne l’atteindra par la volonté d’Allah',
        audioUrl: 'https://example.com/audio/bismillah_protection.mp3',
        icon: Icons.health_and_safety,
        color: IslamicColors.emeraldGreen,
        category: 'Protection',
        source: 'Sunan Abi Dawud',
      ),
      DhikrItem(
        id: 'prot_hasbiyallahu_7',
        arabicText:
            'حَسْبِيَ اللّٰهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
        transliteration:
            'Ḥasbiyallāhu lā ilāha illā huwa, ʿalayhi tawakkaltu wa huwa rabbu al-ʿarshi al-ʿaẓīm',
        meaning:
            'Allah me suffit. Nulle divinité autre que Lui. Je place ma confiance en Lui, Seigneur du Trône immense',
        repetitions: 7,
        benefit: 'Apaise les peurs et renforce le tawakkul; recommandé matin et soir.',
        reward: 'Quiétude du cœur et protection',
        audioUrl: 'https://example.com/audio/hasbiyallahu.mp3',
        icon: Icons.security,
        color: IslamicColors.mysticBlue,
        category: 'Protection',
        source: 'Conseil des savants',
      ),
      DhikrItem(
        id: 'prot_three_quls',
        arabicText:
            'قُلْ هُوَ اللّٰهُ أَحَدٌ • قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ • قُلْ أَعُوذُ بِرَبِّ النَّاسِ (٣ مرات)',
        transliteration:
            "Lire Al-Ikhlās, Al-Falaq et An-Nās (3x chacune) le matin et le soir",
        meaning:
            'Les trois sourates protectrices. Elles suffisent contre tout mal par la permission d’Allah.',
        repetitions: 1,
        benefit: 'Bouclier complet contre la sorcellerie, le mauvais œil et les nuisances.',
        reward: 'Protection globale jour et nuit',
        audioUrl: 'https://example.com/audio/three_quls.mp3',
        icon: Icons.waves,
        color: IslamicColors.roseGold,
        category: 'Protection',
        source: 'Sahih Al-Boukhari',
      ),
      DhikrItem(
        id: 'prot_ayat_kursi',
        arabicText: 'آيَةُ الْكُرْسِي (اللّٰهُ لَا إِلَٰهَ إِلَّا هُوَ...)',
        transliteration: 'Ayat al-Kursī (Coran 2:255)',
        meaning:
            'Le verset du Trône: protection jusqu’au matin/soir et élévation de la foi.',
        repetitions: 1,
        benefit: 'Rempart puissant contre le mal; recommandé après chaque prière et au coucher.',
        reward: 'Protection par un ange mandaté',
        audioUrl: 'https://example.com/audio/ayat_kursi.mp3',
        icon: Icons.castle,
        color: IslamicColors.emeraldGreen,
        category: 'Protection',
        source: 'Sahih Al-Boukhari',
      ),
      DhikrItem(
        id: 'prot_sickness_dua',
        arabicText:
            'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْبَرَصِ، وَالْجُنُونِ، وَالْجُذَامِ، وَمِنْ سَيِّئِ الْأَسْقَامِ',
        transliteration:
            'Allāhumma innī aʿūdhu bika mina al-barasi, wal-junūni, wal-juḏhāmi, wa min sayyiʾi al-asqām',
        meaning:
            'Ô Allah, je cherche refuge auprès de Toi contre la lèpre, la folie, la lèpre grave et les mauvaises maladies.',
        repetitions: 1,
        benefit: 'Protection sanitaire globale; à dire régulièrement.',
        reward: 'Préservation et bien-être',
        audioUrl: 'https://example.com/audio/sickness_protection.mp3',
        icon: Icons.local_hospital,
        color: IslamicColors.dustyRose,
        category: 'Protection',
        source: 'Sunan An-Nasaï',
      ),
    ];
  }

  static List<DhikrItem> _homeDuas() {
    return [
      DhikrItem(
        id: 'home_enter',
        arabicText:
            'بِسْمِ اللّٰهِ وَلَجْنَا، وَبِسْمِ اللّٰهِ خَرَجْنَا، وَعَلَى اللّٰهِ رَبِّنَا تَوَكَّلْنَا',
        transliteration:
            'Bismi-llāh walajnā, wa bismi-llāh kharajnā, wa ʿalā Allāhi rabbina tawakkalnā',
        meaning:
            'Au nom d’Allah, nous entrons; au nom d’Allah, nous sortons; et c’est en Allah, notre Seigneur, que nous plaçons notre confiance.',
        repetitions: 1,
        benefit: 'Apporte la bénédiction et éloigne le diable du foyer.',
        reward: 'Sérénité et protection du foyer',
        audioUrl: 'https://example.com/audio/enter_home.mp3',
        icon: Icons.home,
        color: IslamicColors.emeraldGreen,
        category: 'Maison',
        source: 'Sunan Abi Dawud',
      ),
      DhikrItem(
        id: 'home_dua_entry',
        arabicText:
            'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ الْمَوْلِجِ وَخَيْرَ الْمَخْرَجِ',
        transliteration:
            'Allāhumma innī asʾaluk khaýra al-mawliji wa khaýra al-makhraj',
        meaning:
            'Ô Allah, je Te demande le meilleur de l’entrée et le meilleur de la sortie.',
        repetitions: 1,
        benefit: 'Demande de bénédiction pour les transitions (entrées/sorties).',
        reward: 'Bénédiction dans les déplacements',
        audioUrl: 'https://example.com/audio/house_entry.mp3',
        icon: Icons.door_front_door,
        color: IslamicColors.mysticBlue,
        category: 'Maison',
        source: 'Dua authentique',
      ),
      DhikrItem(
        id: 'home_leave',
        arabicText:
            'بِسْمِ اللّٰهِ، تَوَكَّلْتُ عَلَى اللّٰهِ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ',
        transliteration:
            'Bismi-llāh, tawakkaltu ʿalā Allāh, lā ḥawla wa lā quwwata illā bi-llāh',
        meaning:
            'Au nom d’Allah, je place ma confiance en Allah, il n’y a de force ni de puissance qu’en Allah.',
        repetitions: 1,
        benefit: 'Assuré par des anges, guidé et protégé jusqu’au retour.',
        reward: 'Protection jusqu’au retour à la maison',
        audioUrl: 'https://example.com/audio/leave_home.mp3',
        icon: Icons.logout,
        color: IslamicColors.roseGold,
        category: 'Maison',
        source: 'Sunan At-Tirmidhi',
      ),
    ];
  }

  // Synchronous base (built-in) categories
  static List<InvocationCategory> baseCategories() {
    return [
      InvocationCategory(
        id: 'rabbana_50',
        title: '50 Rabbana',
        subtitle: 'Invocations coraniques commençant par رَبَّنَا',
        icon: Icons.menu_book,
        color: IslamicColors.emeraldGreen,
        items: RabbanaDuas.all(),
      ),
      InvocationCategory(
        id: 'maison',
        title: 'Maison',
        subtitle: 'En entrant, en sortant et bénédiction du foyer',
        icon: Icons.home,
        color: IslamicColors.roseGold,
        items: _homeDuas(),
      ),
      InvocationCategory(
        id: 'protection_mal',
        title: 'Contre le mal',
        subtitle: 'Boucliers prophétiques et versets protecteurs',
        icon: Icons.shield,
        color: IslamicColors.mysticBlue,
        items: _protectionDuas(),
      ),
    ];
  }

  // Dynamic categories loaded from assets (Hisn al-Muslim / Citadelle du musulman)
  static Future<List<InvocationCategory>> loadCategories() async {
    final base = baseCategories();
    try {
      final rawCats = await InvocationsRepository.loadFromAssets();
      for (final rc in rawCats) {
        final (icon, color) = _iconColorFor(rc.title);
        final items = rc.items.map((e) => DhikrItem(
              id: e.id,
              arabicText: e.arabic,
              transliteration: e.transliteration ?? '',
              meaning: e.translation ?? '',
              repetitions: e.repetitions ?? 1,
              benefit: e.benefit ?? '',
              reward: e.reward ?? '',
              audioUrl: e.audioUrl ?? '',
              icon: icon,
              color: color,
              category: rc.title,
              source: e.source,
              hadithReference: e.reference,
            ))
            .toList();
        base.add(InvocationCategory(
          id: rc.id,
          title: rc.title,
          subtitle: rc.subtitle ?? 'La Citadelle du Musulman',
          icon: icon,
          color: color,
          items: items,
        ));
      }
    } catch (e) {
      // Swallow errors and keep base categories if asset missing or malformed
    }
    return base;
  }
}
