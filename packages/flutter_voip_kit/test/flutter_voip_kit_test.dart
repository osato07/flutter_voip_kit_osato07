import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voip_kit/flutter_voip_kit.dart';
import 'package:flutter_voip_kit/flutter_voip_kit_platform_interface.dart';
import 'package:flutter_voip_kit/flutter_voip_kit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterVoipKitPlatform
    with MockPlatformInterfaceMixin
    implements FlutterVoipKitPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterVoipKitPlatform initialPlatform = FlutterVoipKitPlatform.instance;

  test('$MethodChannelFlutterVoipKit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterVoipKit>());
  });

  test('getPlatformVersion', () async {
    FlutterVoipKit flutterVoipKitPlugin = FlutterVoipKit();
    MockFlutterVoipKitPlatform fakePlatform = MockFlutterVoipKitPlatform();
    FlutterVoipKitPlatform.instance = fakePlatform;

    expect(await flutterVoipKitPlugin.getPlatformVersion(), '42');
  });
}
