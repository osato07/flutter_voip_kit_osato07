import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';

export 'package:flutter_callkit_incoming/entities/entities.dart';

/// Top-level background handler for Android FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
  // If the message contains data payload for VoIP
  if (message.data.isNotEmpty && message.data['callType'] == 'voip_incoming') {
    await FlutterVoipKit().showIncomingCall(message.data);
  }
}

class FlutterVoipKit {
  static final FlutterVoipKit _instance = FlutterVoipKit._internal();
  factory FlutterVoipKit() => _instance;
  FlutterVoipKit._internal();

  static const MethodChannel _channel = MethodChannel('flutter_voip_kit');
  final Uuid _uuid = const Uuid();
  bool _isInitialized = false;

  /// Initialize the VoIP service
  /// [onEvent] is a callback when the user accepts the call
  Future<void> initialize({Function(CallEvent)? onEvent}) async {
    if (_isInitialized) return;

    // Initialize Firebase if not already
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      print("Firebase Init Error: $e");
    }

    // Android: FCM Setup
    if (Platform.isAndroid) {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Foreground handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.data.isNotEmpty &&
            message.data['callType'] == 'voip_incoming') {
          showIncomingCall(message.data);
        }
      });
    }

    // iOS: Initialize Native Plugin
    if (Platform.isIOS) {
      await _channel.invokeMethod('initialize');
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onVoipToken') {
          print("Received VoIP Token via Plugin: ${call.arguments}");
          // TODO: Expose this token to the user
        } else if (call.method == 'onIncomingPush') {
          try {
            final data = Map<String, dynamic>.from(call.arguments);
            showIncomingCall(data);
          } catch (e) {
            print("Error parsing VoIP push data: $e");
          }
        }
      });
    }

    // Setup CallKit Incoming Listeners
    FlutterCallkitIncoming.onEvent.listen((event) {
      if (onEvent != null && event != null) {
        onEvent(event);
      }
    });

    _isInitialized = true;
  }

  /// Show incoming call UI (Uses generic data map)
  Future<void> showIncomingCall(Map<String, dynamic> data) async {
    var callId = data['uuid'] ?? _uuid.v4();

    final params = CallKitParams(
      id: callId,
      nameCaller: data['name'] ?? 'Unknown Caller',
      appName: 'VoIP App',
      avatar: data['avatar'],
      handle: data['handle'] ?? '000000',
      type: 0,
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      extra: <String, dynamic>{'userId': data['userId']},
      headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  /// Get FCM Token (For Android mostly)
  Future<String?> getFcmToken() async {
    return await FirebaseMessaging.instance.getToken();
  }
}
