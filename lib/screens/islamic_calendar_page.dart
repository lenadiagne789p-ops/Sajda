import 'package:flutter/material.dart';
import 'package:sajda/models/islamic_calendar.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/services/notification_service.dart';

class IslamicCalendarPage extends StatefulWidget {
  const IslamicCalendarPage({super.key});

  @override
  State<IslamicCalendarPage> createState() => _IslamicCalendarPageState();
}

class _IslamicCalendarPageState extends State<IslamicCalendarPage>
    with TickerProviderStateMixin {
  List<IslamicEvent> _events = [];
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _events = IslamicEvent.getAnnualEvents();
    
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildCurrentDateCard(),
                    const SizedBox(height: 20),
                    _buildTodayEventsCard(),
                    const SizedBox(height: 20),
                    _buildUpcomingEventsSection(),
                    const SizedBox(height: 20),
                    _buildAllEventsSection(),
                    const SizedBox(height: 20),
                  ]),
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
          IslamicColors.pearlWhite,
          IslamicColors.pearlWhite.withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 0.9),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Calendrier Islamique',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildCurrentDateCard() {
    final hijriDate = HijriDate.fromDateTime(DateTime.now());
    final gregorianDate = DateTime.now();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.emeraldGreen.withValues(alpha: 0.1),
            IslamicColors.roseGold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: IslamicColors.emeraldGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: IslamicColors.emeraldGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Aujourd\'hui',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IslamicColors.emeraldGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  hijriDate.toArabicString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: IslamicColors.emeraldGreen,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  hijriDate.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: IslamicColors.roseGold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${gregorianDate.day}/${gregorianDate.month}/${gregorianDate.year}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayEventsCard() {
    final todayEvents = _events.where((event) => event.isToday()).toList();
    
    if (todayEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available,
              color: Colors.grey[600],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun événement aujourd\'hui',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Profitez de cette journée pour faire du dhikr',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Événements d\'aujourd\'hui',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...todayEvents.map((event) => _buildSpecialEventCard(event)),
      ],
    );
  }

  Widget _buildSpecialEventCard(IslamicEvent event) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => _showEventDetails(event),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  event.color.withValues(alpha: 0.2),
                  event.color.withValues(alpha: 0.1),
                  event.color.withValues(alpha: 0.05),
                ],
                stops: const [0.0, 0.5, 1.0],
                transform: GradientRotation(_shimmerAnimation.value),
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: event.color.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: event.color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: event.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(event.icon, color: event.color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.nameArabic,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: event.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            event.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.occurrence,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (event.specialHassanatMultiplier > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: IslamicColors.roseGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars, color: IslamicColors.roseGold, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'x${event.specialHassanatMultiplier}',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: IslamicColors.roseGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_month, color: event.color, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date hijri : ${event.date.toString()}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          Text(
                            'Date grégorienne : ${event.date.toGregorianString()}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (event.recommendedActions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Actions recommandées:',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: event.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: event.recommendedActions
                        .map((action) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: event.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: event.color.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                action,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: event.color,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Voir détails',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: event.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: event.color,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingEventsSection() {
    final upcomingEvents = _events.where((event) => event.isThisWeek() && !event.isToday()).toList();
    
    if (upcomingEvents.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Événements à venir',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: upcomingEvents.length,
            itemBuilder: (context, index) {
              return _buildUpcomingEventCard(upcomingEvents[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingEventCard(IslamicEvent event) {
    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              event.color.withValues(alpha: 0.1),
              event.color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: event.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(event.icon, color: event.color, size: 24),
                const SizedBox(width: 8),
                if (event.specialHassanatMultiplier > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: IslamicColors.roseGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'x${event.specialHassanatMultiplier}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: IslamicColors.roseGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              event.nameArabic,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: event.color,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              event.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              event.occurrence,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                event.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Détails',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: event.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_ios,
                  color: event.color,
                  size: 12,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllEventsSection() {
    final Map<IslamicEventType, List<IslamicEvent>> groupedEvents = {};
    for (final event in _events) {
      groupedEvents.putIfAbsent(event.type, () => []).add(event);
    }

    final orderedTypes = [
      IslamicEventType.festival,
      IslamicEventType.obligatoryFast,
      IslamicEventType.sacredNight,
      IslamicEventType.recommendedFast,
      IslamicEventType.specialSeason,
      IslamicEventType.commemoration,
    ].where((type) => groupedEvents.containsKey(type)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calendrier spirituel complet',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: IslamicColors.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...orderedTypes.map((type) {
          final events = groupedEvents[type]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getCategoryTitle(type),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: IslamicColors.emeraldGreen,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              ...events.map(_buildEventListItem),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildEventListItem(IslamicEvent event) {
    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: event.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(event.icon, color: event.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.nameArabic,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: event.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    event.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    event.occurrence,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    'Hijri: ${event.date.toString()} • Grégorien: ${event.date.toGregorianString()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (event.specialHassanatMultiplier > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: IslamicColors.roseGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars, color: IslamicColors.roseGold, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'x${event.specialHassanatMultiplier}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: IslamicColors.roseGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryTitle(IslamicEventType type) {
    switch (type) {
      case IslamicEventType.festival:
        return 'Fêtes (Aïd)';
      case IslamicEventType.obligatoryFast:
        return 'Jeûnes obligatoires';
      case IslamicEventType.recommendedFast:
        return 'Jeûnes recommandés';
      case IslamicEventType.sacredNight:
        return 'Nuits sacrées';
      case IslamicEventType.specialSeason:
        return 'Saisons spirituelles';
      case IslamicEventType.commemoration:
        return 'Commémorations';
    }
  }

  void _showEventDetails(IslamicEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventDetailSheet(event: event),
    );
  }
}

class EventDetailSheet extends StatelessWidget {
  final IslamicEvent event;

  const EventDetailSheet({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête avec bouton de fermeture
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 32),
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Bouton fermer
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: event.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(event.icon, color: event.color, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.nameArabic,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: event.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              event.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Date info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: event.color.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: event.color.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: event.color, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Date hijri : ${event.date.toString()}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: event.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_month, color: event.color, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Date grégorienne : ${event.date.toGregorianString()}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.access_time, color: event.color, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Période : ${event.occurrence}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Hassanat multiplier
                  if (event.specialHassanatMultiplier > 1) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            IslamicColors.roseGold.withValues(alpha: 0.1),
                            IslamicColors.roseGold.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.stars, color: IslamicColors.roseGold, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Récompense Spirituelle',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: IslamicColors.roseGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Les bonnes actions de ce jour sont multipliées par ${event.specialHassanatMultiplier}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: IslamicColors.roseGold,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'x${event.specialHassanatMultiplier}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: IslamicColors.emeraldGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 20),

                  if (event.benefits.isNotEmpty) ...[
                    Text(
                      'Bienfaits spirituels',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: IslamicColors.emeraldGreen,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...event.benefits.map(
                      (benefit) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: event.color.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: event.color.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.brightness_1, color: event.color, size: 10),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                benefit,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Fasting recommendations
                  if (_getFastingInfo(event).isNotEmpty) ...[
                    Text(
                      'Jeûne Recommandé',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: IslamicColors.emeraldGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.dining, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Information sur le jeûne',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getFastingInfo(event),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Recommended actions
                  if (event.recommendedActions.isNotEmpty) ...[
                    Text(
                      'Actions Recommandées',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: IslamicColors.emeraldGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...event.recommendedActions.map((action) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: event.color.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: event.color.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: event.color, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              action,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 20),
                  ],
                  
                  // Reminder button
                  FutureBuilder<bool>(
                    future: NotificationService.isReminderScheduled(event.id),
                    builder: (context, snapshot) {
                      final isScheduled = snapshot.data ?? false;
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isScheduled 
                            ? null 
                            : () => _scheduleReminder(context, event),
                          icon: Icon(
                            isScheduled ? Icons.check_circle : Icons.notifications_active, 
                            color: Colors.white
                          ),
                          label: Text(
                            isScheduled 
                              ? 'Rappel déjà programmé' 
                              : 'Programmer un rappel (3 jours avant)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isScheduled ? Colors.grey : event.color,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFastingInfo(IslamicEvent event) {
    switch (event.id) {
      case 'ashura':
        return 'Il est recommandé de jeûner le jour d\'Ashura (10 Muharram) ainsi que le jour précédent ou suivant. Le Prophète ﷺ a dit que jeûner ce jour efface les péchés de l\'année précédente.';
      case 'arafat':
        return 'Le jeûne du jour d\'Arafat est fortement recommandé pour ceux qui ne font pas le pèlerinage. Il efface les péchés de l\'année précédente et de l\'année suivante.';
      case 'laylat_nisf_shaban':
        return 'Il est recommandé de jeûner le jour suivant cette nuit bénie (15 Sha\'ban).';
      case 'fast_shaban':
        return 'Jeûner les jours blancs (13, 14, 15) de Sha\'ban permet d\'augmenter les œuvres avant l\'arrivée de Ramadan.';
      case 'hajj_start':
        return 'Il est recommandé de jeûner les 9 premiers jours de Dhul-Hijjah, surtout pour ceux qui ne font pas le pèlerinage.';
      case 'ramadan_start':
        return 'Le jeûne est obligatoire pendant tout le mois de Ramadan, de l\'aube au coucher du soleil.';
      case 'shawwal_fast':
        return 'Jeûner six jours de Shawwal après l\'Eid al-Fitr est fortement recommandé et équivaut à un jeûne de toute l\'année.';
      default:
        return '';
    }
  }

  Future<void> _scheduleReminder(BuildContext context, IslamicEvent event) async {
    try {
      // Check if reminder is already scheduled
      final isScheduled = await NotificationService.isReminderScheduled(event.id);
      
      if (isScheduled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Un rappel est déjà programmé pour ${event.name}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }

      // Schedule the reminder
      await NotificationService.scheduleIslamicEventReminder(event);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rappel programmé pour ${event.name}'),
              Text(
                '📅 Vous serez notifié 3 jours avant l\'événement',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
          backgroundColor: event.color,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la programmation du rappel: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}