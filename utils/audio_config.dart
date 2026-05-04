import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioConfig {
  static bool _configured = false;

  static Future<void> ensureInitialized() async {
    if (_configured) return;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.allowBluetooth,
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
      _configured = true;
    } catch (e) {
      debugPrint('[AudioConfig] Error: $e');
    }
  }
}
