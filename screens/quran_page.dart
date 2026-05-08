import 'package:flutter/material.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/services/quran_api_service.dart';
import 'package:sajda/screens/ayah_player_page.dart';
import 'package:sajda/widgets/ui/gradient_app_bar.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/utils/performance_monitor.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> surahs = [];
  bool isLoading = true;
  bool hasError = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _lastBookmark;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSurahs();
    _loadBookmark();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        hasError = false;
      });
    }
    
    try {
      final surahsList = await PerformanceMonitor.measureAsync('quran_page:get_surah_list', QuranApiService.getSurahsList());
      if (mounted) {
        setState(() {
          surahs = surahsList.isNotEmpty ? surahsList : QuranApiService.staticSurahsList();
          isLoading = false;
          hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // En cas d'exception, basculer sur la liste statique hors ligne plutôt que d'afficher une erreur
          surahs = QuranApiService.staticSurahsList();
          isLoading = false;
          hasError = false;
        });
      }
    }
  }

  Future<void> _loadBookmark() async {
    final data = await StorageService.getQuranReadingData();
    if (mounted) {
      setState(() {
        _lastBookmark = data.isNotEmpty ? data : null;
      });
    }
  }

  List<Map<String, dynamic>> get filteredSurahs {
    if (searchQuery.isEmpty) return surahs;
    return surahs.where((surah) {
      final name = surah['name']?.toString().toLowerCase() ?? '';
      final englishName = surah['englishName']?.toString().toLowerCase() ?? '';
      final translation = surah['englishNameTranslation']?.toString().toLowerCase() ?? '';
      final number = surah['number']?.toString() ?? '';
      final query = searchQuery.toLowerCase();
      
      return name.contains(query) || 
             englishName.contains(query) || 
             translation.contains(query) ||
             number.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      // Use solid background to avoid rare web canvas asserts on transparent routes (Flutter Web)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          GradientSliverAppBar(
            title: '📖 Saint Coran',
            subtitle: '${surahs.length} sourates',
            expandedHeight: 180,
            pinned: true,
            showBack: true,
            actions: const [],
          ),
          if (_lastBookmark != null && (_lastBookmark!['surahNumber'] != null))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildResumeCard(context),
              ),
            ),
          SliverToBoxAdapter(
            child: const SizedBox(height: 8),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Arabe', icon: Icon(Icons.translate)),
                  Tab(text: 'Traduction', icon: Icon(Icons.language)),
                  Tab(text: 'Audio', icon: Icon(Icons.volume_up)),
                ],
                indicatorColor: cs.secondary,
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSearchBar(),
            ),
          ),
          isLoading ? 
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(50),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Chargement des sourates...'),
                    ],
                  ),
                ),
              ),
            ) :
            hasError ?
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(50),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Vérifiez votre connexion internet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadSurahs,
                        icon: Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            ) :
            filteredSurahs.isEmpty ?
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(50),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucune sourate trouvée',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Essayez une autre recherche',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ) :
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final surah = filteredSurahs[index];
                  return _buildSurahCard(surah);
                },
                childCount: filteredSurahs.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Rechercher une sourate...',
          prefixIcon: const Icon(Icons.search, color: IslamicColors.emeraldGreen),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: IslamicColors.emeraldGreen),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.cardTheme.color,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildSurahCard(Map<String, dynamic> surah) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openSurahReader(surah),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Numéro de la sourate
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [IslamicColors.emeraldGreen, IslamicColors.roseGold],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      '${surah['number']}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Informations de la sourate
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah['name'] ?? '',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: IslamicColors.emeraldGreen,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        surah['englishName'] ?? '',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        surah['englishNameTranslation'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.75),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Informations supplémentaires
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: surah['revelationType'] == 'Meccan' 
                            ? IslamicColors.roseGold.withValues(alpha: 0.2)
                            : IslamicColors.emeraldGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        surah['revelationType'] == 'Meccan' ? 'Mecque' : 'Médine',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: surah['revelationType'] == 'Meccan' 
                              ? IslamicColors.roseGold
                              : IslamicColors.emeraldGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.format_list_numbered,
                          size: 16,
                          color: cs.onSurface.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${surah['numberOfAyahs']} versets',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumeCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sn = (_lastBookmark?['surahNumber'] as int?) ?? 0;
    final an = (_lastBookmark?['ayahNumber'] as int?) ?? 0;
    final se = (_lastBookmark?['surahEnglishName']?.toString() ?? 'Sourate $sn');
    final sa = (_lastBookmark?['surahArabicName']?.toString() ?? '');
    return Material(
      color: theme.cardTheme.color,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.bookmark, color: IslamicColors.roseGold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reprendre la lecture', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('$se • $sa • verset $an', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.8))),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () async {
                Map<String, dynamic>? target = surahs.firstWhere(
                  (s) => (s['number'] == sn),
                  orElse: () => {},
                );
                if (target.isEmpty) {
                  target = {
                    'number': sn,
                    'name': sa.isNotEmpty ? sa : 'سورة',
                    'englishName': se,
                    'numberOfAyahs': 7,
                    'revelationType': 'Meccan',
                  };
                }
                final idx = (_lastBookmark?['ayahIndex'] as int?) ?? 0;
                await _openSurahReader(target, initialAyahIndex: idx);
              },
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text('Reprendre'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSurahReader(Map<String, dynamic> surah, {int initialAyahIndex = 0}) async {
    final theme = Theme.of(context);
    // Small blocking loader while we fetch verses + translation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Chargement de la sourate...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            ],
          ),
        ),
      ),
    );

    try {
      final sn = (surah['number'] as int?) ?? 0;
      if (sn <= 0) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numéro de sourate invalide.')));
        return;
      }

      final bundle = await QuranApiService.getSurahForReading(
        sn,
        translationEdition: 'fr.hamidullah',
        includeTranslation: true,
      );

      // Prepare meta and ayahs in the shape expected by AyahPlayerPage
      final meta = (bundle['meta'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(bundle['meta'] as Map<String, dynamic>)
          : <String, dynamic>{};
      final ayahsRaw = <Map<String, dynamic>>[];
      if (bundle['ayahs'] is List) {
        for (final a in bundle['ayahs'] as List) {
          if (a is Map) {
            final m = Map<String, dynamic>.from(a);
            final numIn = m['numberInSurah'] ?? m['number'] ?? 1;
            final arab = m['arabic']?.toString() ?? m['text']?.toString() ?? '';
            final tr = m['translation']?.toString();
            ayahsRaw.add({
              'numberInSurah': numIn is int ? numIn : int.tryParse(numIn.toString()) ?? 1,
              'arabic': arab,
              if (tr != null && tr.isNotEmpty) 'translation': tr,
            });
          }
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // close loader

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AyahPlayerPage(
            surahNumber: sn,
            surahEnglishName: meta['englishName']?.toString() ?? (surah['englishName']?.toString() ?? 'Sourate $sn'),
            surahArabicName: meta['name']?.toString() ?? (surah['name']?.toString() ?? ''),
            surahMeta: meta,
            ayahs: ayahsRaw,
            initialAyahIndex: initialAyahIndex.clamp(0, ayahsRaw.isNotEmpty ? ayahsRaw.length - 1 : 0),
            initialTranslationEdition: meta['translationEdition']?.toString() ?? 'fr.hamidullah',
            initialShowTranslation: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }
}