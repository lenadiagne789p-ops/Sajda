import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sajda/models/islamic_action.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/widgets/hassanat_counter.dart';
import 'package:sajda/widgets/spiritual_progress_circle.dart';
// import 'package:sajda/widgets/daily_actions_card.dart';
// Encadré de niveau supprimé pour éviter la répétition visuelle
import 'package:sajda/widgets/tier_callout_card.dart';
import 'package:sajda/screens/actions_page.dart';
import 'package:sajda/screens/profile_page.dart';

// import 'package:sajda/screens/allah_names_page.dart';
import 'package:sajda/screens/prayer_times_page.dart';
import 'package:sajda/screens/dhikr_counter_page.dart';
// import 'package:sajda/screens/streaks_page.dart';
import 'package:sajda/screens/leaderboard_page.dart';
import 'package:sajda/screens/salat_courses_page.dart';
import 'package:sajda/screens/quran_page.dart';
import 'package:sajda/screens/muslim_news_page.dart';
import 'package:sajda/screens/islamic_calendar_page.dart';
import 'package:sajda/screens/mosques_page.dart';
import 'package:sajda/screens/invocations_page.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/widgets/ui/modern_card.dart';
// import 'package:sajda/screens/pinned_actions_reorder_page.dart';
import 'package:sajda/widgets/ai/chat_assistant_sheet.dart';
import 'package:sajda/widgets/ui/sparkle_icon.dart';

import 'package:sajda/utils/lazy_loader.dart';
import 'package:sajda/utils/performance_monitor.dart';
import 'package:provider/provider.dart';
import 'package:sajda/utils/app_state.dart';
import 'package:sajda/models/user.dart';
import 'package:sajda/models/daily_verse.dart';
import 'package:sajda/services/daily_verse_service.dart';
import 'package:sajda/services/hadith_service.dart';
import 'package:sajda/screens/ayah_player_page.dart';
import 'package:sajda/widgets/ui/primary_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  List<IslamicAction> _dailyActions = [];
  bool _isLoading = true;
  StreamSubscription<void>? _dailyActionsSub;
  DailyVerse? _dailyVerse;
  String? _dailyVerseError;
  bool _isVerseExpanded = false;
  late Hadith _dailyHadith;
  bool _isHadithExpanded = false;

  @override
  void initState() {
    super.initState();
    _dailyHadith = HadithService.getHadithForToday();
    _loadData();
    // Refresh home counters when daily actions change anywhere in the app
    _dailyActionsSub = StorageService.dailyActionsChanged.listen((_) {
      if (mounted) _refreshData();
    });
    // Pins feature removed (no listener)
  }

  Future<void> _loadData() async {
    PerformanceMonitor.startTimer('loadHomeData');
    try {
      final actions = await StorageService.getDailyActions();
      DailyVerse? verse;
      String? verseError;
      try {
        verse = await DailyVerseService.getVerseForToday();
      } catch (e) {
        verseError = e.toString();
      }
      if (mounted) {
        setState(() {
          _dailyActions = actions;
          _isLoading = false;
          _dailyVerse = verse;
          _dailyVerseError = verseError;
        });
      }
      PerformanceMonitor.stopTimer('loadHomeData');
    } catch (e) {
      PerformanceMonitor.stopTimer('loadHomeData');
      if (mounted) {
         setState(() {
           _isLoading = false;
           _dailyVerse = null;
           _dailyVerseError = e.toString();
         });
      }
    }
  }

  @override
  void dispose() {
    _dailyActionsSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async => _loadData();

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const OptimizedLoadingIndicator(
          message: 'Chargement de votre parcours spirituel...',
          color: IslamicColors.emeraldGreen,
        ),
      );
    }

    // Pages sans l'onglet Coran
    final pages = [
      _buildHomePage(),
      LazyLoader.delayed(child: const PrayerTimesPage(), delay: const Duration(milliseconds: 250)),
      LazyLoader.delayed(child: const ActionsPage(), delay: const Duration(milliseconds: 300)),
      LazyLoader.delayed(child: const DhikrCounterPage(), delay: const Duration(milliseconds: 350)),
      LazyLoader.delayed(child: const MosquesPage(), delay: const Duration(milliseconds: 400)),
      LazyLoader.delayed(child: const ProfilePage(), delay: const Duration(milliseconds: 450)),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Removed custom page background; ambient background now shown globally

  Widget _buildHomePage() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        color: IslamicColors.emeraldGreen,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(20.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildWelcomeSection(),
                  const SizedBox(height: 30),
                   _buildProgressSection(),
                  const SizedBox(height: 20),
                   _buildDailyVerseSection(),
                   const SizedBox(height: 20),
                   _buildDailyHadithSection(),
                   const SizedBox(height: 20),
          // Place the inspiring card right under Spiritual Progress
                  _buildMotivationalSection(),
                  const SizedBox(height: 30),
          // Section Épinglés supprimée
                  // QuranReadingWidget retiré
                  _buildFeaturedToolsSection(),
                  const SizedBox(height: 30),
                  // Motivational section moved above
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Épinglés supprimée

  Widget _buildDailyVerseSection() {
    if (_dailyVerse == null && (_dailyVerseError == null || _dailyVerseError!.isEmpty)) {
      return const SizedBox.shrink();
    }

    if (_dailyVerse == null) {
      return ModernCard(
        padding: const EdgeInsets.all(20),
        tintColor: IslamicColors.softViolet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_stories, color: IslamicColors.softViolet, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Verset du jour indisponible',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Impossible de récupérer le verset du jour pour le moment. Réessaie plus tard.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final verse = _dailyVerse!;
    final theme = Theme.of(context);
    final surahLabel = verse.surahArabicName.isNotEmpty
        ? '${verse.surahNumber}. ${verse.surahArabicName}'
        : 'Sourate ${verse.surahNumber}';
    final translationLabel = verse.translationEdition == 'fr.hamidullah'
        ? 'Traduction: Hamidullah'
        : 'Traduction: ${verse.translationEdition}';

    // Header compact + contenu extensible
    final header = Row(
      children: [
        Icon(Icons.auto_stories, color: IslamicColors.softViolet.withValues(alpha: 0.9), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verset du jour',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: IslamicColors.softViolet,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$surahLabel • v${verse.ayahNumber}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AnimatedRotation(
          turns: _isVerseExpanded ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: const Icon(Icons.keyboard_arrow_down, color: IslamicColors.softViolet, size: 24),
        ),
      ],
    );

    final expandedContent = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Text(
          verse.arabicText,
          style: theme.textTheme.titleLarge?.copyWith(
            color: IslamicColors.softViolet,
            height: 1.6,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        if (verse.translationText != null && verse.translationText!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            verse.translationText!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildInfoChip(Icons.bookmark_added, '$surahLabel • v${verse.ayahNumber}'),
            if (verse.surahEnglishTranslation.isNotEmpty)
              _buildInfoChip(Icons.translate, verse.surahEnglishTranslation),
            _buildInfoChip(Icons.language, translationLabel),
            if (verse.revelationType.isNotEmpty)
              _buildInfoChip(Icons.mosque, verse.revelationType == 'Meccan' ? 'Révélée à La Mecque' : 'Révélée à Médine'),
          ],
        ),
        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Ouvrir le lecteur',
          onPressed: () => _openDailyVerse(verse),
          expanded: false,
        ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _isVerseExpanded = !_isVerseExpanded),
      child: ModernCard(
        padding: const EdgeInsets.all(16),
        tintColor: IslamicColors.softViolet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _isVerseExpanded
                  ? expandedContent
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        // court extrait pour l'état compact
                        (verse.translationText != null && verse.translationText!.trim().isNotEmpty)
                            ? verse.translationText!
                            : verse.arabicText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyHadithSection() {
    final theme = Theme.of(context);
    final hadith = _dailyHadith;
    final headerRow = Row(
      children: [
        Icon(Icons.format_quote, color: IslamicColors.roseGold.withValues(alpha: 0.9), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hadith du jour',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: IslamicColors.roseGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hadith.source,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        AnimatedRotation(
          turns: _isHadithExpanded ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: Icon(Icons.keyboard_arrow_down, color: IslamicColors.roseGold, size: 24),
        ),
      ],
    );

    final expandedContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          '\u201c${hadith.text}\u201d',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontStyle: FontStyle.italic,
            height: 1.6,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.justify,
        ),
        if (hadith.narrator != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: IslamicColors.roseGold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hadith.narrator!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: IslamicColors.roseGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.menu_book_outlined, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hadith.source,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _isHadithExpanded = !_isHadithExpanded),
      child: ModernCard(
        padding: const EdgeInsets.all(16),
        tintColor: IslamicColors.roseGold,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headerRow,
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _isHadithExpanded
                  ? expandedContent
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        hadith.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _openDailyVerse(DailyVerse verse) {
    if (verse.ayahs.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AyahPlayerPage(
          surahNumber: verse.surahNumber,
          surahEnglishName: verse.surahEnglishName,
          surahArabicName: verse.surahArabicName,
          surahMeta: verse.meta,
          ayahs: verse.ayahs,
          initialAyahIndex: verse.ayahIndex,
          initialTranslationEdition: verse.translationEdition,
          initialShowTranslation: true,
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final appUser = context.watch<AppState>().user;
    String _firstNameOf(String name) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) return '';
      final parts = trimmed.split(RegExp(r"\s+|[-_]"));
      return parts.first;
    }
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: _BotLeadingButton(onTap: () {
          ChatAssistantSheet.show(context);
        }),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.emeraldAurora,
            ),
            child: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsetsDirectional.only(bottom: 12),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_firstNameOf(appUser.name).isNotEmpty)
                    Text(
                      _firstNameOf(appUser.name),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    _todayFr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: HassanatCounter(
            hassanat: appUser.totalHassanat,
            user: appUser,
          ),
        ),
      ],
    );
  }

  String _todayFr() {
    const days = ['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'];
    const months = ['janvier','février','mars','avril','mai','juin','juillet','août','septembre','octobre','novembre','décembre'];
    final now = DateTime.now();
    final dayName = days[(now.weekday - 1) % 7];
    final monthName = months[now.month - 1];
    return '$dayName ${now.day} $monthName';
  }

  // Avatar supprimé de l'app bar — photos de profil désactivées

  Widget _buildWelcomeSection() {
    final appUser = context.watch<AppState>().user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (appUser.streak > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: IslamicColors.roseGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department, color: IslamicColors.roseGold, size: 16),
                const SizedBox(width: 4),
                Text('${appUser.streak} jours consécutifs',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: IslamicColors.roseGold, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressSection() {
    final appUser = context.watch<AppState>().user;
    return Column(
      children: [
        Text(
          'Votre Progression Spirituelle',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        // Rendu optimisé avec RepaintBoundary pour éviter les repaints inutiles sur Web
        const SizedBox(height: 4),
        RepaintBoundary(
          child: SpiritualProgressCircle(user: appUser, dailyActions: _dailyActions),
        ),
        const SizedBox(height: 16),
        _buildTierCalloutIfNeeded(appUser),
      ],
    );
  }

  Widget _buildTierCalloutIfNeeded(User appUser) {
    // Affiche l'encadré pour le palier "Aspirant — Quartz" (tiers bas) afin d'encourager;
    // pour d'autres paliers on peut étendre plus tard si besoin.
    // On se base sur LevelSystem dans le widget pour le visuel.
    return TierCalloutCard(
      user: appUser,
      onViewActions: () => _onItemTapped(2),
    );
  }

  // Section Actions à faire retirée de l'accueil selon demande

  Widget _buildMotivationalSection() {
    final motivationalQuotes = [
      {
        'arabic': 'وَمَنْ أَحْيَاهَا فَكَأَنَّمَا أَحْيَا النَّاسَ جَمِيعًا',
        'french': 'Celui qui sauve une vie, c\'est comme s\'il avait sauvé l\'humanité entière',
        'reference': 'Coran 5:32'
      },
      {
        'arabic': 'إِنَّ اللَّهَ يُحِبُّ الْمُحْسِنِينَ',
        'french': 'En vérité, Allah aime les bienfaisants',
        'reference': 'Coran 2:195'
      },
      {
        'arabic': 'وَمَن تَطَوَّعَ خَيْرًا فَإِنَّ اللَّهَ شَاكِرٌ عَلِيمٌ',
        'french': 'Quiconque fait spontanément une bonne œuvre, Allah est Reconnaissant et Omniscient',
        'reference': 'Coran 2:158'
      },
    ];

    final quote = motivationalQuotes[DateTime.now().day % motivationalQuotes.length];

    return ModernCard(
      padding: const EdgeInsets.all(20),
      tintColor: IslamicColors.mysticBlue,
      child: Column(
        children: [
          const Icon(
            Icons.format_quote,
            color: IslamicColors.mysticBlue,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            quote['arabic']!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: IslamicColors.mysticBlue,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          Text(
            quote['french']!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: IslamicColors.emeraldGreen,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '— ${quote['reference']}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: IslamicColors.roseGold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outils Spirituels',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          // Make tiles taller to avoid vertical overflow on small screens or large text
          childAspectRatio: 0.98,
          children: [
            // Carte Coran retirée
            _buildToolCard(
              'مواقيت الصلاة',
              'Horaires de Prière',
              Icons.schedule,
              IslamicColors.roseGold,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrayerTimesPage()),
              ),
            ),
            _buildToolCard(
              'المسبحة',
              'Compteur Dhikr',
              Icons.favorite,
              IslamicColors.dustyRose,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DhikrCounterPage()),
              ),
            ),
            _buildToolCard(
              'القرآن الكريم',
              'Lecture du Coran',
              Icons.menu_book,
              IslamicColors.softViolet,
              () {
                // Ouvre désormais le sélecteur de sourates avant la lecture
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuranPage()),
                );
              },
            ),
            _buildToolCard(
              'التقويم الهجري',
              'Calendrier',
              Icons.calendar_month,
              IslamicColors.mysticBlue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IslamicCalendarPage()),
              ),
            ),
            _buildToolCard(
              'الأدعية',
              'Invocations',
              Icons.menu_book,
              IslamicColors.emeraldGreen,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InvocationsPage()),
              ),
            ),
            _buildToolCard(
              'الترتيب',
              'Classement',
              Icons.leaderboard,
              IslamicColors.mysticBlue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeaderboardPage()),
              ),
            ),
            _buildToolCard(
              'تعليم الصلاة',
              'Cours de Salat',
              Icons.mosque,
              IslamicColors.emeraldGreen,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SalatCoursesPage()),
              ),
            ),
            _buildToolCard(
              'الأخبار',
              'Actualités',
              Icons.article,
              IslamicColors.mysticBlue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MuslimNewsPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard(
    String titleArabic,
    String titleFrench,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      tintColor: color,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            titleArabic,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            titleFrench,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: IslamicColors.emeraldGreen,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time),
              activeIcon: Icon(Icons.access_time_filled),
              label: 'Prière',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist),
              activeIcon: Icon(Icons.checklist),
              label: 'Actions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Dhikr',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              activeIcon: Icon(Icons.location_on),
              label: 'Mosquées',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class _BotLeadingButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BotLeadingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            // Softer glassy surface without a harsh border
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const SparkleIcon(
            icon: Icons.auto_awesome_rounded,
            size: 22,
            color: Colors.white,
            haloColor: IslamicColors.roseGold,
          ),
        ),
      ),
    );
  }
}
