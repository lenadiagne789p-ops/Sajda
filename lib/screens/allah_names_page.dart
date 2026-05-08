import 'package:flutter/material.dart';
import 'package:sajda/models/allah_name.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/widgets/ui/gradient_app_bar.dart';

class AllahNamesPage extends StatefulWidget {
  const AllahNamesPage({super.key});

  @override
  State<AllahNamesPage> createState() => _AllahNamesPageState();
}

class _AllahNamesPageState extends State<AllahNamesPage> {
  final List<AllahName> names = AllahName.getAllNames();
  final TextEditingController _searchController = TextEditingController();
  List<AllahName> filteredNames = [];

  @override
  void initState() {
    super.initState();
    filteredNames = names;
  }

  void _filterNames(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredNames = names;
      } else {
        filteredNames = names.where((name) {
          return name.french.toLowerCase().contains(query.toLowerCase()) ||
                 name.transliteration.toLowerCase().contains(query.toLowerCase()) ||
                 name.arabic.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IslamicColors.pearlWhite,
      appBar: const GradientAppBar(title: 'Les 99 Noms d\'Allah', showBack: true),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterNames,
                decoration: InputDecoration(
                  hintText: 'Rechercher un nom...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: IslamicColors.roseGold,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          
          // Liste des noms
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredNames.length,
              itemBuilder: (context, index) {
                final name = filteredNames[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        _showNameDetail(context, name);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Numéro
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                   colors: [IslamicColors.emeraldGreen, IslamicColors.emeraldGreen.withValues(alpha: 0.8)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${name.number}',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Contenu
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nom arabe
                                  Text(
                                    name.arabic,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: IslamicColors.emeraldGreen,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  
                                  // Translittération
                                  Text(
                                    name.transliteration,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: IslamicColors.roseGold,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  
                                  // Traduction française
                                  Text(
                                    name.french,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Icône
                            Icon(
                              Icons.arrow_forward_ios,
                              color: IslamicColors.roseGold,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showNameDetail(BuildContext context, AllahName name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // En-tête avec bouton de fermeture
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 32),
                      // Handle
                      Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Bouton fermer
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                     colors: [IslamicColors.emeraldGreen, IslamicColors.emeraldGreen.withValues(alpha: 0.8)],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${name.number}',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              Text(
                                name.arabic,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: IslamicColors.emeraldGreen,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              Text(
                                name.transliteration,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: IslamicColors.roseGold,
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              Text(
                                name.french,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.black87,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Signification
                        _buildSection(
                          '📖 Signification',
                          name.meaning,
                        ),
                        
                        // Description
                        _buildSection(
                          '💡 Description',
                          name.description,
                        ),
                        
                        // Réflexion
                        _buildSection(
                          '🤲 Réflexion',
                          name.reflection,
                        ),
                        
                        // Attributs
                        const SizedBox(height: 20),
                        Text(
                          '✨ Attributs divins',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: IslamicColors.emeraldGreen,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: name.attributes.map((attribute) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                   colors: [IslamicColors.roseGold, IslamicColors.roseGold.withValues(alpha: 0.8)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                attribute,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.black87,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}