import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sajda/services/subscription_service.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/screens/subscription_screen.dart';
import 'package:sajda/theme.dart';

/// Global gate that blocks the app when trial is over and there is no active subscription.
/// It shows a non-dismissible modern bottom sheet leading to the SubscriptionScreen.
class PaywallGate extends StatefulWidget {
  final Widget child;
  const PaywallGate({super.key, required this.child});

  @override
  State<PaywallGate> createState() => _PaywallGateState();
}

class _PaywallGateState extends State<PaywallGate> with WidgetsBindingObserver {
  bool _paywallVisible = false;
  bool _shouldGate = false;
  StreamSubscription<void>? _userChangedSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bindUserStream();
    // Initial check
    // ignore: discarded_futures
    _evaluateEntitlement();
  }

  void _bindUserStream() {
    // Listen to user/premium changes to update gate in real-time
    _userChangedSub = StorageService.userChanged.listen((_) {
      // ignore: discarded_futures
      _evaluateEntitlement();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check on resume (trial may have ended while app in background)
      // ignore: discarded_futures
      _evaluateEntitlement();
    }
  }

  Future<void> _evaluateEntitlement() async {
    try {
      final isPremium = await SubscriptionService.isPremium();
      final trialActive = await SubscriptionService.isTrialActive();
      final trialUsed = await SubscriptionService.isTrialUsed();
      final shouldGate = (!isPremium && !trialActive && trialUsed);
      if (!mounted) return;
      if (shouldGate != _shouldGate) {
        setState(() => _shouldGate = shouldGate);
      }
      if (shouldGate && !_paywallVisible) {
        _showPaywall();
      } else if (!shouldGate && _paywallVisible) {
        _dismissPaywall();
      }
    } catch (_) {
      // Silent
    }
  }

  Future<void> _showPaywall() async {
    if (!mounted) return;
    // Ensure a Navigator is available. If not yet, delay until next frame.
    final nav = Navigator.maybeOf(context, rootNavigator: true);
    if (nav == null) {
      // Try again after the current frame to avoid calling before MaterialApp builds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _shouldGate && !_paywallVisible) {
          // ignore: discarded_futures
          _showPaywall();
        }
      });
      return;
    }

    if (_paywallVisible) return;
    _paywallVisible = true;

    // Use root navigator to ensure overlay on top of whole app
    // ignore: use_build_context_synchronously
    try {
      await showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        backgroundColor: Theme.of(context).colorScheme.surface,
        isDismissible: false,
        enableDrag: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => const _PaywallSheet(),
      );
    } catch (_) {
      // If bottom sheet failed to show (e.g., during route transition), allow UI to remain interactive
    }
    // When closed (after upgrade), mark as not visible
    _paywallVisible = false;
    // Re-check entitlement after dismissal
    // ignore: discarded_futures
    _evaluateEntitlement();
  }

  void _dismissPaywall() {
    if (!_paywallVisible) return;
    final nav = Navigator.maybeOf(context, rootNavigator: true);
    if (nav != null && nav.canPop()) {
      nav.pop();
    }
    _paywallVisible = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userChangedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Optionally dim the app under the sheet (visual cue)
    // Do NOT block interactions while waiting for the sheet; only the sheet blocks when visible.
    return widget.child;
  }
}

class _PaywallSheet extends StatefulWidget {
  const _PaywallSheet();

  @override
  State<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<_PaywallSheet> {
  bool _isRestoring = false;

  Future<void> _openSubscriptions() async {
    // Push the existing SubscriptionScreen (same as Profile > Sajda Premium)
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SubscriptionScreen(), fullscreenDialog: true),
    );
    // After returning, re-check entitlement by closing the sheet if premium now
    final entitled = await SubscriptionService.isPremium();
    if (entitled && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _restore() async {
    setState(() => _isRestoring = true);
    try {
      await SubscriptionService.restorePurchases();
      await Future.delayed(const Duration(milliseconds: 800));
      final entitled = await SubscriptionService.verifySubscriptionStatus();
      if (entitled && mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      // No-op; user can retry
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.lock, color: IslamicColors.roseGold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Essai gratuit terminé',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Votre essai gratuit de 7 jours est terminé. Abonnez-vous pour continuer à profiter de toutes les fonctionnalités.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: IslamicColors.emeraldGreen.withValues(alpha: 0.2)),
                color: IslamicColors.emeraldGreen.withValues(alpha: 0.06),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.diamond, color: IslamicColors.emeraldGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sajda Premium', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          'Lecture audio du Coran, rappels intelligents, stats avancées, cours de salat et plus encore.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _openSubscriptions,
                icon: const Icon(Icons.shopping_bag, color: Colors.white),
                label: Text(
                  'Voir les abonnements',
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: IslamicColors.roseGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isRestoring ? null : _restore,
                icon: _isRestoring
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore),
                label: Text(
                  _isRestoring ? 'Restauration…' : 'J\'ai déjà un abonnement',
                  style: theme.textTheme.bodyMedium,
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Paramètres > Profil > Sajda Premium',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
