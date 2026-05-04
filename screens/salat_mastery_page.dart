import 'package:flutter/material.dart';
import 'package:sajda/theme.dart';
// This page focuses on guidance text only (no photos)

class SalatMasteryPage extends StatefulWidget {
  const SalatMasteryPage({super.key});

  @override
  State<SalatMasteryPage> createState() => _SalatMasteryPageState();
}

class _SalatMasteryPageState extends State<SalatMasteryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _HeaderBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IntroCard(),
                    const SizedBox(height: 20),
                    // Niyya (intention)
                    const _SectionHeader(
                      icon: Icons.my_location,
                      color: IslamicColors.emeraldGreen,
                      title: 'Niyya (intention) — formulations',
                      subtitle: 'Rappel: l’intention se trouve dans le cœur; la formulation vocale est optionnelle',
                    ),
                    const SizedBox(height: 12),
                    const _DuaCard(
                      title: 'Formule générale (optionnelle)',
                      arabic: 'نَوَيْتُ الصَّلَاةَ لِلّٰهِ تَعَالَى أَدَاءً مُسْتَقْبِلَ الْقِبْلَةِ',
                      translit: 'Nawaytu ṣ-ṣalāta lillāhi taʿālā adā’an mustaqbila-l-qiblah',
                      meaning: 'J’ai l’intention d’accomplir la prière pour Allah, à l’heure, en direction de la Qibla.',
                      hint: 'La prononcer n’est pas obligatoire',
                      accent: IslamicColors.emeraldGreen,
                    ),
                    const SizedBox(height: 10),
                    const _DuaCard(
                      title: 'Exemple — Fajr (farḍ)',
                      arabic: 'نَوَيْتُ أَنْ أُصَلِّي لِلّٰهِ تَعَالَى صَلَاةَ الْفَجْرِ رَكْعَتَيْنِ فَرْضًا أَدَاءً مُسْتَقْبِلَ الْقِبْلَةِ',
                      translit: 'Nawaytu an uṣallī lillāhi taʿālā ṣalāta al-fajr rakʿatayn farḍan adā’an mustaqbila-l-qiblah',
                      meaning: 'J’ai l’intention d’accomplir la prière de Fajr: 2 unités obligatoires, en direction de la Qibla.',
                      accent: IslamicColors.mysticBlue,
                    ),
                    const SizedBox(height: 10),
                    const _DuaCard(
                      title: 'Exemple — Dhuhr (farḍ)',
                      arabic: 'نَوَيْتُ أَنْ أُصَلِّي لِلّٰهِ تَعَالَى صَلَاةَ الظُّهْرِ أَرْبَعَ رَكَعَاتٍ فَرْضًا أَدَاءً مُسْتَقْبِلَ الْقِبْلَةِ',
                      translit: 'Nawaytu an uṣallī lillāhi taʿālā ṣalāta ẓ-ẓuhr arbaʿa rakaʿāt farḍan adā’an mustaqbila-l-qiblah',
                      meaning: 'J’ai l’intention d’accomplir la prière de Dhuhr: 4 unités obligatoires, en direction de la Qibla.',
                      accent: IslamicColors.roseGold,
                    ),
                    const SizedBox(height: 24),
                    // Ouverture de la prière
                    const _SectionHeader(
                      icon: Icons.play_circle_outline,
                      color: IslamicColors.emeraldGreen,
                      title: 'Ouverture: Duʿāʾ al-Istiftāḥ',
                      subtitle: 'Supplication d’ouverture après le Takbîr de début',
                    ),
                    const SizedBox(height: 12),
                    const _DuaCard(
                      title: 'Duʿāʾ d’ouverture (version répandue)',
                      arabic: 'سُبْحَانَكَ اللّٰهُمَّ وَبِحَمْدِكَ، وَتَبَارَكَ اسْمُكَ، وَتَعَالَىٰ جَدُّكَ، وَلَا إِلٰهَ غَيْرُكَ',
                      translit: 'Subḥānaka-llāhumma wa bi-ḥamdik, wa tabāraka-smuk, wa taʿālā jadduk, wa lā ilāha ghayruk',
                      meaning: 'Gloire et louange à Toi, ô Allah. Béni soit Ton Nom, exaltée soit Ta Majesté, et nulle divinité autre que Toi.',
                      accent: IslamicColors.emeraldGreen,
                    ),
                    const SizedBox(height: 10),
                    const _DuaCard(
                      title: 'Duʿāʾ d’ouverture (version alternative 1)',
                      arabic: 'اللَّهُمَّ بَاعِدْ بَيْنِي وَبَيْنَ خَطَايَايَ كَمَا بَاعَدْتَ بَيْنَ الْمَشْرِقِ وَالْمَغْرِبِ، اللَّهُمَّ نَقِّنِي مِنْ خَطَايَايَ كَمَا يُنَقَّى الثَّوْبُ الْأَبْيَضُ مِنَ الدَّنَسِ، اللَّهُمَّ اغْسِلْنِي مِنْ خَطَايَايَ بِالثَّلْجِ وَالْمَاءِ وَالْبَرَدِ',
                      translit: 'Allāhumma bāʿid baynī wa bayna khaṭāyāya kamā bāʿadta bayna l-mashriqi wa l-maghrib. Allāhumma naqqinī min khaṭāyāya kamā yunaqqā ath-thawbu l-abyaḍu mina d-danas. Allāhumma aghsilnī min khaṭāyāya bi-th-thalji wa l-mā’i wa l-barad.',
                      meaning: 'Ô Allah, éloigne-moi de mes péchés comme Tu as éloigné l’Orient de l’Occident. Purifie-moi de mes fautes comme on blanchit un vêtement blanc de la saleté. Lave-moi de mes péchés par la neige, l’eau et la grêle.',
                      accent: IslamicColors.mysticBlue,
                    ),
                    const SizedBox(height: 10),
                    const _DuaCard(
                      title: 'Duʿāʾ d’ouverture (version alternative 2)',
                      arabic: 'اللَّهُ أَكْبَرُ كَبِيرًا، وَالْحَمْدُ لِلّٰهِ كَثِيرًا، وَسُبْحَانَ اللّٰهِ بُكْرَةً وَأَصِيلًا',
                      translit: 'Allāhu akbaru kabīrā, wal-ḥamdu lillāhi kathīrā, wa subḥānallāhi bukratan wa aṣīlā',
                      meaning: 'Allah est le Plus Grand dans Son immensité; la louange appartient abondamment à Allah; gloire à Allah au matin et au soir.',
                      accent: IslamicColors.roseGold,
                    ),
                    const SizedBox(height: 28),
                    const _SectionHeader(
                      icon: Icons.favorite_outline,
                      color: IslamicColors.emeraldGreen,
                      title: 'Invocations après la Salat',
                      subtitle: 'Formules authentiques à dire juste après le Taslîm',
                    ),
                    const SizedBox(height: 12),
                    const _DuaCard(
                      title: 'Istighfâr (3×)',
                      arabic: 'أَسْتَغْفِرُ اللّٰهَ',
                      translit: 'Astaghfiru-llāh',
                      meaning: 'Je demande pardon à Allah',
                      hint: 'Répéter trois fois',
                      accent: IslamicColors.emeraldGreen,
                    ),
                    const SizedBox(height: 10),
                    const _DuaCard(
                      title: 'Louange et salut',
                      arabic: 'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
                      translit: 'Allāhumma anta-s-salāmu wa minka-s-salām, tabārakta yā dhal-jalāli wal-ikrām',
                      meaning: 'Ô Allah, Tu es la Paix et de Toi vient la paix. Tu es béni, Ô Détenteur de majesté et de noblesse.',
                      accent: IslamicColors.mysticBlue,
                    ),
                    const SizedBox(height: 10),
                    const _DuaCard(
                      title: 'Demande d’aide',
                      arabic: 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
                      translit: 'Allāhumma aʿinnī ʿalā dhikrika wa shukrika wa ḥusni ʿibādatik',
                      meaning: 'Ô Allah, aide-moi à T’évoquer, à Te remercier et à T’adorer de la meilleure manière.',
                      accent: IslamicColors.roseGold,
                    ),
                    const SizedBox(height: 10),
                    const _DuaCard(
                      title: 'Tahlîl étendu',
                      arabic: 'لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
                      translit: 'Lā ilāha illā-llāhu waḥdahu lā sharīka lah, lahu-l-mulku wa lahu-l-ḥamd, wa huwa ʿalā kulli shay’in qadīr',
                      meaning: 'Nulle divinité digne d’adoration si ce n’est Allah, Unique sans associé. À Lui la royauté et la louange, et Il est capable de toute chose.',
                      accent: IslamicColors.emeraldGreen,
                    ),
                    const SizedBox(height: 12),
                    const _TasbihSet(),
                    const SizedBox(height: 28),
                    const _SectionHeader(
                      icon: Icons.event_available,
                      color: IslamicColors.mysticBlue,
                      title: 'Rappel des unités de prière (Rakʿāt)',
                      subtitle: 'Obligatoires et recommandations utiles',
                    ),
                    const SizedBox(height: 12),
                    const _RakaaSummary(),
                    const SizedBox(height: 28),
                    // Sunnahs détaillées
                    const _SectionHeader(
                      icon: Icons.event_note,
                      color: IslamicColors.emeraldGreen,
                      title: 'Sunnahs recommandées',
                      subtitle: 'Rawātib, Witr et autres prières surérogatoires',
                    ),
                    const SizedBox(height: 12),
                    const _ChecklistCard(
                      color: IslamicColors.emeraldGreen,
                      title: 'Rawātib muʾakkadah (fortement confirmées)',
                      bullets: [
                        'Avant Fajr: 2 (les plus confirmées, à ne pas négliger).',
                        'Dhuhr: 2–4 avant et 2 après (selon les habitudes juridiques).',
                        'Après Maghrib: 2.',
                        'Après ʿIshāʼ: 2.',
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _ChecklistCard(
                      color: IslamicColors.mysticBlue,
                      title: 'Autres sunnahs utiles',
                      bullets: [
                        'Avant ʿAsr: 4 recommandées (non confirmées).',
                        'Duḥā (forenoon): 2–8 entre le soleil haut et Dhuhr.',
                        'Tahiyyat al-masjid: 2 à l’entrée dans la mosquée.',
                        'Après les ablutions (wuḍūʾ): 2.',
                        'Witr: 1, 3 ou plus (nombre impair) après ʿIshāʼ; Qunūt permis dans la dernière rakʿa.',
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _TipCard(
                      color: IslamicColors.roseGold,
                      icon: Icons.tips_and_updates_outlined,
                      title: 'Astuce',
                      body: 'Les sunnahs de 4 rakʿāt se prient de préférence deux par deux (taslīm à la fin de chaque paire). Priorisez les sunnahs de Fajr et la régularité des Rawātib.',
                    ),
                    const SizedBox(height: 28),
                    const _SectionHeader(
                      icon: Icons.auto_awesome,
                      color: IslamicColors.dustyRose,
                      title: 'Prière sur le Prophète ﷺ',
                      subtitle: 'Formules recommandées (différentes versions)',
                    ),
                    const SizedBox(height: 12),
                    const _DuaCard(
                      title: 'Ṣalāt Ibrāhīmiyya (complète)',
                      arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ. اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
                      translit: 'Allāhumma ṣalli ʿalā Muḥammad wa ʿalā āli Muḥammad kamā ṣallayta ʿalā Ibrāhīm wa ʿalā āli Ibrāhīm, innaka Ḥamīdun Majīd. Allāhumma bārik ʿalā Muḥammad wa ʿalā āli Muḥammad kamā bārakta ʿalā Ibrāhīm wa ʿalā āli Ibrāhīm, innaka Ḥamīdun Majīd.',
                      meaning: 'Ô Allah, prie sur Muhammad et sur la famille de Muhammad, comme Tu as prié sur Ibrâhîm et la famille d’Ibrâhîm. Tu es certes Digne de louange, Glorieux. Ô Allah, bénis Muhammad et la famille de Muhammad, comme Tu as béni Ibrâhîm et la famille d’Ibrâhîm. Tu es certes Digne de louange, Glorieux.',
                      accent: IslamicColors.dustyRose,
                    ),
                    const SizedBox(height: 10),
                    const _DuaCard(
                      title: 'Formule concise',
                      arabic: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
                      translit: 'Allāhumma ṣalli wa sallim ʿalā nabiyyinā Muḥammad',
                      meaning: 'Ô Allah, prie et salue notre Prophète Muhammad.',
                      accent: IslamicColors.mysticBlue,
                    ),
                    const SizedBox(height: 10),
                    const _DuaCard(
                      title: 'Formule de louange',
                      arabic: 'صَلَّى اللّٰهُ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
                      translit: 'Ṣallā-llāhu ʿalā Muḥammad wa ʿalā āli Muḥammad',
                      meaning: 'Qu’Allah prie sur Muhammad et sur la famille de Muhammad.',
                      accent: IslamicColors.emeraldGreen,
                    ),
                    const SizedBox(height: 28),
                    // Tashahhud
                    const _SectionHeader(
                      icon: Icons.menu_book_outlined,
                      color: IslamicColors.mysticBlue,
                      title: 'At-Tašahhud (assis)',
                      subtitle: 'Attestation récitée en position Julûs',
                    ),
                    const SizedBox(height: 12),
                    const _DuaCard(
                      title: 'Tashahhud (version courte authentique)',
                      arabic: 'التَّحِيَّاتُ لِلّٰهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللّٰهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَىٰ عِبَادِ اللّٰهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللّٰهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
                      translit: 'At-taḥiyyātu lillāhi waṣ-ṣalawātu waṭ-ṭayyibāt. As-salāmu ʿalayka ayyuhan-nabiyyu wa raḥmatullāhi wa barakātuh. As-salāmu ʿalaynā wa ʿalā ʿibādillāhiṣ-ṣāliḥīn. Ashhadu an lā ilāha illā-llāh, wa ashhadu anna Muḥammadan ʿabduhu wa rasūluh.',
                      meaning: 'Toutes les salutations, prières et bonnes paroles appartiennent à Allah. Que la paix soit sur toi, ô Prophète, ainsi que la miséricorde d’Allah et Ses bénédictions. Que la paix soit sur nous et sur les serviteurs pieux d’Allah. J’atteste qu’il n’y a de divinité digne d’adoration qu’Allah, et j’atteste que Muhammad est Son serviteur et Son messager.',
                      accent: IslamicColors.mysticBlue,
                    ),
                    const SizedBox(height: 28),
                    // Invocations after the last Tashahhud (before Taslîm)
                    const _SectionHeader(
                      icon: Icons.shield_outlined,
                      color: IslamicColors.emeraldGreen,
                      title: 'Invocations après le dernier Tašahhud',
                      subtitle: 'À dire avant le Taslîm — Source : La Citadelle du Musulman',
                    ),
                    const SizedBox(height: 12),
                    const _DuaCard(
                      title: 'Protection contre 4 épreuves',
                      arabic:
                          'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عَذَابِ جَهَنَّمَ، وَمِنْ عَذَابِ الْقَبْرِ، وَمِنْ فِتْنَةِ الْمَحْيَا وَالْمَمَاتِ، وَمِنْ شَرِّ فِتْنَةِ الْمَسِيحِ الدَّجَّالِ',
                      translit:
                          'Allāhumma innī aʿūdhu bika min ʿadhābi Jahannam, wa min ʿadhābi l‑qabr, wa min fitnati l‑maḥyā wal‑mamāt, wa min sharri fitnati l‑Masīḥi d‑Dajjāl',
                      meaning:
                          'Ô Allah, je cherche refuge auprès de Toi contre le châtiment de l’Enfer, contre le châtiment de la tombe, contre l’épreuve de la vie et de la mort, et contre le mal de l’épreuve du Faux Messie (Dajjâl).',
                      accent: IslamicColors.emeraldGreen,
                    ),
                    const SizedBox(height: 10),
                    const _DuaCard(
                      title: 'Demande de pardon (enseignement au calife Abû Bakr)',
                      arabic:
                          'اللَّهُمَّ إِنِّي ظَلَمْتُ نَفْسِي ظُلْمًا كَثِيرًا، وَلَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ، فَاغْفِرْ لِي مَغْفِرَةً مِنْ عِنْدِكَ، وَارْحَمْنِي، إِنَّكَ أَنْتَ الْغَفُورُ الرَّحِيمُ',
                      translit:
                          'Allāhumma innī ẓalamtu nafsī ẓulman kathīrā, wa lā yaghfiru dh‑dhunūba illā anta, faghfir lī maghfiratan min ʿindik, warḥamnī, innaka anta l‑Ghafūru r‑Raḥīm',
                      meaning:
                          'Ô Allah, j’ai certes fait beaucoup de tort à moi‑même, et nul ne pardonne les péchés si ce n’est Toi. Accorde‑moi donc, de Ta part, un pardon et fais‑moi miséricorde. Tu es, en vérité, le Pardonneur, le Très Miséricordieux.',
                      accent: IslamicColors.mysticBlue,
                    ),
                    const SizedBox(height: 10),
                    const _DuaCard(
                      title: 'Refuge contre le péché et la dette',
                      arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْمَأْثَمِ وَالْمَغْرَمِ',
                      translit: 'Allāhumma innī aʿūdhu bika mina l‑maʾthami wal‑maghram',
                      meaning: 'Ô Allah, je cherche refuge auprès de Toi contre le péché et la dette.',
                      accent: IslamicColors.roseGold,
                    ),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: 0.75,
                      child: Text(
                        'Note: Ces invocations sont issues de “La Citadelle du Musulman”.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Taslîm (salutations finales)
                    const _SectionHeader(
                      icon: Icons.flag_circle_outlined,
                      color: IslamicColors.roseGold,
                      title: 'Taslîm (salutations finales)',
                      subtitle: 'Clôture de la prière',
                    ),
                    const _SectionHeader(
                      icon: Icons.flag_circle_outlined,
                      color: IslamicColors.roseGold,
                      title: 'Taslîm (salutations finales)',
                      subtitle: 'Clôture de la prière',
                    ),
                    const SizedBox(height: 12),
                    const _DuaCard(
                      title: 'Formule de conclusion',
                      arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللّٰهِ',
                      translit: 'As-salāmu ʿalaykum wa raḥmatullāh',
                      meaning: 'Que la paix et la miséricorde d’Allah soient sur vous (à droite puis à gauche).',
                      accent: IslamicColors.roseGold,
                    ),
                    const SizedBox(height: 28),
                    // Piliers et conditions (récapitulatif synthétique)
                    const _SectionHeader(
                      icon: Icons.fact_check_outlined,
                      color: IslamicColors.emeraldGreen,
                      title: 'Récapitulatif pratique',
                      subtitle: 'Piliers (arkān), conditions (shurūṭ) et erreurs fréquentes',
                    ),
                    const SizedBox(height: 12),
                    const _ChecklistCard(
                      color: IslamicColors.emeraldGreen,
                      title: 'Piliers essentiels',
                      bullets: [
                        'Intention sincère (niyya) pour chaque prière',
                        'Takbîr d’ouverture (Allāhu akbar)',
                        'Lecture de la Fātiḥa en station debout',
                        'Rukûʿ, redressement, deux prosternations et assise',
                        'Sérénité dans chaque position',
                        'Tashahhud final et Taslîm',
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _ChecklistCard(
                      color: IslamicColors.mysticBlue,
                      title: 'Conditions de validité',
                      bullets: [
                        'Purification (wuḍūʾ) et absence de souillures',
                        'Couverture de la ʿawra (parties à couvrir)',
                        'Entrée du temps de la prière',
                        'Orientation vers la Qibla',
                        'Lieu licite et propre',
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _ChecklistCard(
                      color: IslamicColors.roseGold,
                      title: 'Erreurs fréquentes à éviter',
                      bullets: [
                        'Se précipiter sans marquer la sérénité (ṭumaʾnīna)',
                        'Regarder ailleurs que l’endroit de la prosternation',
                        'Mauvaise position des pieds en Julûs (orteils non dirigés vers la Qibla)',
                        'Couper la prière pour une raison non valable',
                      ],
                    ),
                    const SizedBox(height: 28),
                    const _TipCard(
                      color: IslamicColors.emeraldGreen,
                      icon: Icons.check_circle,
                      title: 'Conseil pratique',
                      body: 'Prenez le temps de réciter ces formules calmement après chaque prière. La constance vaut mieux que la quantité.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: IslamicColors.emeraldGreen), onPressed: () => Navigator.of(context).pop()),
          Expanded(
            child: Text('Perfectionner sa Salat', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: IslamicColors.emeraldGreen, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IslamicColors.emeraldGreen.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: IslamicColors.emeraldGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.self_improvement, color: IslamicColors.emeraldGreen)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Un parcours visuel pour corriger la posture, améliorer l’alignement et renforcer le recueillement (khushûʼ).',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700], height: 1.4),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          )
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;
  const _TipCard({required this.color, required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)]),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[800])),
        ])),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _SectionHeader({required this.icon, required this.color, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
          ]),
        )
      ],
    );
  }
}

class _DuaCard extends StatelessWidget {
  final String title;
  final String arabic;
  final String translit;
  final String meaning;
  final String? hint;
  final Color accent;
  const _DuaCard({required this.title, required this.arabic, required this.translit, required this.meaning, required this.accent, this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent.withValues(alpha: 0.10), accent.withValues(alpha: 0.04)]),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.brightness_5, color: accent),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: accent, fontWeight: FontWeight.bold))),
          if (hint != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: accent.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(20)),
              child: Text(hint!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: accent, fontWeight: FontWeight.w600)),
            )
        ]),
        const SizedBox(height: 12),
        Text(
          arabic,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: accent, fontWeight: FontWeight.w700, height: 1.8),
          textAlign: TextAlign.start,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 10),
        Text(translit, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: IslamicColors.mysticBlue, fontStyle: FontStyle.italic, height: 1.5)),
        const SizedBox(height: 8),
        Text(meaning, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[800], height: 1.5)),
      ]),
    );
  }
}

class _TasbihSet extends StatelessWidget {
  const _TasbihSet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IslamicColors.emeraldGreen.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.loop, color: IslamicColors.emeraldGreen),
          const SizedBox(width: 8),
          Text('Tasbîḥ recommandé', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: IslamicColors.emeraldGreen, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        _TasbihRow(label: 'Subḥānallāh', count: 33, color: IslamicColors.mysticBlue),
        const SizedBox(height: 8),
        _TasbihRow(label: 'Alḥamdulillāh', count: 33, color: IslamicColors.roseGold),
        const SizedBox(height: 8),
        _TasbihRow(label: 'Allāhu akbar', count: 34, color: IslamicColors.emeraldGreen),
        const SizedBox(height: 8),
        Opacity(
          opacity: 0.8,
          child: Text(
            'Vous pouvez conclure par « Lā ilāha illā-llāh waḥdahu lā sharīka lah… »',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[700]),
          ),
        ),
      ]),
    );
  }
}

class _TasbihRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _TasbihRow({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[800], fontWeight: FontWeight.w600))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Text('×$count', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
      ),
    ]);
  }
}

class _RakaaSummary extends StatelessWidget {
  const _RakaaSummary();

  Widget _line(BuildContext context, {required Color color, required IconData icon, required String label, required String rakat}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[900], fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
            child: Text(rakat, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IslamicColors.mysticBlue.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.schedule, color: IslamicColors.mysticBlue),
          const SizedBox(width: 8),
          Text('Farḍ (obligatoires)', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: IslamicColors.mysticBlue, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        _line(
          context,
          color: IslamicColors.mysticBlue,
          icon: Icons.wb_sunny_outlined,
          label: 'Fajr',
          rakat: '2 rakʿāt',
        ),
        const SizedBox(height: 8),
        _line(
          context,
          color: IslamicColors.emeraldGreen,
          icon: Icons.wb_sunny_outlined,
          label: 'Dhuhr',
          rakat: '4 rakʿāt',
        ),
        const SizedBox(height: 8),
        _line(
          context,
          color: IslamicColors.emeraldGreen,
          icon: Icons.wb_sunny_outlined,
          label: "ʿAsr",
          rakat: '4 rakʿāt',
        ),
        const SizedBox(height: 8),
        _line(
          context,
          color: IslamicColors.roseGold,
          icon: Icons.nightlight_round,
          label: 'Maghrib',
          rakat: '3 rakʿāt',
        ),
        const SizedBox(height: 8),
        _line(
          context,
          color: IslamicColors.dustyRose,
          icon: Icons.nightlight_outlined,
          label: 'ʿIshāʼ',
          rakat: '4 rakʿāt',
        ),
        const SizedBox(height: 16),
        Opacity(
          opacity: 0.9,
          child: Text(
            'Sunnah recommandées (indicatif): Fajr 2 avant; Dhuhr 4 avant + 2 après; Maghrib 2 après; ʿIshāʼ 2 après. Witr (1–3) après ʿIshāʼ.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[800], height: 1.4),
          ),
        ),
      ]),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final Color color;
  final String title;
  final List<String> bullets;
  const _ChecklistCard({required this.color, required this.title, required this.bullets});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.checklist_rtl, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 10),
        ...bullets.map((b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(b, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[800], height: 1.4))),
              ]),
            )),
      ]),
    );
  }
}
