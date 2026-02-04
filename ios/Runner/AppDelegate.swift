import Flutter
import UIKit
import PushKit

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register for VoIP notifications
    let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
    voipRegistry.delegate = self
    voipRegistry.desiredPushTypes = [.voIP]
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
  // MARK: - PKPushRegistryDelegate
    
  func pushRegistry(_ registry: PKPushRegistry, didUpdatePushCredentials credentials: PKPushCredentials, for type: PKPushType) {
      let token = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
      print("VoIP Token: \(token)")
      
      // Communicate to Flutter
      // Note: In a real app, you might want to store this in UserDefaults or send via a reliable MethodChannel setup
      let controller = window?.rootViewController as? FlutterViewController
      if let binaryMessenger = controller?.binaryMessenger {
          let channel = FlutterMethodChannel(name: "com.example.voip/token", binaryMessenger: binaryMessenger)
          channel.invokeMethod("onVoipToken", arguments: token)
      }
  }
    
  func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
      print("Incoming VoIP Push: \(payload.dictionaryPayload)")
      
      // CRITICAL: Report to CallKit IMMEDIATELY here.
      // If using flutter_callkit_incoming, you should try to invoke its native method if exposed,
      // or implement CXProvider reportNewIncomingCall here manually using the uuid from payload.
      
      // Example of passing to Flutter (This may fail if app is killed and engine not ready):
      let controller = window?.rootViewController as? FlutterViewController
      if let binaryMessenger = controller?.binaryMessenger {
          let channel = FlutterMethodChannel(name: "com.example.voip/token", binaryMessenger: binaryMessenger)
          channel.invokeMethod("onIncomingPush", arguments: payload.dictionaryPayload)
      }
      
      completion()
  }
}
