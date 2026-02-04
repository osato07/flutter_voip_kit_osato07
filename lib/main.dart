import 'package:flutter/material.dart';
import 'package:flutter_voip_kit/flutter_voip_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // We initialize the service as early as possible?
  // Good practice is to let the UI control the flow or have a separate bootstrap.
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String _status = "Initializing...";
  String _token = "Unknown"; // FCM Token (APNS on iOS)

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    await FlutterVoipKit().initialize(
      onEvent: (event) {
        // This is where you handle call events
        switch (event.event) {
          case Event.actionCallIncoming:
            print(
              "📞 Incoming Call Received! Run your logic here (e.g. logging)",
            );
            // Note: The UI is already showing.
            break;

          case Event.actionCallAccept:
            print(
              "✅ Call Accepted! Navigate to call screen or start audio session.",
            );
            // View navigation logic goes here
            break;

          case Event.actionCallDecline:
            print("❌ Call Declined.");
            break;

          default:
            break;
        }

        setState(() {
          _status = "Last Event: ${event.event}";
        });
      },
    );

    // Attempt to get FCM token (Android/iOS)
    // Note: On iOS this is APNS token, not VoIP token (which comes from the Channel).
    try {
      String? token = await FlutterVoipKit().getFcmToken();

      setState(() {
        _token = token ?? "Failed to get FCM Token";
        if (_status == "Initializing...") {
          _status = "Service Initialized";
        }
      });
      print("FCM Token: $_token");
    } catch (e) {
      setState(() {
        _token = "Error getting token: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('VoIP Template')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Status: $_status', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                const Text("FCM Token (for Android Data Messages):"),
                SelectableText(_token, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Simulate an incoming call locally
                    FlutterVoipKit().showIncomingCall({
                      'uuid':
                          'test_call_id_${DateTime.now().millisecondsSinceEpoch}',
                      'name': 'Test Caller',
                      'handle': '+819000000000',
                      'userId': 'user_001',
                    });
                  },
                  child: const Text('Simulate Incoming Call (Local)'),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Use cloud functions or curl to send actual pushes.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
