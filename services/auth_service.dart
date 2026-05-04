import 'dart:async';

import 'storage_service.dart';

/// Version allégée d'`AuthService` pour la build Android hors-ligne (sans Firebase).
class AuthService {
  AuthService._();

  /// Aucun utilisateur connecté dans cette version hors-ligne.
  static Stream<void> get authStateChanges => const Stream.empty();
  static Object? get currentUser => null;

  static Future<T> _unsupported<T>(String operation) async {
    throw AuthException(
      'auth-disabled',
      'L\'opération "$operation" n\'est pas disponible dans cette version hors-ligne de Sajda.',
    );
  }

  static Future<dynamic> signInWithGoogle() => _unsupported('connexion Google');

  static Future<dynamic> signInWithEmail(String email, String password) =>
      _unsupported('connexion par email');

  static Future<dynamic> signUpWithEmail(String email, String password) =>
      _unsupported('inscription par email');

  static Future<void> sendPasswordResetEmail(String email) =>
      _unsupported('réinitialisation du mot de passe');

  /// Déconnexion locale : on efface simplement les données utilisateur locales.
  static Future<void> signOut() async {
    await StorageService.clearLocalUser();
  }
}

class AuthException implements Exception {
  final String code;
  final String message;
  AuthException(this.code, this.message);
  @override
  String toString() => 'AuthException($code): $message';
}
