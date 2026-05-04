import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/utils/api_test_helper.dart';
import 'package:sajda/services/quran_api_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = false;
  Map<String, dynamic>? testResults;
  String? selectedTest;
  List<Map<String, dynamic>> chapters = [];
  List<Map<String, dynamic>> translations = [];
  List<Map<String, dynamic>> reciters = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _performQuickHealthCheck();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performQuickHealthCheck() async {
    await ApiTestHelper.printApiStatus();
  }

  Future<void> _runCompleteTest() async {
    setState(() {
      isLoading = true;
      testResults = null;
    });

    try {
      final results = await ApiTestHelper.runCompleteApiTest();
      setState(() {
        testResults = results;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                results['summary']['overall_status'] == 'SUCCESS' 
                  ? Icons.check_circle 
                  : Icons.warning,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text('Tests terminés: ${results['summary']['success_rate']}'),
            ],
          ),
          backgroundColor: results['summary']['overall_status'] == 'SUCCESS' 
            ? IslamicColors.emeraldGreen 
            : IslamicColors.roseGold,
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Erreur lors des tests: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadChapters() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await QuranApiService.getChaptersFromNewApi();
      setState(() {
        chapters = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadTranslations() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await QuranApiService.getTranslations();
      setState(() {
        translations = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadReciters() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await QuranApiService.getReciters();
      setState(() {
        reciters = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Test API Quran',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: IslamicColors.emeraldGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: IslamicColors.roseGold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Tests'),
            Tab(icon: Icon(Icons.menu_book), text: 'Données'),
            Tab(icon: Icon(Icons.settings), text: 'Debug'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTestTab(),
          _buildDataTab(),
          _buildDebugTab(),
        ],
      ),
    );
  }

  Widget _buildTestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bouton de test principal
          ElevatedButton.icon(
            onPressed: isLoading ? null : _runCompleteTest,
            icon: isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow, color: Colors.white),
            label: Text(
              isLoading ? 'Tests en cours...' : 'Lancer tous les tests',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: IslamicColors.emeraldGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Résultats des tests
          if (testResults != null) _buildTestResults(),
        ],
      ),
    );
  }

  Widget _buildTestResults() {
    final summary = testResults!['summary'] as Map<String, dynamic>;
    final tests = testResults!['tests'] as Map<String, dynamic>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Résumé
        Card(
          color: summary['overall_status'] == 'SUCCESS' 
            ? IslamicColors.emeraldGreen.withValues(alpha: 0.1)
            : IslamicColors.roseGold.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      summary['overall_status'] == 'SUCCESS' 
                        ? Icons.check_circle 
                        : Icons.warning,
                      color: summary['overall_status'] == 'SUCCESS' 
                        ? IslamicColors.emeraldGreen 
                        : IslamicColors.roseGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Résumé des tests',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatChip('Total', summary['total_tests'].toString()),
                    _buildStatChip('Réussis', summary['passed'].toString()),
                    _buildStatChip('Échoués', summary['failed'].toString()),
                    _buildStatChip('Taux', summary['success_rate']),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Détails des tests
        Text(
          'Détails des tests',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        ...tests.entries.map((entry) => _buildTestDetailCard(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Chip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      backgroundColor: IslamicColors.pearlWhite,
    );
  }

  Widget _buildTestDetailCard(String testName, Map<String, dynamic> testData) {
    final passed = testData['passed'] as bool;
    final message = testData['message'] as String;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          passed ? Icons.check_circle : Icons.error,
          color: passed ? IslamicColors.emeraldGreen : Colors.red,
        ),
        title: Text(
          testName.replaceAll('_', ' ').toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(message),
        trailing: testData.containsKey('count') 
          ? Chip(
              label: Text(testData['count'].toString()),
              backgroundColor: IslamicColors.pearlWhite,
            )
          : null,
        onTap: () => _showTestDetails(testName, testData),
      ),
    );
  }

  Widget _buildDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chapitres
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chapitres (${chapters.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _loadChapters,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text('Charger', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: IslamicColors.emeraldGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (chapters.isNotEmpty)
                    ...chapters.take(5).map((chapter) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: IslamicColors.emeraldGreen,
                        child: Text(
                          chapter['number']?.toString() ?? '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(chapter['name'] ?? 'N/A'),
                      subtitle: Text(chapter['english_name'] ?? chapter['englishName'] ?? 'N/A'),
                      dense: true,
                    )),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Traductions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Traductions (${translations.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _loadTranslations,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text('Charger', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: IslamicColors.emeraldGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (translations.isNotEmpty)
                    ...translations.take(3).map((translation) => ListTile(
                      leading: const Icon(Icons.translate),
                      title: Text(translation['name'] ?? 'N/A'),
                      subtitle: Text(translation['language'] ?? translation['language_name'] ?? 'N/A'),
                      dense: true,
                    )),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Récitateurs
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Récitateurs (${reciters.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _loadReciters,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text('Charger', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: IslamicColors.emeraldGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (reciters.isNotEmpty)
                    ...reciters.take(3).map((reciter) => ListTile(
                      leading: const Icon(Icons.record_voice_over),
                      title: Text(reciter['name'] ?? 'N/A'),
                      subtitle: Text(reciter['style'] ?? reciter['recitation_style'] ?? 'N/A'),
                      dense: true,
                    )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuration API',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Nouvelle API', 'https://quranapi.pages.dev/api'),
                  _buildInfoRow('API Fallback', 'http://api.alquran.cloud/v1'),
                  _buildInfoRow('Timeout', '10-15 secondes'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: () async {
              final report = await ApiTestHelper.generateJsonReport();
              Clipboard.setData(ClipboardData(text: report));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rapport JSON copié dans le presse-papiers'),
                ),
              );
            },
            icon: const Icon(Icons.copy, color: Colors.white),
            label: const Text('Copier rapport JSON', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: IslamicColors.emeraldGreen,
            ),
          ),
          
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: () async {
              await ApiTestHelper.printApiStatus();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Statut affiché dans la console'),
                ),
              );
            },
            icon: const Icon(Icons.info, color: Colors.white),
            label: const Text('Vérifier statut', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: IslamicColors.roseGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  void _showTestDetails(String testName, Map<String, dynamic> testData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(testName.replaceAll('_', ' ').toUpperCase()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...testData.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(entry.value.toString()),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}