import 'package:flutter/material.dart';
import 'package:sajda/models/prayer_times.dart';
import 'package:sajda/theme.dart';

class QuickAccessWidget extends StatelessWidget {
  final PrayerType? nextPrayer;
  final DateTime? nextTime;
  final VoidCallback onOpenPrayers;
  final VoidCallback onOpenActions;

  const QuickAccessWidget({
    super.key,
    required this.nextPrayer,
    required this.nextTime,
    required this.onOpenPrayers,
    required this.onOpenActions,
  });

  IconData _iconFor(PrayerType? p) {
    switch (p) {
      case PrayerType.fajr:
        return Icons.wb_sunny_outlined;
      case PrayerType.dhuhr:
        return Icons.wb_sunny;
      case PrayerType.asr:
        return Icons.wb_cloudy;
      case PrayerType.maghrib:
        return Icons.wb_twilight;
      case PrayerType.isha:
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }

  String _label(PrayerType? p) {
    switch (p) {
      case PrayerType.fajr:
        return 'Fajr';
      case PrayerType.dhuhr:
        return 'Dhuhr';
      case PrayerType.asr:
        return 'Asr';
      case PrayerType.maghrib:
        return 'Maghrib';
      case PrayerType.isha:
        return 'Isha';
      default:
        return 'Prochaine prière';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = IslamicColors.emeraldGreen;
    final timeStr = nextTime != null
        ? '${nextTime!.hour.toString().padLeft(2, '0')}:${nextTime!.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.12), IslamicColors.roseGold.withValues(alpha: 0.08)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(_iconFor(nextPrayer), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Prochaine prière', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                  Text('${_label(nextPrayer)} • $timeStr', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onOpenPrayers,
                  icon: const Icon(Icons.access_time, color: Colors.white),
                  label: const Text('Prière'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenActions,
                  icon: const Icon(Icons.fact_check, color: Colors.white),
                  label: const Text('Actions'),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
