import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; 
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// A modern video section that prefers a local asset or network MP4,
/// and gracefully falls back to a YouTube embed.
class InvocationVideoSection extends StatefulWidget {
  final String title;
  final Color accentColor;
  final String youtubeVideoId;
  final String youtubeUrl;
  final String? assetVideoPath; // e.g. assets/videos/morning_dhikr.mp4
  final String? networkVideoUrl; // direct MP4 URL if available

  const InvocationVideoSection({
    super.key,
    required this.title,
    required this.accentColor,
    required this.youtubeVideoId,
    required this.youtubeUrl,
    this.assetVideoPath,
    this.networkVideoUrl,
  });

  @override
  State<InvocationVideoSection> createState() => _InvocationVideoSectionState();
}

class _InvocationVideoSectionState extends State<InvocationVideoSection> {
  VideoPlayerController? _videoController;
  YoutubePlayerController? _ytController;
  bool _useYouTube = false;
  bool _initializing = true;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  Future<void> _initControllers() async {
    setState(() {
      _initializing = true;
    });

    // 1) Try asset video if provided and declared in pubspec
    if (widget.assetVideoPath != null) {
      try {
        // Will throw if asset not found or not listed in pubspec
        await rootBundle.load(widget.assetVideoPath!);
        final c = VideoPlayerController.asset(widget.assetVideoPath!);
        await c.initialize();
        await c.setLooping(true);
        setState(() {
          _videoController = c;
          _useYouTube = false;
          _initializing = false;
        });
        return;
      } catch (_) {
        // ignore and fallback
      }
    }

    // 2) Try network MP4 if provided
    if (widget.networkVideoUrl != null && widget.networkVideoUrl!.isNotEmpty) {
      try {
        final c = VideoPlayerController.networkUrl(Uri.parse(widget.networkVideoUrl!));
        await c.initialize();
        await c.setLooping(true);
        setState(() {
          _videoController = c;
          _useYouTube = false;
          _initializing = false;
        });
        return;
      } catch (_) {
        // ignore and fallback
      }
    }

    // 3) Fallback to YouTube
    _ytController = YoutubePlayerController.fromVideoId(
      videoId: widget.youtubeVideoId,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        strictRelatedVideos: true,
        enableCaption: true,
        playsInline: true,
      ),
    );
    setState(() {
      _useYouTube = true;
      _initializing = false;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _ytController?.close();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final c = _videoController;
    if (c == null) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
    setState(() {});
  }

  Future<void> _toggleMute() async {
    final c = _videoController;
    if (c == null) return;
    _muted = !_muted;
    await c.setVolume(_muted ? 0.0 : 1.0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.accentColor.withValues(alpha: 0.10),
            widget.accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.accentColor.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle_fill, color: widget.accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: widget.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                tooltip: 'Ouvrir sur YouTube',
                onPressed: () {
                  launchUrl(Uri.parse(widget.youtubeUrl), mode: LaunchMode.externalApplication);
                },
                icon: Icon(Icons.open_in_new, color: widget.accentColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: _videoController?.value.aspectRatio ?? 16 / 9,
              child: _initializing
                  ? Container(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(color: widget.accentColor),
                      ),
                    )
                  : _useYouTube
                      ? Container(
                          color: Colors.black,
                          child: YoutubePlayer(
                            controller: _ytController!,
                            aspectRatio: 16 / 9,
                          ),
                        )
                      : _buildVideoPlayer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final c = _videoController!;
    return Stack(
      alignment: Alignment.center,
      children: [
        ColoredBox(
          color: Colors.black,
          child: VideoPlayer(c),
        ),
        // Center play/pause button
        AnimatedOpacity(
          opacity: c.value.isPlaying ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _togglePlay,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(14),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 48),
              ),
            ),
          ),
        ),
        // Bottom controls
        Positioned(
          left: 8,
          right: 8,
          bottom: 4,
          child: Column(
            children: [
              VideoProgressIndicator(
                c,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: widget.accentColor,
                  bufferedColor: widget.accentColor.withValues(alpha: 0.3),
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    onPressed: _togglePlay,
                    icon: Icon(
                      c.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleMute,
                    icon: Icon(_muted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Ouvrir sur YouTube',
                    onPressed: () {
                      launchUrl(Uri.parse(widget.youtubeUrl), mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }
}
