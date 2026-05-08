import 'package:flutter/material.dart';
import 'package:sajda/models/salat_course.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/screens/salat_step_detail_page.dart';
import 'package:sajda/screens/salat_positions_page.dart';
import 'package:sajda/screens/qibla_compass_page.dart';
// import 'package:sajda/screens/salat_learn_npm_page.dart';

class SalatCoursesPage extends StatefulWidget {
  const SalatCoursesPage({super.key});

  @override
  State<SalatCoursesPage> createState() => _SalatCoursesPageState();
}

class _SalatCoursesPageState extends State<SalatCoursesPage>
    with TickerProviderStateMixin {
  List<SalatCourse> _courses = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _courses = SalatCourse.getDefaultCourses();

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeCard(),
                          const SizedBox(height: 30),
                          _buildCoursesSection(),
                          const SizedBox(height: 30),
                          _buildQuickAccessSection(),
                          const SizedBox(height: 20),
                        ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            IslamicColors.emeraldGreen.withValues(alpha: 0.1),
            IslamicColors.pearlWhite.withValues(alpha: 0.8),
            Colors.white
          ]),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: IslamicColors.emeraldGreen),
              onPressed: () => Navigator.pop(context)),
          Expanded(
            child: Text('🕌 تعليم الصلاة',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: IslamicColors.emeraldGreen,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ),
          IconButton(
              icon: const Icon(Icons.bookmark_border,
                  color: IslamicColors.emeraldGreen),
              onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          IslamicColors.emeraldGreen.withValues(alpha: 0.15),
          IslamicColors.roseGold.withValues(alpha: 0.1)
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: IslamicColors.emeraldGreen.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: IslamicColors.emeraldGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.mosque,
                  color: IslamicColors.emeraldGreen, size: 28)),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Apprenez la Salat',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: IslamicColors.emeraldGreen,
                      fontWeight: FontWeight.bold)),
              Text('Le pilier fondamental de l\'Islam',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[600])),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Text(
            'Découvrez comment accomplir correctement la prière islamique avec des instructions détaillées et un guidage étape par étape (sans images).',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[700], height: 1.5)),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildCoursesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Cours disponibles',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: IslamicColors.emeraldGreen, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      ...(_courses.map((course) => _buildCourseCard(course)).toList()),
    ]);
  }

  Widget _buildCourseCard(SalatCourse course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SalatStepDetailPage(course: course)));
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(course.difficulty)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_getDifficultyIcon(course.difficulty),
                        color: _getDifficultyColor(course.difficulty),
                        size: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: IslamicColors.emeraldGreen)),
                        Text(course.difficulty,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color:
                                        _getDifficultyColor(course.difficulty),
                                    fontWeight: FontWeight.w600)),
                      ]),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
              ]),
              const SizedBox(height: 16),
              Text(course.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[700], height: 1.4)),
              const SizedBox(height: 16),
              Row(children: [
                _buildCourseInfo(
                    Icons.access_time,
                    '${course.estimatedDuration} min',
                    IslamicColors.mysticBlue),
                const SizedBox(width: 20),
                _buildCourseInfo(Icons.list_alt,
                    '${course.steps.length} étapes', IslamicColors.roseGold),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseInfo(IconData icon, String text, Color color) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text(text,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: color, fontWeight: FontWeight.w500))
    ]);
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'débutant':
        return IslamicColors.emeraldGreen;
      case 'intermédiaire':
        return IslamicColors.mysticBlue;
      case 'avancé':
        return IslamicColors.roseGold;
      default:
        return Colors.grey;
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'débutant':
        return Icons.star_outline;
      case 'intermédiaire':
        return Icons.star_half;
      case 'avancé':
        return Icons.star;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildQuickAccessSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Accès rapide',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: IslamicColors.emeraldGreen, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _buildQuickAccessCard('Positions de base', Icons.accessibility_new,
              IslamicColors.emeraldGreen, () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SalatPositionsPage()));
          }),
          _buildQuickAccessCard(
              'Guide Qibla', Icons.explore, IslamicColors.roseGold, () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const QiblaCompassPage()));
          }),
        ],
      ),
    ]);
  }

  Widget _buildQuickAccessCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05)
            ]),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}
