# Flutter VoIP Kit Template

This project provides a "ready-to-use" implementation for cross-platform VoIP calls (Audio/Video) using Flutter, Firebase, and CallKit/ConnectionService.

## 🌟 Features
- **Library-based Architecture**: Core logic is encapsulated in `packages/flutter_voip_kit_osato07`.
- **iOS**: Native `PKPushRegistry` integration for standard-compliant VoIP handling.
- **Android**: High-priority FCM Data Message handling with full-screen intent support.

---

## 🛠 Prerequisites
1.  **Firebase Project**: Create one at [console.firebase.google.com](https://console.firebase.google.com/).
2.  **Apple Developer Account**: Required for VoIP Certificates.

---

## 🍎 iOS Setup (Critical)

VoIP on iOS requires precise configuration. One missed step will cause silent failures.

### 1. Xcode Capabilities
Open `ios/Runner.xcworkspace` in Xcode. Select your target (Runner) -> **Signing & Capabilities**.
1.  **+ Capability** -> **Background Modes** -> Check:
    -   ✅ **Audio, AirPlay, and Picture in Picture**
    -   ✅ **Voice over IP**
    -   ✅ **Remote notifications**
2.  **+ Capability** -> **Push Notifications** (if not already added).

### 2. Certificates & Provisioning
1.  Go to [Apple Developer Console](https://developer.apple.com/account/resources/certificates/list).
2.  Create a **VoIP Services Certificate**.
    -   Select your App ID.
    -   Download the `.cer` file.
3.  **Exporting .p12**:
    -   Open the `.cer` in Keychain Access.
    -   Right-click it and export as `.p12` (Give it a password).

### 3. Connection to Backend (Two Options)
You need to send VoIP pushes to APNs (Apple Push Notification service).

#### Option A: Using Firebase Cloud Messaging (Recommended for simplicity)
If you rely on `admin.messaging().send()` in your Cloud Functions:
1.  Go to Firebase Console -> **Project Settings** -> **Cloud Messaging** -> **Apple app configuration**.
2.  Upload your **APNs Authentication Key (.p8)** (Recommended over .p12 as it handles both VoIP and Standard).
    -   *Note*: Ensure your Key ID is enabled for "Apple Push Notifications service (APNs)".

#### Option B: Direct APNs in Cloud Functions (Advanced)
If you want to read certificates directly in `index.ts`:
1.  Place your `voip_cert.p12` (or key) inside `functions/certs/`.
2.  Use a library like `node-apn` instead of `firebase-admin` for the iOS part.
    ```typescript
    // In functions/index.ts (Pseudocode)
    import * as apn from 'apn';
    const apnProvider = new apn.Provider({
       pfx: "certs/voip_cert.p12",
       production: true // true for TestFlight/AppStore
    });
    // Send using apnProvider...
    ```
    *The provided template currently uses Option A (Firebase Admin).*

---

## 🤖 Android Setup

### 1. Firebase Config
1.  Download `google-services.json` from Firebase Console.
2.  Place it in: `android/app/google-services.json`.

### 2. Permissions (Automated)
The library `flutter_voip_kit_osato07` automatically injects required permissions:
-   `FOREGROUND_SERVICE`
-   `WAKE_LOCK`
-   `POST_NOTIFICATIONS`
-   `READ_PHONE_STATE`

You do **NOT** need to edit `AndroidManifest.xml` manually for these.

---

## ☁️ Backend (Cloud Functions)

The `functions/index.ts` determines how calls are routed.

### 1. Key Logic (Simulating VoIP)
We rely on **Push Types** to tell the OS this is a call.

-   **Android**: We send a `data` message with `"callType": "voip_incoming"`.
-   **iOS**: We send an APNs payload with headers:
    ```json
    "headers": {
      "apns-push-type": "voip",
      "apns-priority": "10",
      "apns-topic": "com.your.bundle.id.voip" 
    }
    ```
    *(Note: `.voip` suffix is often required depending on how you send it)*.

### 2. Deployment
```bash
firebase deploy --only functions
```

---

## 🚀 Usage in Flutter

### 1. Add Dependency
In `pubspec.yaml`:
```yaml
dependencies:
  flutter_voip_kit_osato07:
    path: ./packages/flutter_voip_kit_osato07
```

### 2. Initialize
In `lib/main.dart`:
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

// Inside your State class
@override
void initState() {
  super.initState();
  
  FlutterVoipKit().initialize(
    onEvent: (event) {
      if (event.event == Event.actionCallAccept) {
        // User answered! Navigate to Screen.
      }
    }
  );
  
  // Submit this token to your backend!
  FlutterVoipKit().getFcmToken().then((token) {
     // Save token to Firestore...
  });
}
```
