import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_voip_kit_platform_interface.dart';

/// An implementation of [FlutterVoipKitPlatform] that uses method channels.
class MethodChannelFlutterVoipKit extends FlutterVoipKitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_voip_kit');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
