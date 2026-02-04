import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_voip_kit_method_channel.dart';

abstract class FlutterVoipKitPlatform extends PlatformInterface {
  /// Constructs a FlutterVoipKitPlatform.
  FlutterVoipKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterVoipKitPlatform _instance = MethodChannelFlutterVoipKit();

  /// The default instance of [FlutterVoipKitPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterVoipKit].
  static FlutterVoipKitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterVoipKitPlatform] when
  /// they register themselves.
  static set instance(FlutterVoipKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
