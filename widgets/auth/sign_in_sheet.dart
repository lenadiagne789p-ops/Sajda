import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajda/services/auth_service.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/utils/app_state.dart';

class SignInSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _SignInSheetBody(),
    );
  }
}

class _SignInSheetBody extends StatefulWidget {
  const _SignInSheetBody();

  @override
  State<_SignInSheetBody> createState() => _SignInSheetBodyState();
}

class _SignInSheetBodyState extends State<_SignInSheetBody> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _withLoading(Future<void> Function() op) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await op();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(bottom: bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Se connecter',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: IslamicColors.emeraldGreen,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accédez à votre progression, synchronisez vos données et profitez du cloud ☁️',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _withLoading(() async {
                            await AuthService.signInWithGoogle();
                            if (mounted) {
                              // Also refresh AppState user from storage
                              await context.read<AppState>().refreshUser();
                              Navigator.of(context).pop();
                            }
                          }),
                  icon: const Icon(Icons.login, color: IslamicColors.emeraldGreen),
                  label: const Text('Continuer avec Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: IslamicColors.emeraldGreen,
                    side: const BorderSide(color: IslamicColors.emeraldGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('ou', style: Theme.of(context).textTheme.labelSmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email, color: IslamicColors.emeraldGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock, color: IslamicColors.emeraldGreen),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: IslamicColors.roseGold),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading
                          ? null
                          : () => _withLoading(() async {
                                await AuthService.signInWithEmail(_emailController.text, _passwordController.text);
                                if (mounted) {
                                  await context.read<AppState>().refreshUser();
                                  Navigator.of(context).pop();
                                }
                              }),
                      style: FilledButton.styleFrom(
                        backgroundColor: IslamicColors.emeraldGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Se connecter', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _withLoading(() async {
                                await AuthService.signUpWithEmail(_emailController.text, _passwordController.text);
                                if (mounted) {
                                  await context.read<AppState>().refreshUser();
                                  Navigator.of(context).pop();
                                }
                              }),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: IslamicColors.emeraldGreen,
                        side: const BorderSide(color: IslamicColors.emeraldGreen),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Créer un compte'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _withLoading(() async {
                            if (_emailController.text.trim().isEmpty) {
                              setState(() => _error = 'Entrez votre email pour réinitialiser');
                              return;
                            }
                            await AuthService.sendPasswordResetEmail(_emailController.text);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Email de réinitialisation envoyé')),
                              );
                            }
                          }),
                  icon: const Icon(Icons.key, color: IslamicColors.mysticBlue),
                  label: const Text('Mot de passe oublié?'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 8),
              if (_isLoading)
                const LinearProgressIndicator(minHeight: 2),
            ],
          ),
        ),
      ),
    );
  }
}
