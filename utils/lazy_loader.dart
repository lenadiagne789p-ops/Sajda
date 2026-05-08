import 'package:flutter/material.dart';

/// Utilitaire pour le chargement paresseux des composants
class LazyLoader {
  static const Duration _defaultDelay = Duration(milliseconds: 100);
  
  /// Charge un widget après un délai pour améliorer les performances
  static Widget delayed({
    required Widget child,
    Duration delay = _defaultDelay,
    Widget placeholder = const SizedBox.shrink(),
  }) {
    return FutureBuilder<void>(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return child;
        }
        return placeholder;
      },
    );
  }
  
  /// Charge une liste de widgets de manière échelonnée
  static List<Widget> staggeredList({
    required List<Widget> children,
    Duration staggerDelay = const Duration(milliseconds: 50),
  }) {
    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      
      return delayed(
        child: child,
        delay: Duration(milliseconds: staggerDelay.inMilliseconds * index),
      );
    }).toList();
  }
}

/// Widget pour afficher un indicateur de chargement optimisé
class OptimizedLoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;
  
  const OptimizedLoadingIndicator({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? theme.primaryColor,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}