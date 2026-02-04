# Flutter VoIP Kit

A Flutter plugin for handling VoIP calls on iOS (CallKit + PushKit) and Android (ConnectionService + FCM).

## Features

*   **iOS**: Integrates `PKPushRegistry` for incoming VoIP notifications.
*   **Android**: Handles `FOREGROUND_SERVICE` and full-screen intents via FCM.
*   **Unified API**: Simple `initialize` and `onEvent` API.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_voip_kit: ^0.0.1
```

## Usage

```dart
import 'package:flutter_voip_kit/flutter_voip_kit.dart';

await FlutterVoipKit().initialize(
  onEvent: (event) {
     print("VoIP Event: ${event.event}");
  }
);
```

See the example app for full implementation details.

