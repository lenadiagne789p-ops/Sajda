import 'package:flutter/material.dart';
import 'package:sajda/models/islamic_action.dart';
import 'package:sajda/theme.dart';
import 'package:audioplayers/audioplayers.dart';

class ActionDetailPage extends StatefulWidget {
  final IslamicAction action;
  final Function(String) onActionCompleted;

  const ActionDetailPage({
    super.key,
    required this.action,
    required this.onActionCompleted,
  });

  @override
  State<ActionDetailPage> createState() => _ActionDetailPageState();
}

class _ActionDetailPageState extends State<ActionDetailPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isPlaying = false;
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
    
    // Initialize audio player if an audio URL is available
    if (widget.action.audioUrl != null && widget.action.audioUrl!.isNotEmpty) {
      final player = AudioPlayer();
      _audioPlayer = player;
      player.setReleaseMode(ReleaseMode.stop);
      player.onPlayerStateChanged.listen((state) {
        if (!mounted) return;
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      });
      player.onPlayerComplete.listen((_) {
        if (!mounted) return;
        setState(() => _isPlaying = false);
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (_audioPlayer == null || widget.action.audioUrl == null || widget.action.audioUrl!.isEmpty) {
      return;
    }

    try {
      final shouldStartPlayback = !_isPlaying;

      if (_isPlaying) {
        await _audioPlayer!.stop();
      } else {
        final source = _resolveAudioSource(widget.action.audioUrl!);
        if (source != null) {
          await _audioPlayer!.stop();
          await _audioPlayer!.play(source);
        } else {
          throw Exception('Source audio invalide');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shouldStartPlayback ? 'Audio en cours...' : 'Audio arrêté'),
          backgroundColor: IslamicColors.emeraldGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isPlaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur audio: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Source? _resolveAudioSource(String path) {
    if (path.startsWith('http')) {
      return UrlSource(path);
    }

    final normalized = path.startsWith('assets/') ? path.replaceFirst('assets/', '') : path;
    if (normalized.isEmpty) {
      return null;
    }
    return AssetSource(normalized);
  }

  Color _getActionColor() {
    switch (widget.action.type) {
      case ActionType.prayer:
        return IslamicColors.emeraldGreen;
      case ActionType.dhikr:
        return IslamicColors.roseGold;
      case ActionType.quranReading:
        return IslamicColors.mysticBlue;
      case ActionType.charity:
        return IslamicColors.dustyRose;
      case ActionType.goodDeed:
        return IslamicColors.softViolet;
      case ActionType.hadith:
        return const Color(0xFF8D6E63);
      case ActionType.sunnah:
        return const Color(0xFF66BB6A);
      case ActionType.socialService:
        return const Color(0xFF26C6DA);
      case ActionType.family:
        return const Color(0xFFBA68C8);
      case ActionType.worship:
        return const Color(0xFFFFB74D);
      case ActionType.names99:
        return IslamicColors.emeraldGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionColor = _getActionColor();
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              actionColor.withValues(alpha: 0.1),
              IslamicColors.pearlWhite,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(actionColor),
                SliverPadding(
                  padding: const EdgeInsets.all(20.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildMainCard(actionColor),
                      const SizedBox(height: 20),
                      if (widget.action.detailedDescription != null)
                        _buildDetailedDescription(actionColor),
                      if (widget.action.hadiths != null && widget.action.hadiths!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildHadithSection(actionColor),
                      ],
                      if (widget.action.islamicTeaching != null) ...[
                        const SizedBox(height: 20),
                        _buildTeachingSection(actionColor),
                      ],
                      if (widget.action.audioUrl != null) ...[
                        const SizedBox(height: 20),
                        _buildAudioSection(actionColor),
                      ],
                      const SizedBox(height: 20),
                      _buildActionButton(actionColor),
                      const SizedBox(height: 20),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Color actionColor) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: actionColor.withValues(alpha: 0.1),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: actionColor),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Détails de l\'Action',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: actionColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildMainCard(Color actionColor) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: actionColor.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                widget.action.isCompleted ? Icons.check_circle : widget.action.icon,
                color: actionColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.action.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: actionColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.action.arabicTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: IslamicColors.roseGold,
                fontWeight: FontWeight.w600,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars, color: actionColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.action.hassanatReward} Hassanat',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: actionColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.action.isCompleted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Action Terminée',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedDescription(Color actionColor) {
    return _buildSection(
      'Description Détaillée',
      Icons.info_outline,
      actionColor,
      Text(
        widget.action.detailedDescription!,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.6,
          color: Colors.grey[700],
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildHadithSection(Color actionColor) {
    return _buildSection(
      'Hadiths Authentiques',
      Icons.menu_book,
      actionColor,
      Column(
        children: widget.action.hadiths!.asMap().entries.map((entry) {
          final index = entry.key;
          final hadith = entry.value;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: actionColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: actionColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Hadith ${index + 1}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: actionColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  hadith,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTeachingSection(Color actionColor) {
    return _buildSection(
      'Enseignement Islamique',
      Icons.school,
      actionColor,
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              actionColor.withValues(alpha: 0.05),
              actionColor.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: actionColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          widget.action.islamicTeaching!,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.6,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  Widget _buildAudioSection(Color actionColor) {
    return _buildSection(
      'Audio Récitation',
      Icons.volume_up,
      actionColor,
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: actionColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: actionColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _toggleAudio,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: actionColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Écouter la récitation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: actionColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isPlaying ? 'En cours de lecture...' : 'Cliquer pour écouter',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Color actionColor, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: actionColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: actionColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Color actionColor) {
    if (widget.action.isCompleted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.grey),
            const SizedBox(width: 12),
            Text(
              'Action Déjà Terminée',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        widget.onActionCompleted(widget.action.id);
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [actionColor, actionColor.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: actionColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              'Marquer comme Terminé',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}