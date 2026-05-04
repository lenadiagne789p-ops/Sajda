import 'package:flutter/material.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/screens/subscription_screen.dart';

class PremiumFeatureLock extends StatelessWidget {
  final Widget child;
  final bool isPremium;
  final String featureName;
  final String description;

  const PremiumFeatureLock({
    super.key,
    required this.child,
    required this.isPremium,
    required this.featureName,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return child;
    }

    return Stack(
      children: [
        // Contenu désactivé
        Opacity(
          opacity: 0.3,
          child: IgnorePointer(child: child),
        ),
        
        // Overlay de verrouillage
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: IslamicColors.roseGold,
                      boxShadow: [
                        BoxShadow(
                           color: IslamicColors.roseGold.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    featureName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                       color: Theme.of(context)
                           .colorScheme
                           .onSurface
                           .withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  ElevatedButton(
                    onPressed: () => _showSubscriptionScreen(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IslamicColors.roseGold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Débloquer',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSubscriptionScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SubscriptionScreen(),
      ),
    );
  }
}