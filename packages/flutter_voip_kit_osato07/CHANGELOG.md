## 0.1.7

* Required `CXProviderDelegate` implementation was added to `FlutterVoipKitPlugin.swift`.
* Fixed issue where CallKit calls could be ignored if the delegate was not set.
* Implemented mandatory `CXProviderDelegate` methods: `providerDidReset`, `perform CXAnswerCallAction`, and `perform CXEndCallAction`.

## 0.1.6

* Implemented native iOS CallKit reporting for incoming VoIP pushes to ensure iOS 13+ compliance.
* This ensures that incoming calls are reported to the system immediately, preventing app termination during push handling.

## 0.1.5

* Fixed iOS Swift compilation errors by updating `PKPushRegistryDelegate` method signatures.
* Ensured VoIP token management is correctly exposed in Dart.

## 0.1.4

* Renamed `ios/flutter_voip_kit.podspec` to `ios/flutter_voip_kit_osato07.podspec`.

## 0.1.3

* Added `getVoIPToken` method to retrieve iOS VoIP tokens.
* Added `onTokenRaw` stream for real-time VoIP token updates on iOS.
* Added `dispose` method to `FlutterVoipKit` for resource cleanup.
* Clarified `getFcmToken` vs `getVoIPToken` in documentation.

## 0.1.2

* Added call management methods: `startCall`, `endCall`, `endAllCalls`.
* Added in-call control methods: `muteCall`, `holdCall`.
* Added `activeCalls` to retrieve call status.
* Added `onEvent` stream getter.

## 0.1.1

* Update README documentation.

## 0.1.0

* Initial release.
* Support for iOS CallKit and PushKit.
* Support for Android ConnectionService and FCM Data Messages.
* Encapsulated logic into a reusable plugin.
