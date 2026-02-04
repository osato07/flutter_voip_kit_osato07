import Flutter
import UIKit
import PushKit

public class FlutterVoipKitPlugin: NSObject, FlutterPlugin, PKPushRegistryDelegate {
  
  static var channel: FlutterMethodChannel?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    channel = FlutterMethodChannel(name: "flutter_voip_kit", binaryMessenger: registrar.messenger())
    let instance = FlutterVoipKitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel!)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      // Register for VoIP notifications
      let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
      voipRegistry.delegate = self
      voipRegistry.desiredPushTypes = [.voIP]
      result(true)
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - PKPushRegistryDelegate
  
  public func pushRegistry(_ registry: PKPushRegistry, didUpdatePushCredentials credentials: PKPushCredentials, for type: PKPushType) {
      let token = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
      print("[FlutterVoipKitPlugin] VoIP Token: \(token)")
      FlutterVoipKitPlugin.channel?.invokeMethod("onVoipToken", arguments: token)
  }
  
  public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
      print("[FlutterVoipKitPlugin] Incoming VoIP Push: \(payload.dictionaryPayload)")
      FlutterVoipKitPlugin.channel?.invokeMethod("onIncomingPush", arguments: payload.dictionaryPayload)
      completion()
  }
}
