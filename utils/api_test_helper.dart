import 'dart:convert';
import 'package:sajda/services/quran_api_service.dart';

/// Utilitaire pour tester l'intégration de l'API Quran
class ApiTestHelper {
  
  /// Test complet de l'API QuranAPI.pages.dev
  static Future<Map<String, dynamic>> runCompleteApiTest() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <String, dynamic>{},
      'summary': <String, dynamic>{},
    };

    print('🚀 Démarrage des tests d\'API Quran...\n');
    
    // Test 1: Connectivité de base
    print('1️⃣ Test de connectivité...');
    final isConnected = await QuranApiService.testNewApiConnectivity();
    results['tests']['connectivity'] = {
      'passed': isConnected,
      'message': isConnected 
        ? 'Nouvelle API accessible' 
        : 'Nouvelle API non accessible, utilisation du fallback'
    };
    print(isConnected ? '✅ Nouvelle API accessible' : '⚠️ Fallback vers ancienne API');

    // Test 2: Liste des chapitres
    print('\n2️⃣ Test de récupération des chapitres...');
    try {
      final chapters = await QuranApiService.getChaptersFromNewApi();
      results['tests']['chapters'] = {
        'passed': chapters.isNotEmpty,
        'count': chapters.length,
        'sample': chapters.take(3).toList(),
        'message': chapters.isNotEmpty 
          ? '${chapters.length} chapitres récupérés'
          : 'Aucun chapitre récupéré'
      };
      print(chapters.isNotEmpty 
        ? '✅ ${chapters.length} chapitres récupérés'
        : '❌ Aucun chapitre récupéré');
    } catch (e) {
      results['tests']['chapters'] = {
        'passed': false,
        'error': e.toString(),
        'message': 'Erreur lors de la récupération des chapitres'
      };
      print('❌ Erreur: $e');
    }

    // Test 3: Récupération de sourate avec versets
    print('\n3️⃣ Test de récupération d\'une sourate...');
    try {
      final surahData = await QuranApiService.getChapterWithVerses(1); // Al-Fatiha
      final hasVerses = surahData != null && 
                       (surahData['verses'] != null || surahData['ayahs'] != null);
      results['tests']['chapter_verses'] = {
        'passed': hasVerses,
        'chapter': 1,
        'data_structure': surahData?.keys.toList() ?? [],
        'message': hasVerses 
          ? 'Sourate Al-Fatiha récupérée avec versets'
          : 'Échec de récupération des versets'
      };
      print(hasVerses 
        ? '✅ Sourate Al-Fatiha récupérée avec versets'
        : '❌ Échec de récupération des versets');
    } catch (e) {
      results['tests']['chapter_verses'] = {
        'passed': false,
        'error': e.toString(),
        'message': 'Erreur lors de la récupération de la sourate'
      };
      print('❌ Erreur: $e');
    }

    // Test 4: Traductions
    print('\n4️⃣ Test de récupération des traductions...');
    try {
      final translations = await QuranApiService.getTranslations();
      results['tests']['translations'] = {
        'passed': translations.isNotEmpty,
        'count': translations.length,
        'sample': translations.take(2).toList(),
        'message': translations.isNotEmpty 
          ? '${translations.length} traductions disponibles'
          : 'Aucune traduction récupérée'
      };
      print(translations.isNotEmpty 
        ? '✅ ${translations.length} traductions disponibles'
        : '❌ Aucune traduction récupérée');
    } catch (e) {
      results['tests']['translations'] = {
        'passed': false,
        'error': e.toString(),
        'message': 'Erreur lors de la récupération des traductions'
      };
      print('❌ Erreur: $e');
    }

    // Test 5: Récitateurs
    print('\n5️⃣ Test de récupération des récitateurs...');
    try {
      final reciters = await QuranApiService.getReciters();
      results['tests']['reciters'] = {
        'passed': reciters.isNotEmpty,
        'count': reciters.length,
        'sample': reciters.take(2).toList(),
        'message': reciters.isNotEmpty 
          ? '${reciters.length} récitateurs disponibles'
          : 'Aucun récitateur récupéré'
      };
      print(reciters.isNotEmpty 
        ? '✅ ${reciters.length} récitateurs disponibles'
        : '❌ Aucun récitateur récupéré');
    } catch (e) {
      results['tests']['reciters'] = {
        'passed': false,
        'error': e.toString(),
        'message': 'Erreur lors de la récupération des récitateurs'
      };
      print('❌ Erreur: $e');
    }

    // Test 6: Méthode hybride
    print('\n6️⃣ Test de la méthode hybride...');
    try {
      final hybridResult = await QuranApiService.getSurahHybrid(1);
      final hasData = hybridResult['data'] != null;
      results['tests']['hybrid_method'] = {
        'passed': hasData,
        'source': hybridResult['source'],
        'message': hasData 
          ? 'Méthode hybride fonctionnelle (source: ${hybridResult['source']})'
          : 'Échec de la méthode hybride'
      };
      print(hasData 
        ? '✅ Méthode hybride fonctionnelle (source: ${hybridResult['source']})'
        : '❌ Échec de la méthode hybride');
    } catch (e) {
      results['tests']['hybrid_method'] = {
        'passed': false,
        'error': e.toString(),
        'message': 'Erreur avec la méthode hybride'
      };
      print('❌ Erreur: $e');
    }

    // Test 7: Recherche
    print('\n7️⃣ Test de recherche...');
    try {
      final searchResult = await QuranApiService.searchQuran('Allah');
      final hasResults = searchResult != null && searchResult.isNotEmpty;
      results['tests']['search'] = {
        'passed': hasResults,
        'query': 'Allah',
        'message': hasResults 
          ? 'Recherche fonctionnelle'
          : 'Fonction de recherche non disponible'
      };
      print(hasResults 
        ? '✅ Recherche fonctionnelle'
        : '⚠️ Fonction de recherche non disponible');
    } catch (e) {
      results['tests']['search'] = {
        'passed': false,
        'error': e.toString(),
        'message': 'Erreur lors de la recherche'
      };
      print('❌ Erreur: $e');
    }

    // Calcul du résumé
    final tests = results['tests'] as Map<String, dynamic>;
    final totalTests = tests.length;
    final passedTests = tests.values.where((test) => test['passed'] == true).length;
    final failedTests = totalTests - passedTests;
    
    results['summary'] = {
      'total_tests': totalTests,
      'passed': passedTests,
      'failed': failedTests,
      'success_rate': (passedTests / totalTests * 100).toStringAsFixed(1) + '%',
      'overall_status': passedTests >= (totalTests * 0.6) ? 'SUCCESS' : 'PARTIAL'
    };

    print('\n📊 RÉSUMÉ DES TESTS:');
    print('Total: $totalTests');
    print('Réussis: $passedTests');
    print('Échoués: $failedTests');
    print('Taux de réussite: ${results['summary']['success_rate']}');
    print('Statut global: ${results['summary']['overall_status']}');

    return results;
  }

  /// Test rapide pour vérifier si l'API fonctionne
  static Future<bool> quickHealthCheck() async {
    try {
      final isConnected = await QuranApiService.testNewApiConnectivity();
      if (isConnected) {
        final chapters = await QuranApiService.getChaptersFromNewApi();
        return chapters.isNotEmpty;
      } else {
        // Test de l'API de fallback
        final surahs = await QuranApiService.getSurahsList();
        return surahs.isNotEmpty;
      }
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  /// Affiche des informations détaillées sur l'état de l'API
  static Future<void> printApiStatus() async {
    print('🔍 Vérification du statut de l\'API Quran...\n');
    
    final newApiWorking = await QuranApiService.testNewApiConnectivity();
    print('Nouvelle API (quranapi.pages.dev): ${newApiWorking ? '🟢 En ligne' : '🔴 Hors ligne'}');
    
    final fallbackWorking = await QuranApiService.isApiAvailable();
    print('API de fallback (alquran.cloud): ${fallbackWorking ? '🟢 En ligne' : '🔴 Hors ligne'}');
    
    if (!newApiWorking && !fallbackWorking) {
      print('⚠️ Toutes les APIs sont hors ligne, utilisation des données statiques');
    } else if (!newApiWorking && fallbackWorking) {
      print('📡 Utilisation de l\'API de fallback');
    } else if (newApiWorking) {
      print('🚀 Utilisation de la nouvelle API optimisée');
    }
    
    print('');
  }

  /// Génère un rapport JSON des tests
  static Future<String> generateJsonReport() async {
    final results = await runCompleteApiTest();
    return jsonEncode(results);
  }
}