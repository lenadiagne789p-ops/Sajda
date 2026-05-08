class SalatStep {
  final String id;
  final String title;
  final String arabicText;
  final String transliteration;
  final String meaning;
  final String description;
  // Plusieurs illustrations par position
  final List<String> imageAssets;
  final String audioUrl;
  final SalatStepType type;
  final int duration; // en secondes
  // Contenu pédagogique structuré
  final List<String> explanations; // points clés / pas-à-pas
  final List<String> mistakes; // erreurs fréquentes à éviter
  final List<String> tips; // conseils & sunan

  SalatStep({
    required this.id,
    required this.title,
    required this.arabicText,
    required this.transliteration,
    required this.meaning,
    required this.description,
    required this.imageAssets,
    required this.audioUrl,
    required this.type,
    this.duration = 0,
    this.explanations = const [],
    this.mistakes = const [],
    this.tips = const [],
  });
}

enum SalatStepType {
  standing, // debout
  bowing, // rukuu
  prostration, // sujud
  sitting, // juloos
  transition, // transition
}

class SalatCourse {
  final String id;
  final String title;
  final String description;
  final List<SalatStep> steps;
  final int estimatedDuration; // en minutes
  final String difficulty; // débutant, intermédiaire, avancé

  SalatCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    required this.estimatedDuration,
    required this.difficulty,
  });

  static List<SalatCourse> getDefaultCourses() {
    return [
      SalatCourse(
        id: 'basic_salat',
        title: 'Apprendre la Salat - Bases',
        description: 'Apprenez les étapes fondamentales de la prière islamique avec les invocations essentielles',
        estimatedDuration: 15,
        difficulty: 'Débutant',
        steps: [
          SalatStep(
            id: 'takbir_tahrimah',
            title: 'Takbîr de consécration',
            arabicText: 'اللَّهُ أَكْبَرُ',
            transliteration: 'Allāhu akbar',
            meaning: 'Allah est le plus grand',
            description: 'Levez les mains à hauteur des oreilles, paumes tournées vers la Qibla, et prononcez "Allāhu akbar" pour entrer solennellement en prière. Ce geste marque l\'entrée dans l\'état sacré de communication avec Allah.',
            // 2–3 photos locales (dernier lot importé)
            imageAssets: [
              'assets/images/dire-Allahu-akbar.jpg',
              'assets/images/dire-Allahu-akbar-2.jpg',
            ],
            audioUrl: 'https://example.com/audio/takbir.mp3',
            type: SalatStepType.standing,
            duration: 5,
            explanations: [
              'Placez-vous face à la Qibla, en état d\'ablution valide.',
              'Levez les mains à hauteur des épaules ou des oreilles, paumes vers la Qibla.',
              'Dites distinctement: « Allāhu akbar » en engageant l\'intention (niyya) dans le cœur.',
              'Posez ensuite les mains sur la poitrine: main droite sur la gauche.',
            ],
            mistakes: [
              'Prononcer l\'intention à voix haute: l\'intention se fait dans le cœur.',
              'Lever les mains trop haut ou trop bas, ou tourner les paumes vers l\'extérieur.',
              'Regarder ailleurs que l\'emplacement de prosternation.',
            ],
            tips: [
              'Stabilisez votre posture avant de prononcer le takbîr.',
              'Synchronisez le geste des mains avec la parole pour plus de concentration (khushūʿ).',
              'Évitez toute parole mondaine après le takbîr: vous êtes entré en prière.',
            ],
          ),
          SalatStep(
            id: 'qiyam',
            title: 'Position debout (Qiyâm)',
            arabicText: '''بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ
الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ
الرَّحْمَنِ الرَّحِيمِ
مَالِكِ يَوْمِ الدِّينِ
إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ
اهْدِنَا الصِّرَاطَ الْمُستَقِيمَ
صِرَاطَ الَّذِينَ أَنعَمتَ عَلَيهِمْ
غَيرِ المَغضُوبِ عَلَيهِمْ وَلاَ الضَّالِّينَ''',
            transliteration: '''Bismillāhi-r-Rahmāni-r-Rahīm
Al-hamdu lillāhi Rabbi-l-ālamīn
Ar-Rahmāni-r-Rahīm
Māliki yawmi-d-dīn
Iyyāka na\'budu wa iyyāka nasta\'īn
Ihdinā-s-sirāta-l-mustaqīm
Sirāta-lladhīna an\'amta \'alayhim
Ghayri-l-maghdūbi \'alayhim wa lā-d-dāllīn''',
            meaning: 'Au nom d\'Allah, le Tout Miséricordieux, le Très Miséricordieux. Louange à Allah, Seigneur de l\'univers...',
            description: 'Récitez Al-Fatiha en position debout, les mains jointes sur la poitrine',
            // 2–3 photos locales (Qiyâm)
            imageAssets: [
              'assets/images/se-tenir-debout-pendant-la-priere-et-reciter-la-fatiha.jpg',
              'assets/images/se-tenir-debout-pendant-la-priere.jpg',
            ],
            audioUrl: 'https://example.com/audio/fatiha.mp3',
            type: SalatStepType.standing,
            duration: 60,
            explanations: [
              'Placez la main droite sur la gauche au-dessus de la poitrine.',
              'Récitez la Fātiha posément, puis une sourate ou quelques versets.',
              'Respectez la quiétude (ṭumaʾnīna): pas de précipitation entre les versets.',
              'Regard fixé vers l\'emplacement de la prosternation.',
            ],
            mistakes: [
              'Lire trop vite sans articuler clairement.',
              'Regarder à droite/gauche ou le plafond.',
              'Croiser les bras trop bas au niveau du ventre (selon avis suivis).',
            ],
            tips: [
              'Variez les courtes sourates pour maintenir la présence du cœur.',
              'Apprenez les règles de base de tajwīd pour améliorer la récitation.',
            ],
          ),
          SalatStep(
            id: 'ruku',
            title: 'Inclinaison (Rukû\')',
            arabicText: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
            transliteration: 'Subhāna rabbiya-l-\'azīm',
            meaning: 'Gloire à mon Seigneur le Magnifique',
            description: 'Inclinez-vous en plaçant les mains sur les genoux et répétez cette invocation 3 fois minimum',
            // 2–3 photos locales (Rukûʿ)
            imageAssets: [
              'assets/images/ruku-priere-salat.jpg',
              'assets/images/ruku-priere-salat-2.jpg',
            ],
            audioUrl: 'https://example.com/audio/ruku.mp3',
            type: SalatStepType.bowing,
            duration: 15,
            explanations: [
              'Inclinez le dos droit, tête alignée, mains posées fermement sur les genoux.',
              'Doigts écartés, coudes légèrement vers l\'extérieur.',
              'Dites au minimum trois fois: « Subḥāna rabbiya-l-ʿaẓīm ».',
              'Gardez la quiétude avant de remonter.',
            ],
            mistakes: [
              'Dos arrondi, tête relevée ou trop abaissée.',
              'Toucher à peine les genoux sans stabilité.',
              'Réciter moins de trois glorifications sans excuse.',
            ],
            tips: [
              'Imaginez que le dos pourrait porter un verre d\'eau: restez bien plat.',
              'Respirez calmement pour favoriser la concentration.',
            ],
          ),
          SalatStep(
            id: 'qawmah',
            title: 'Redressement après Rukû\'',
            arabicText: 'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ، رَبَّنَا وَلَكَ الْحَمْدُ',
            transliteration: 'Sami\'a-llāhu liman hamidah, Rabbanā wa laka-l-hamd',
            meaning: 'Allah entend celui qui Le loue, notre Seigneur, à Toi la louange',
            description: 'Redressez-vous et récitez cette invocation en position debout',
            // Pas de photo dédiée « qawmah » : posture debout
            imageAssets: [
              'assets/images/se-tenir-debout-pendant-la-priere.jpg',
            ],
            audioUrl: 'https://example.com/audio/qawmah.mp3',
            type: SalatStepType.standing,
            duration: 10,
            explanations: [
              'Relevez-vous complètement avant toute récitation suivante.',
              'Dites: « Samiʿa-llāhu liman ḥamidah » (imam/individuel), puis « Rabbanā wa laka-l-ḥamd » (tous).',
              'Stabilisez-vous brièvement (ṭumaʾnīna).',
            ],
            mistakes: [
              'Remonter à moitié puis redescendre aussitôt.',
              'Réciter en mouvement sans marquer l\'arrêt.',
            ],
            tips: [
              'Profitez de ce redressement pour renouveler la gratitude intérieurement.',
            ],
          ),
          SalatStep(
            id: 'sujud1',
            title: 'Première prosternation (Sujûd)',
            arabicText: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
            transliteration: 'Subhāna rabbiya-l-a\'lā',
            meaning: 'Gloire à mon Seigneur le Très-Haut',
            description: 'Prosternez-vous en touchant le sol avec le front, le nez, les paumes, les genoux et les orteils. Répétez l\'invocation 3 fois minimum',
            // 2–3 photos locales (Sujûd)
            imageAssets: [
              'assets/images/prosternation-priere-salat.jpg',
              'assets/images/prosternation-priere-salat-2.jpg',
              'assets/images/prosternation-priere-salat-3.jpg',
            ],
            audioUrl: 'https://example.com/audio/sujud.mp3',
            type: SalatStepType.prostration,
            duration: 15,
            explanations: [
              'Descendez en posant au sol: mains, genoux, pieds, puis front et nez.',
              'Doigts pointés vers la Qibla, coudes décollés des côtes.',
              'Dites au minimum trois fois: « Subḥāna rabbiya-l-aʿlā ».',
              'C\'est le moment le plus propice pour invoquer personnellement.',
            ],
            mistakes: [
              'Ne pas coller le nez au sol avec le front.',
              'Coudes posés au sol (posture du chien), à éviter.',
              'Hanches trop relevées sans vraie prosternation.',
            ],
            tips: [
              'Gardez les pieds dressés, orteils fléchis vers la Qibla.',
              'Allongez légèrement la glorification pour savourer le moment.',
            ],
          ),
          SalatStep(
            id: 'juloos_bayn_sajdatayn',
            title: 'Position assise entre les prosternations',
            arabicText: 'رَبِّ اغْفِرْ لِي، رَبِّ اغْفِرْ لِي',
            transliteration: 'Rabbi-ghfir lī, Rabbi-ghfir lī',
            meaning: 'Mon Seigneur, pardonne-moi, mon Seigneur, pardonne-moi',
            description: 'Asseyez-vous brièvement entre les deux prosternations et invoquez le pardon d\'Allah',
            // 2–3 photos locales (position assise)
            imageAssets: [
              'assets/images/tachahoud-priere.jpg',
              'assets/images/tachahoud-priere-2.jpg',
            ],
            audioUrl: 'https://example.com/audio/juloos.mp3',
            type: SalatStepType.sitting,
            duration: 10,
            explanations: [
              'Asseyez-vous posé, dos ajusté, mains sur les cuisses.',
              'Récitez: « Rabbi-ghfir lī » au moins une fois (deux fois courant).',
              'Marquez la ṭumaʾnīna avant la prosternation suivante.',
            ],
            mistakes: [
              'S\'asseoir à peine et replonger immédiatement en prosternation.',
              'Agiter les doigts ou regarder autour.',
            ],
            tips: [
              'Profitez de ce bref repos pour reprendre une respiration calme.',
            ],
          ),
          SalatStep(
            id: 'sujud2',
            title: 'Seconde prosternation (Sujûd)',
            arabicText: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
            transliteration: 'Subhāna rabbiya-l-a\'lā',
            meaning: 'Gloire à mon Seigneur le Très-Haut',
            description: 'Effectuez une seconde prosternation identique à la première',
            // 2–3 photos locales (Sujûd)
            imageAssets: [
              'assets/images/prosternation-priere-salat-2.jpg',
              'assets/images/prosternation-priere-salat.jpg',
              'assets/images/prosternation-priere-salat-3.jpg',
            ],
            audioUrl: 'https://example.com/audio/sujud.mp3',
            type: SalatStepType.prostration,
            duration: 15,
            explanations: [
              'Répétez la même posture et les mêmes invocations que pour la première prosternation.',
              'Assurez une quiétude minimale avant de vous relever.',
            ],
            mistakes: [
              'Précipiter la seconde prosternation sans stabilité.',
            ],
            tips: [
              'Renouvelez vos invocations personnelles à ce moment privilégié.',
            ],
          ),
          SalatStep(
            id: 'tashahhud',
            title: 'Position assise finale (Tashahhud)',
            arabicText: '''التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ''',
            transliteration: '''At-tahiyyātu lillāhi wa-s-salawātu wa-t-tayyibāt. As-salāmu \'alayka ayyuha-n-nabiyyu wa rahmatu-llāhi wa barakātuh. As-salāmu \'alaynā wa \'alā \'ibādi-llāhi-s-sālihīn. Ashhadu an lā ilāha illā-llāh wa ashhadu anna Muhammadan \'abduhu wa rasūluh''',
            meaning: 'Les salutations sont à Allah ainsi que les prières et les bonnes œuvres. Que la paix soit sur toi ô Prophète ainsi que la miséricorde d\'Allah et Ses bénédictions...',
            description: 'Asseyez-vous et récitez le Tashahhud en levant l\'index de la main droite lors de l\'attestation de foi',
            // 2–3 photos locales (Tashahhud)
            imageAssets: [
              'assets/images/tachahoud-priere-2.jpg',
              'assets/images/tachahoud-priere.jpg',
            ],
            audioUrl: 'https://example.com/audio/tashahhud.mp3',
            type: SalatStepType.sitting,
            duration: 45,
            explanations: [
              'Asseyez-vous en tawarruk/iftirāsh selon la rakʿa et l\'école suivie.',
              'Placez la main droite sur la cuisse, index levé au moment de l\'attestation.',
              'Récitez le Tashahhud, puis les prières sur le Prophète ﷺ dans la dernière assise.',
            ],
            mistakes: [
              'Bouger l\'index sans repère ou continuellement.',
              'Oublier les salutations sur le Prophète ﷺ dans la dernière assise.',
            ],
            tips: [
              'Maintenez le regard baissé et le cœur présent durant toute la récitation.',
            ],
          ),
          SalatStep(
            id: 'taslim',
            title: 'Salutations finales (Taslîm)',
            arabicText: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ',
            transliteration: 'As-salāmu \'alaykum wa rahmatu-llāh',
            meaning: 'Que la paix et la miséricorde d\'Allah soient sur vous',
            description: 'Tournez la tête vers la droite puis vers la gauche en prononçant les salutations finales',
            // 2–3 photos locales (Taslîm)
            imageAssets: [
              'assets/images/taslim-finir-la-priere.jpg',
              'assets/images/taslim-finir-la-priere-2.jpg',
            ],
            audioUrl: 'https://example.com/audio/taslim.mp3',
            type: SalatStepType.sitting,
            duration: 10,
            explanations: [
              'Terminez la prière en saluant à droite puis à gauche.',
              'Incluez la miséricorde dans la salutation complète.',
            ],
            mistakes: [
              'Ne saluer que d\'un côté sans excuse valable.',
            ],
            tips: [
              'Accompagnez le salut d\'une gratitude intérieure pour la prière accomplie.',
            ],
          ),
        ],
      ),
      SalatCourse(
        id: 'advanced_salat',
        title: 'Perfectionner sa Salat',
        description: 'Approfondissez votre compréhension de la prière avec les invocations supplémentaires et les subtilités',
        estimatedDuration: 35,
        difficulty: 'Avancé',
        steps: [
          // Étape 1 — Niyya (intention)
          SalatStep(
            id: 'niyya',
            title: 'Niyya (Intention)',
            arabicText: 'النِّيَّةُ مَحَلُّهَا الْقَلْبُ',
            transliteration: 'An-niyyatu maḥalluhā al-qalb',
            meaning: 'L\'intention a pour place le cœur',
            description:
                'La niyya n\'a pas besoin d\'être prononcée. Elle consiste à déterminer dans le cœur quelle prière vous accomplissez, pour Allah uniquement.',
            imageAssets: const [],
            audioUrl: '',
            type: SalatStepType.transition,
            duration: 10,
            explanations: [
              'Formule générale optionnelle (non obligatoire): « نَوَيْتُ أَنْ أُصَلِّيَ لِلّٰهِ تَعَالَى » (Nawaytu an uṣalliya li-Llāhi taʿālā).',
              'Exemple Fajr (2 rakʿāt): « نَوَيْتُ صَلَاةَ الْفَجْرِ رَكْعَتَيْنِ لِلّٰهِ تَعَالَى » — Nawaytu ṣalāta-l-Fajri rakʿatayn li-Llāhi taʿālā.',
              'Exemple Ẓuhr (4 rakʿāt): « نَوَيْتُ صَلَاةَ الظُّهْرِ أَرْبَعَ رَكَعَاتٍ لِلّٰهِ تَعَالَى » — Nawaytu ṣalāta-ẓ-Ẓuhr arbaʿa rakaʿāt li-Llāhi taʿālā.',
              'Rappel: ne pas s\'attacher à une formulation précise; l\'essentiel est la présence du cœur.',
            ],
            mistakes: [
              'Penser que la formulation à voix haute est obligatoire.',
              'Changer d\'intention pendant la prière sans raison valable.',
            ],
            tips: [
              'Prenez une seconde avant le takbîr pour fixer sereinement votre intention.',
            ],
          ),

          // Étape 2 — Istiftāḥ (version 1)
          SalatStep(
            id: 'dua_istiftah',
            title: 'Invocation d\'ouverture (Du\'āʾ al-Istiftāḥ) — Version 1',
            arabicText:
                'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، وَتَبَارَكَ اسْمُكَ، وَتَعَالَى جَدُّكَ، وَلَا إِلَهَ غَيْرُكَ',
            transliteration:
                'Subḥānaka-llāhumma wa bi-ḥamdik, wa tabāraka-smuk, wa taʿālā jadduk, wa lā ilāha ghayruk',
            meaning:
                'Gloire et louange à Toi, ô Allah. Béni soit Ton Nom, exaltée soit Ta majesté, et il n\'y a de divinité que Toi.',
            description:
                'À réciter après le takbîr d\'ouverture et avant la Fātiḥa (en prière individuelle, à voix basse).',
            imageAssets: const [],
            audioUrl: 'https://example.com/audio/istiftah.mp3',
            type: SalatStepType.standing,
            duration: 15,
            explanations: [
              'Après le takbîr, récitez cette invocation à voix basse.',
              'Restez debout, mains croisées sur la poitrine.',
            ],
            mistakes: [
              'La négliger systématiquement par précipitation.',
            ],
            tips: [
              'Alternez les versions authentiques pour raviver la présence du cœur.',
            ],
          ),

          // Étape 3 — Istiftāḥ (version 2)
          SalatStep(
            id: 'dua_istiftah_ba3id',
            title: 'Invocation d\'ouverture — Version 2',
            arabicText:
                'اللَّهُمَّ بَاعِدْ بَيْنِي وَبَيْنَ خَطَايَايَ كَمَا بَاعَدْتَ بَيْنَ الْمَشْرِقِ وَالْمَغْرِبِ، اللَّهُمَّ نَقِّنِي مِنْ خَطَايَايَ كَمَا يُنَقَّى الثَّوْبُ الأَبْيَضُ مِنَ الدَّنَسِ، اللَّهُمَّ اغْسِلْنِي مِنْ خَطَايَايَ بِالثَّلْجِ وَالْمَاءِ وَالْبَرَدِ',
            transliteration:
                'Allāhumma bāʿid baynī wa bayna khaṭāyāya kamā bāʿadta bayna al-mashriqi wal-maghrib. Allāhumma naqqinī min khaṭāyāya kamā yunaqqā ath-thawbu al-abyaḍu mina-d-danas. Allāhumma-ghsilnī min khaṭāyāya bi-th-thalji wal-māʾi wal-barad.',
            meaning:
                'Ô Allah, éloigne-moi de mes péchés comme Tu as éloigné l\'Orient de l\'Occident. Ô Allah, purifie-moi de mes péchés comme on blanchit un vêtement blanc de toute souillure. Ô Allah, lave-moi de mes péchés par la neige, l\'eau et la grêle.',
            description: 'Version alternative authentique de l\'istiftāḥ.',
            imageAssets: const [],
            audioUrl: '',
            type: SalatStepType.standing,
            duration: 20,
            explanations: [
              'À alterner avec la version 1 pour varier les invocations d\'ouverture.',
            ],
            mistakes: const [],
            tips: const [],
          ),

          // Étape 4 — Istiftāḥ (version 3)
          SalatStep(
            id: 'dua_istiftah_kabira',
            title: 'Invocation d\'ouverture — Version 3',
            arabicText:
                'اللَّهُ أَكْبَرُ كَبِيرًا، وَالْحَمْدُ لِلَّهِ كَثِيرًا، وَسُبْحَانَ اللَّهِ بُكْرَةً وَأَصِيلًا',
            transliteration:
                'Allāhu akbaru kabīrā, wal-ḥamdu lillāhi kathīrā, wa subḥāna-llāhi bukratan wa aṣīlā.',
            meaning:
                'Allah est infiniment Grand, et louange abondante à Allah. Gloire à Allah, matin et soir.',
            description: 'Version récitée par certains Compagnons — authentique.',
            imageAssets: const [],
            audioUrl: '',
            type: SalatStepType.standing,
            duration: 10,
            explanations: const [],
            mistakes: const [],
            tips: const [],
          ),

          // Étape 5 — Prières sur le Prophète ﷺ (Salât Ibrâhîmiyya)
          SalatStep(
            id: 'after_tashahhud_salawat',
            title: 'Après le dernier Tashahhud — Prières sur le Prophète ﷺ',
            arabicText: '''اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ.
اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ.''',
            transliteration:
                '''Allāhumma ṣalli ʿalā Muḥammad wa ʿalā āli Muḥammad, kamā ṣallayta ʿalā Ibrāhīm wa ʿalā āli Ibrāhīm, innaka Ḥamīdun Majīd.
Allāhumma bārik ʿalā Muḥammad wa ʿalā āli Muḥammad, kamā bārakta ʿalā Ibrāhīm wa ʿalā āli Ibrāhīm, innaka Ḥamīdun Majīd.''',
            meaning:
                'Ô Allah, prie sur Muhammad et sur la famille de Muhammad, comme Tu as prié sur Ibrahim et sur la famille d’Ibrahim; Tu es Digne de louanges, Glorieux. Ô Allah, bénis Muhammad et la famille de Muhammad, comme Tu as béni Ibrahim et la famille d’Ibrahim; Tu es Digne de louanges, Glorieux.',
            description:
                'À réciter dans la dernière assise après le Tashahhud et avant le Taslîm. Formule authentique (Salât Ibrâhîmiyya) enseignée dans la prière.',
            imageAssets: const [],
            audioUrl: '',
            type: SalatStepType.sitting,
            duration: 20,
            explanations: const [],
            mistakes: const [],
            tips: const [],
          ),

          // Étape 6 — Invocations après le dernier Tashahhud (protection)
          SalatStep(
            id: 'after_tashahhud_protections',
            title: 'Après le dernier Tashahhud — Protection (4 épreuves)',
            arabicText:
                'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عَذَابِ جَهَنَّمَ، وَمِنْ عَذَابِ الْقَبْرِ، وَمِنْ فِتْنَةِ الْمَحْيَا وَالْمَمَاتِ، وَمِنْ شَرِّ فِتْنَةِ الْمَسِيحِ الدَّجَّالِ',
            transliteration:
                'Allāhumma innī aʿūdhu bika min ʿadhābi Jahannam, wa min ʿadhābi-l-qabr, wa min fitnati-l-maḥyā wa-l-mamāt, wa min sharri fitnati-l-Masīḥi-d-Dajjāl.',
            meaning:
                'Ô Allah, je me réfugie auprès de Toi contre le châtiment de l\'Enfer, contre le châtiment de la tombe, contre l\'épreuve de la vie et de la mort, et contre le mal de l\'épreuve du Faux Messie.',
            description:
                'À dire avant le taslîm dans la dernière assise. Source: La Citadelle du Musulman.',
            imageAssets: const [],
            audioUrl: '',
            type: SalatStepType.sitting,
            duration: 15,
            explanations: const [],
            mistakes: const [],
            tips: const [],
          ),

          // Étape 7 — Invocations après le dernier Tashahhud (pardon enseigné à Abû Bakr)
          SalatStep(
            id: 'after_tashahhud_forgiveness',
            title: 'Après le dernier Tashahhud — Demande de pardon',
            arabicText:
                'اللَّهُمَّ إِنِّي ظَلَمْتُ نَفْسِي ظُلْمًا كَثِيرًا، وَلَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ، فَاغْفِرْ لِي مَغْفِرَةً مِنْ عِنْدِكَ، وَارْحَمْنِي، إِنَّكَ أَنْتَ الْغَفُورُ الرَّحِيمُ',
            transliteration:
                'Allāhumma innī ẓalamtu nafsī ẓulman kathīrā, wa lā yaghfiru-dh-dhunūba illā Anta, faghfir lī maghfiratan min ʿindik, warḥamnī, innaka Anta-l-Ghafūru-r-Raḥīm.',
            meaning:
                'Ô Allah, j\'ai beaucoup lésé mon âme et nul ne pardonne les péchés en dehors de Toi; accorde-moi un pardon venant de Toi et fais-moi miséricorde, car Tu es le Pardonneur, le Très Miséricordieux.',
            description: 'À dire avant le taslîm. Source: La Citadelle du Musulman.',
            imageAssets: const [],
            audioUrl: '',
            type: SalatStepType.sitting,
            duration: 15,
            explanations: const [],
            mistakes: const [],
            tips: const [],
          ),

          // Étape 8 — Invocations après le dernier Tashahhud (refuge contre le péché et la dette)
          SalatStep(
            id: 'after_tashahhud_sin_debt',
            title: 'Après le dernier Tashahhud — Refuge contre le péché et la dette',
            arabicText:
                'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْمَأْثَمِ وَالْمَغْرَمِ',
            transliteration:
                'Allāhumma innī aʿūdhu bika mina-l-maʼthami wa-l-maghram.',
            meaning:
                'Ô Allah, je me réfugie auprès de Toi contre le péché et l\'endettement.',
            description: 'À dire avant le taslîm. Source: La Citadelle du Musulman.',
            imageAssets: const [],
            audioUrl: '',
            type: SalatStepType.sitting,
            duration: 10,
            explanations: const [],
            mistakes: const [],
            tips: const [],
          ),

          // Étape 8 retirée: « Sunnahs recommandées » (demande client)
        ],
      ),
    ];
  }

  static SalatStep? getStepById(String stepId) {
    for (var course in getDefaultCourses()) {
      for (var step in course.steps) {
        if (step.id == stepId) {
          return step;
        }
      }
    }
    return null;
  }
}