import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sajda/models/reminder.dart';

class ReminderService {
  static const String _remindersKey = 'spiritual_reminders';
  static List<Reminder> _reminders = [];
  static Timer? _reminderTimer;
  static BuildContext? _globalContext;
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void initialize(BuildContext context) {
    _globalContext = context;
    _loadReminders();
    _startReminderTimer();
  }

  static void initializeWithNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _loadReminders();
    _startReminderTimer();
  }

  static void dispose() {
    _reminderTimer?.cancel();
    _globalContext = null;
    _navigatorKey = null;
  }

  static Future<void> _loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = prefs.getString(_remindersKey);
      
      if (remindersJson != null) {
        final List<dynamic> jsonList = jsonDecode(remindersJson);
        _reminders = jsonList.map((json) => Reminder.fromJson(json)).toList();
      } else {
        // Initialize with default reminders
        _reminders = Reminder.getDefaultReminders();
        await _saveReminders();
      }
    } catch (e) {
      // If error loading, use defaults
      _reminders = Reminder.getDefaultReminders();
    }
  }

  static Future<void> _saveReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _reminders.map((reminder) => reminder.toJson()).toList();
      await prefs.setString(_remindersKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving reminders: $e');
    }
  }

  static List<Reminder> getReminders() {
    return List<Reminder>.from(_reminders);
  }

  static List<Reminder> getActiveReminders() {
    return _reminders.where((reminder) => reminder.isActive).toList();
  }

  static Future<void> addReminder(Reminder reminder) async {
    _reminders.add(reminder);
    await _saveReminders();
  }

  static Future<void> updateReminder(Reminder updatedReminder) async {
    final index = _reminders.indexWhere((r) => r.id == updatedReminder.id);
    if (index != -1) {
      _reminders[index] = updatedReminder;
      await _saveReminders();
    }
  }

  static Future<void> deleteReminder(String reminderId) async {
    _reminders.removeWhere((reminder) => reminder.id == reminderId);
    await _saveReminders();
  }

  static Future<void> toggleReminder(String reminderId) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(
        isActive: !_reminders[index].isActive,
      );
      await _saveReminders();
    }
  }

  static void _startReminderTimer() {
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkForActiveReminders();
    });
  }

  static void _checkForActiveReminders() {
    final ctx = _navigatorKey?.currentContext ?? _globalContext;
    if (ctx == null) return;

    final now = DateTime.now();
    final currentTime = TimeOfDay.now();
    final currentDayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday

    for (final reminder in getActiveReminders()) {
      if (reminder.days.contains(currentDayOfWeek) &&
          reminder.time.hour == currentTime.hour &&
          reminder.time.minute == currentTime.minute) {
        _showReminderPopup(reminder);
      }
    }
  }

  static void _showReminderPopup(Reminder reminder) {
    final ctx = _navigatorKey?.currentContext ?? _globalContext;
    if (ctx == null) return;

    showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (context) => ReminderPopup(reminder: reminder),
    );

    // Auto dismiss after 30 seconds
    Timer(const Duration(seconds: 30), () {
      final popCtx = _navigatorKey?.currentContext ?? _globalContext;
      if (popCtx != null && Navigator.canPop(popCtx)) {
        Navigator.of(popCtx).pop();
      }
    });
  }

  static List<String> getDayNames() {
    return ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  }

  static String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ReminderPopup extends StatefulWidget {
  final Reminder reminder;

  const ReminderPopup({super.key, required this.reminder});

  @override
  State<ReminderPopup> createState() => _ReminderPopupState();
}

class _ReminderPopupState extends State<ReminderPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 8,
              content: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.reminder.type.color.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: widget.reminder.type.color,
                        shape: BoxShape.circle,
                        boxShadow: const [],
                      ),
                      child: Icon(
                        widget.reminder.type.icon,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.reminder.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: widget.reminder.type.color,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.reminder.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.reminder.arabicMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: widget.reminder.type.color,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Plus tard',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Navigate to appropriate action page
                              _navigateToAction();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.reminder.type.color,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              'Faire maintenant',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToAction() {
    // Navigate to appropriate screen based on reminder type
    switch (widget.reminder.type) {
      case ReminderType.prayer:
        // Navigate to prayer times or actions
        Navigator.of(context).pushNamed('/actions');
        break;
      case ReminderType.dhikr:
        Navigator.of(context).pushNamed('/dhikr');
        break;
      case ReminderType.quran:
        Navigator.of(context).pushNamed('/actions');
        break;
      case ReminderType.charity:
        Navigator.of(context).pushNamed('/actions');
        break;
      case ReminderType.repentance:
        Navigator.of(context).pushNamed('/dhikr');
        break;
      default:
        Navigator.of(context).pushNamed('/actions');
    }
  }
}