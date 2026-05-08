import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/models/user.dart';

class AppState extends ChangeNotifier {
  User _user = User(
    id: 'default',
    name: '',
    totalHassanat: 0,
    currentLevel: 0,
    streak: 0,
    lastActivityDate: DateTime.now(),
    isPremium: false,
  );

  User get user => _user;
  StreamSubscription<void>? _userChangedSub;

  Future<void> initializeUser() async {
    _user = await StorageService.getUser();
    // Listen to global user update events and keep state in sync
    _userChangedSub ??= StorageService.userChanged.listen((_) async {
      _user = await StorageService.getUser();
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> refreshUser() async {
    _user = await StorageService.getUser();
    notifyListeners();
  }

  static Future<bool> shouldShowOnboarding() async {
    return await StorageService.isFirstTime();
  }
  
  static Future<void> markOnboardingComplete() async {
    await StorageService.setFirstTimeCompleted();
  }

  @override
  void dispose() {
    _userChangedSub?.cancel();
    super.dispose();
  }
}