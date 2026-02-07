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

  /// VoIP Token (iOS only)
  String? _voipToken;

  /// Stream controller for VoIP token updates
  final StreamController<String> _tokenStreamController =
      StreamController<String>.broadcast();

  /// Get VoIP Token (iOS only)
  /// Returns null on Android or if not yet received
  Future<String?> getVoIPToken() async {
    return _voipToken;
  }

  /// Stream of VoIP token updates (iOS only)
  Stream<String> get onTokenRaw => _tokenStreamController.stream;

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
          final token = call.arguments as String?;
          print("Received VoIP Token via Plugin: $token");

          if (token != null) {
            _voipToken = token;
            _tokenStreamController.add(token);
          }
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

  /// Dispose the VoIP service
  void dispose() {
    _tokenStreamController.close();
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

  /// Start an outgoing call
  Future<void> startCall({
    required String uuid,
    required String handle,
    String? nameCaller,
    String? avatar,
    bool hasVideo = false,
  }) async {
    final params = CallKitParams(
      id: uuid,
      nameCaller: nameCaller ?? handle,
      handle: handle,
      type: 1, // 1 = Outgoing
      extra: <String, dynamic>{'userId': handle},
      ios: IOSParams(handleType: 'generic', supportsVideo: hasVideo),
    );
    await FlutterCallkitIncoming.startCall(params);
  }

  /// End a specific call by UUID
  Future<void> endCall(String uuid) async {
    await FlutterCallkitIncoming.endCall(uuid);
  }

  /// End all active calls
  Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
  }

  /// Mute or Unmute a call
  Future<void> muteCall(String uuid, bool isMuted) async {
    await FlutterCallkitIncoming.muteCall(uuid, isMuted: isMuted);
  }

  /// Hold or Unhold a call
  Future<void> holdCall(String uuid, bool isOnHold) async {
    await FlutterCallkitIncoming.holdCall(uuid, isOnHold: isOnHold);
  }

  /// Get list of active calls
  Future<List<dynamic>> activeCalls() async {
    return await FlutterCallkitIncoming.activeCalls();
  }

  /// Stream of call events
  Stream<CallEvent?> get onEvent => FlutterCallkitIncoming.onEvent;

  /// Get FCM Token (For Android / iOS Standard Notifications)
  /// NOTE: For iOS VoIP notifications, use [getVoIPToken] instead.
  Future<String?> getFcmToken() async {
    return await FirebaseMessaging.instance.getToken();
  }
}
