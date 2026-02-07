# Complete Guide: Implementing VoIP with flutter_voip_kit_osato07

このガイドでは、`flutter_voip_kit_osato07` をプロジェクトに導入した後、実際に着信画面（CallKit/ConnectionService）を表示させ、バックエンドから通知を送信するまでに必要な全手順を網羅します。

## 1. ライブラリの導入

`pubspec.yaml` に追加：

```yaml
dependencies:
  flutter_voip_kit_osato07: ^0.1.7
  firebase_core: ^4.0.0
  cloud_firestore: ^6.0.0 # トークン保存用（推奨）
  cloud_functions: ^6.0.0 # 通知送信テスト用（推奨）
```

## 2. iOS 固有の設定 (Xcode)

iOS で VoIP 通知を受け取るには、Xcode で複数の設定が必要です。

### 2.1 Capabilities の追加

1. Xcode で `ios/Runner.xcworkspace` を開きます。
2. Runner ターゲットを選択し、「Signing & Capabilities」タブを開きます。
3. 「+ Capability」をクリックし、以下を追加します：
   - **Push Notifications**
   - **Background Modes**
     - [x] Audio, AirPlay, and Picture in Picture
     - [x] Voice over IP
     - [x] Remote notifications

### 2.2 Info.plist の編集

`ios/Runner/Info.plist` に以下を追加（または確認）してください：

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>voip</string>
    <string>remote-notification</string>
</array>
```

## 3. Firebase & APNs 連携設定

### 3.1 APNs Auth Key (.p8) の準備

1. Apple Developer Portal で Apple Push Notifications service (APNs) キー（.p8ファイル）を作成します。
2. **Key ID** と **Team ID** をメモしておきます。

### 3.2 Firebase Console への登録

1. Firebase Console > プロジェクト設定 > クラウドメッセージング を開きます。
2. 「iOS アプリの設定」で、先ほどの .p8 ファイルをアップロードし、Key ID と Team ID を入力します。

## 4. バックエンド実装 (Firebase Cloud Functions)

iOS 13以降、VoIP通知は **FCM経由ではなく APNs へ直接送信** する必要があります。

### 4.1 必要なパッケージのインストール

`functions` ディレクトリで実行：

```bash
npm install apn firebase-admin firebase-functions
```

### 4.2 送信ロジックの実装例 (functions/index.js)

```javascript
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const apn = require("apn");

admin.initializeApp();

// APNs設定（自分の情報に書き換え）
const apnProvider = new apn.Provider({
    token: {
        key: "path/to/AuthKey_XXXXXXXX.p8",
        keyId: "XXXXXXXXXX",
        teamId: "YYYYYYYYYY"
    },
    production: false // 開発時は false
});

exports.sendVoipCall = functions.https.onCall(async (data, context) => {
    const { token, callerName, uuid, platform } = data;

    if (platform === "ios") {
        const note = new apn.Notification();
        note.expiry = Math.floor(Date.now() / 1000) + 3600;
        note.topic = "com.your.bundle.id.voip"; // 必ず .voip で終わる
        note.payload = { uuid, callerName, callType: "voip_incoming" };
        note.pushType = "voip";

        const result = await apnProvider.send(note, token);
        return { success: result.failed.length === 0 };
    } else {
        // AndroidはFCMで送信
        const message = {
            token: token,
            data: { uuid, callerName, callType: "voip_incoming" },
            android: { priority: "high" }
        };
        const response = await admin.messaging().send(message);
        return { success: true, messageId: response };
    }
});
```

## 5. Flutter フロントエンド実装

### 5.1 初期化とトークン管理

```dart
import 'package:flutter_voip_kit_osato07/flutter_voip_kit.dart';

class VoipManager {
  final _voipKit = FlutterVoipKit();

  Future<void> init() async {
    await _voipKit.initialize(
      onEvent: (event) {
        // 応答・拒否・終了などのイベント処理
        print('Event: ${event.event}');
      },
    );

    // トークンの取得（iOSはAPNs VoIPトークン、AndroidはFCMトークン）
    // ※ 起動直後は取れない場合があるため、Streamでの監視を推奨
    _voipKit.onTokenRaw.listen((token) {
      print('VoIP Token: $token');
      // サーバー（Firestore等）に保存する処理
    });
  }
}
```

### 5.2 トークン取得の注意点

iOS の VoIP トークンはアプリ起動から数秒遅れて発行されることがあります。以下のようなリトライ処理を含めるのが安全です：

```dart
Future<String?> getSafeToken() async {
  String? token = await _voipKit.getVoIPToken();
  int retry = 0;
  while (token == null && retry < 10) {
    await Future.delayed(Duration(milliseconds: 500));
    token = await _voipKit.getVoIPToken();
    retry++;
  }
  return token;
}
```

## 🧪 テスト・デバッグのヒント

- **実機必須**: VoIP 通知はシミュレーターでは動作しません。必ず iOS/Android 実機でテストしてください。
- **証明書の不一致**: 送信側の `bundleId.voip` とアプリの Bundle ID が一致しているか、.p8 キーが正しいか確認してください。
- **バックグラウンド実行**: アプリを完全に終了させた状態で通知を送り、着信画面が立ち上がるか確認してください。
- **Android の権限**: Android 13以降は `POST_NOTIFICATIONS` 権限が必要です。ライブラリが内部で要求しますが、アプリ側でも許可状態を確認してください。

## 📋 最終チェックリスト

- [ ] Apple Developer Portal で VoIP 用の証明書/Key を作成したか？
- [ ] Xcode で Voice over IP バックグラウンドモードを有効にしたか？
- [ ] バックエンドから送信する際のデバイストークンは、`getVoIPToken()` で取得したものか？
- [ ] 送信時の Topic 末尾に `.voip` を付けているか？（iOSの場合）
