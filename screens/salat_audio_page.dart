import 'package:flutter/material.dart';
import 'package:sajda/theme.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:sajda/models/npm_salat_media.dart';
import 'package:sajda/services/salat_asset_service.dart';

class SalatAudioPage extends StatefulWidget {
  const SalatAudioPage({super.key});

  @override
  State<SalatAudioPage> createState() => _SalatAudioPageState();
}

class _SalatAudioPageState extends State<SalatAudioPage> with TickerProviderStateMixin {
  String? _currentPlayingId;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  final AudioPlayer _player = AudioPlayer();
  List<NpmAudioItem> _assetAudios = const [];
  
  final List<SalatAudio> _audios = [
    SalatAudio(
      id: 'takbir',
      title: 'Takbîr de consécration',
      arabicText: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allāhu akbar',
      meaning: 'Allah est le plus grand',
      category: 'Ouverture',
      duration: 3,
    ),
    SalatAudio(
      id: 'fatiha',
      title: 'Sourate Al-Fatiha',
      arabicText: '''بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ
الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ
الرَّحْمَنِ الرَّحِيمِ
مَالِكِ يَوْمِ الدِّينِ
إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ
اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ
صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ
غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ''',
      transliteration: '''Bismillāhi-r-Rahmāni-r-Rahīm
Al-hamdu lillāhi Rabbi-l-ālamīn
Ar-Rahmāni-r-Rahīm
Māliki yawmi-d-dīn
Iyyāka na'budu wa iyyāka nasta'īn
Ihdinā-s-sirāta-l-mustaqīm
Sirāta-lladhīna an'amta 'alayhim
Ghayri-l-maghdūbi 'alayhim wa lā-d-dāllīn''',
      meaning: 'Au nom d\'Allah, le Tout Miséricordieux, le Très Miséricordieux. Louange à Allah, Seigneur de l\'univers...',
      category: 'Récitation',
      duration: 45,
    ),
    SalatAudio(
      id: 'ruku',
      title: 'Invocation du Rukû\'',
      arabicText: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
      transliteration: 'Subhāna rabbiya-l-\'azīm',
      meaning: 'Gloire à mon Seigneur le Magnifique',
      category: 'Rukû\'',
      duration: 8,
    ),
    SalatAudio(
      id: 'qawmah',
      title: 'Redressement après Rukû\'',
      arabicText: 'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ، رَبَّنَا وَلَكَ الْحَمْدُ',
      transliteration: 'Sami\'a-llāhu liman hamidah, Rabbanā wa laka-l-hamd',
      meaning: 'Allah entend celui qui Le loue, notre Seigneur, à Toi la louange',
      category: 'Transition',
      duration: 5,
    ),
    SalatAudio(
      id: 'sujud',
      title: 'Invocation du Sujûd',
      arabicText: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
      transliteration: 'Subhāna rabbiya-l-a\'lā',
      meaning: 'Gloire à mon Seigneur le Très-Haut',
      category: 'Sujûd',
      duration: 8,
    ),
    SalatAudio(
      id: 'juloos',
      title: 'Entre les prosternations',
      arabicText: 'رَبِّ اغْفِرْ لِي، رَبِّ اغْفِرْ لِي',
      transliteration: 'Rabbi-ghfir lī, Rabbi-ghfir lī',
      meaning: 'Mon Seigneur, pardonne-moi, mon Seigneur, pardonne-moi',
      category: 'Position assise',
      duration: 6,
    ),
    SalatAudio(
      id: 'tashahhud',
      title: 'Tashahhud',
      arabicText: '''التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ''',
      transliteration: '''At-tahiyyātu lillāhi wa-s-salawātu wa-t-tayyibāt. As-salāmu 'alayka ayyuha-n-nabiyyu wa rahmatu-llāhi wa barakātuh. As-salāmu 'alaynā wa 'alā 'ibādi-llāhi-s-sālihīn. Ashhadu an lā ilāha illā-llāh wa ashhadu anna Muhammadan 'abduhu wa rasūluh''',
      meaning: 'Les salutations sont à Allah ainsi que les prières et les bonnes œuvres. Que la paix soit sur toi ô Prophète...',
      category: 'Tashahhud',
      duration: 35,
    ),
    SalatAudio(
      id: 'taslim',
      title: 'Salutations finales',
      arabicText: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ',
      transliteration: 'As-salāmu \'alaykum wa rahmatu-llāh',
      meaning: 'Que la paix et la miséricorde d\'Allah soient sur vous',
      category: 'Clôture',
      duration: 4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_waveController);
    _player.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _currentPlayingId = null);
    });
    _loadAssetAudios();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadAssetAudios() async {
    try {
      final audios = await SalatAssetService.loadInvocationAudios();
      if (mounted) setState(() => _assetAudios = audios);
    } catch (_) {}
  }

  Future<void> _toggleAudio(SalatAudio audio) async {
    if (_currentPlayingId == audio.id) {
      // Stop current audio
      await _stopAudio();
    } else {
      // Stop any current audio and play new one
      await _stopAudio();
      await _playAudio(audio);
    }
  }

  Future<void> _playAudio(SalatAudio audio) async {
    try {
      // If real asset exists for this item id, play from assets
      final match = _assetAudios.firstWhere(
        (e) => _normalizeId(e.title) == _normalizeId(audio.id) || _normalizeId(e.title) == _normalizeId(audio.title),
        orElse: () => _assetAudios.firstWhere(
          (e) => _normalizeId(e.url.split('/').last) == _normalizeId(audio.id),
          orElse: () => NpmAudioItem(url: '', title: ''),
        ),
      );

      if (match.url.isNotEmpty) {
        await _player.stop();
        await _player.setSourceAsset(match.url);
        await _player.resume();
        setState(() {
          _currentPlayingId = audio.id;
          _waveController.repeat();
        });
        return;
      }

      // Fallback: synthetic snackbar timer if no local audio
      setState(() {
        _currentPlayingId = audio.id;
        _waveController.repeat();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aucun audio local trouvé pour "${audio.title}"'), backgroundColor: Colors.orange));
      Timer(Duration(seconds: audio.duration), () {
        if (_currentPlayingId == audio.id) _stopAudio();
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la lecture: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _normalizeId(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  Future<void> _stopAudio() async {
    setState(() {
      _currentPlayingId = null;
      _waveController.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = _audios.map((audio) => audio.category).toSet().toList();
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              IslamicColors.mysticBlue.withValues(alpha: 0.1),
              IslamicColors.pearlWhite.withValues(alpha: 0.8),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildIntroCard(),
              Expanded(
                child: DefaultTabController(
                  length: categories.length,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        labelColor: IslamicColors.mysticBlue,
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: IslamicColors.mysticBlue,
                        tabs: categories.map((category) => Tab(text: category)).toList(),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: categories.map((category) {
                            final categoryAudios = _audios.where(
                              (audio) => audio.category == category,
                            ).toList();
                            
                            return ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: categoryAudios.length,
                              itemBuilder: (context, index) {
                                return _buildAudioCard(categoryAudios[index]);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: IslamicColors.mysticBlue),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              '🎵 Invocations audio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: IslamicColors.mysticBlue,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up, color: IslamicColors.mysticBlue),
            onPressed: () {
              _showAudioTips();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.mysticBlue.withValues(alpha: 0.15),
            IslamicColors.mysticBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: IslamicColors.mysticBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: IslamicColors.mysticBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.headphones,
                  color: IslamicColors.mysticBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio guidé pour la Salat',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: IslamicColors.mysticBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Écoutez et apprenez la prononciation correcte',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Chaque invocation est accompagnée de sa translitération et de sa traduction pour vous aider dans votre apprentissage.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioCard(SalatAudio audio) {
    final isPlaying = _currentPlayingId == audio.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec titre et bouton play
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audio.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: IslamicColors.mysticBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${audio.duration}s',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleAudio(audio),
                  child: AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isPlaying 
                              ? IslamicColors.roseGold.withValues(alpha: 0.2)
                              : IslamicColors.mysticBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isPlaying)
                              ...List.generate(3, (index) {
                                return AnimatedContainer(
                                  duration: Duration(milliseconds: 300 + (index * 200)),
                                  width: 40.0 + (index * 8),
                                  height: 40.0 + (index * 8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: IslamicColors.roseGold.withValues(
                                        alpha: 0.3 - (index * 0.1)
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                );
                              }),
                            Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: isPlaying ? IslamicColors.roseGold : IslamicColors.mysticBlue,
                              size: 32,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Texte arabe
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: IslamicColors.emeraldGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: IslamicColors.emeraldGreen.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    audio.arabicText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: IslamicColors.emeraldGreen,
                      fontWeight: FontWeight.bold,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                  if (audio.transliteration.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      audio.transliteration,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: IslamicColors.mysticBlue,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    audio.meaning,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAudioTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.lightbulb, color: IslamicColors.mysticBlue),
            const SizedBox(width: 8),
            const Text('Conseils d\'écoute'),
          ],
        ),
        content: const Text(
          '• Utilisez des écouteurs pour une meilleure expérience\n'
          '• Répétez après chaque audio pour mémoriser\n'
          '• Pratiquez régulièrement pour améliorer votre prononciation\n'
          '• N\'hésitez pas à réécouter plusieurs fois\n'
          '• Concentrez-vous sur le sens de chaque invocation',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}

class SalatAudio {
  final String id;
  final String title;
  final String arabicText;
  final String transliteration;
  final String meaning;
  final String category;
  final int duration; // en secondes

  SalatAudio({
    required this.id,
    required this.title,
    required this.arabicText,
    required this.transliteration,
    required this.meaning,
    required this.category,
    required this.duration,
  });
}