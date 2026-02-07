import Flutter
import UIKit
import PushKit
import CallKit

public class FlutterVoipKitPlugin: NSObject, FlutterPlugin, PKPushRegistryDelegate, CXProviderDelegate {
  
  static var channel: FlutterMethodChannel?
  private static var provider: CXProvider?
  private static var instance: FlutterVoipKitPlugin?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    channel = FlutterMethodChannel(name: "flutter_voip_kit", binaryMessenger: registrar.messenger())
    let instance = FlutterVoipKitPlugin()
    self.instance = instance
    
    if FlutterVoipKitPlugin.provider == nil {
        let config = CXProviderConfiguration(localizedName: "VoIP App")
        config.supportsVideo = true
        config.maximumCallGroups = 1
        config.maximumCallsPerCallGroup = 1
        
        let provider = CXProvider(configuration: config)
        // 重要: Delegateをセットしないと CallKit は動作しません
        provider.setDelegate(instance, queue: nil)
        FlutterVoipKitPlugin.provider = provider
    }
    
    registrar.addMethodCallDelegate(instance, channel: channel!)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
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
  
  // MARK: - CXProviderDelegate (必須)
  
  public func providerDidReset(_ provider: CXProvider) {
      print("[FlutterVoipKitPlugin] Provider did reset")
  }
  
  public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
      print("[FlutterVoipKitPlugin] Answer Call Action")
      action.fulfill()
  }
  
  public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
      print("[FlutterVoipKitPlugin] End Call Action")
      action.fulfill()
  }
  
  // MARK: - PKPushRegistryDelegate
  
  public func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
      let token = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
      print("[FlutterVoipKitPlugin] VoIP Token: \(token)")
      FlutterVoipKitPlugin.channel?.invokeMethod("onVoipToken", arguments: token)
  }
  
  public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completionHandler completion: @escaping () -> Void) {
      let data = payload.dictionaryPayload
      print("[FlutterVoipKitPlugin] Incoming VoIP Push: \(data)")
      
      let uuidString = data["uuid"] as? String ?? UUID().uuidString
      guard let uuid = UUID(uuidString: uuidString) else {
          completion()
          return
      }
      let callerName = data["callerName"] as? String ?? "Unknown"
      
      let update = CXCallUpdate()
      update.remoteHandle = CXHandle(type: .generic, value: callerName)
      update.hasVideo = true
      
      // CallKitに報告
      FlutterVoipKitPlugin.provider?.reportNewIncomingCall(with: uuid, update: update) { error in
          if let error = error {
              print("[FlutterVoipKitPlugin] Error reporting call: \(error.localizedDescription)")
          }
          completion()
      }
      
      FlutterVoipKitPlugin.channel?.invokeMethod("onIncomingPush", arguments: data)
  }
}