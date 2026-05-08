import 'package:flutter/foundation.dart';

/// Moniteur de performances pour identifier les goulots d'étranglement
class PerformanceMonitor {
  static final Map<String, DateTime> _timers = {};
  static final Map<String, Duration> _measurements = {};
  
  /// Démarre un chronomètre pour mesurer une opération
  static void startTimer(String operation) {
    if (kDebugMode) {
      _timers[operation] = DateTime.now();
    }
  }
  
  /// Arrête le chronomètre et enregistre la mesure
  static void stopTimer(String operation) {
    if (kDebugMode && _timers.containsKey(operation)) {
      final duration = DateTime.now().difference(_timers[operation]!);
      _measurements[operation] = duration;
      
      // Log si l'opération est lente
      if (duration.inMilliseconds > 100) {
        debugPrint('⚠️ Opération lente détectée: $operation - ${duration.inMilliseconds}ms');
      } else {
        debugPrint('✅ $operation - ${duration.inMilliseconds}ms');
      }
      
      _timers.remove(operation);
    }
  }
  
  /// Mesure une opération Future
  static Future<T> measureAsync<T>(String operation, Future<T> future) async {
    startTimer(operation);
    try {
      final result = await future;
      stopTimer(operation);
      return result;
    } catch (e) {
      stopTimer(operation);
      rethrow;
    }
  }
  
  /// Mesure une opération synchrone
  static T measure<T>(String operation, T Function() function) {
    startTimer(operation);
    try {
      final result = function();
      stopTimer(operation);
      return result;
    } catch (e) {
      stopTimer(operation);
      rethrow;
    }
  }
  
  /// Obtient toutes les mesures
  static Map<String, Duration> getAllMeasurements() {
    return Map.unmodifiable(_measurements);
  }
  
  /// Affiche un rapport de performances
  static void printReport() {
    if (kDebugMode && _measurements.isNotEmpty) {
      debugPrint('\n📊 Rapport de performances:');
      debugPrint('=' * 50);
      
      final sorted = _measurements.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (final entry in sorted) {
        final operation = entry.key;
        final duration = entry.value;
        final status = duration.inMilliseconds > 100 ? '🔴' : '🟢';
        debugPrint('$status $operation: ${duration.inMilliseconds}ms');
      }
      
      debugPrint('=' * 50);
    }
  }
  
  /// Remet à zéro toutes les mesures
  static void reset() {
    _timers.clear();
    _measurements.clear();
  }
}