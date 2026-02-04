import 'package:flutter/material.dart';
import 'package:flutter_voip_kit_osato07/flutter_voip_kit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    FlutterVoipKit().initialize(
      onEvent: (event) {
        print("VoIP Event: ${event.event}");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('VoIP Kit Example')),
        body: const Center(child: Text('VoIP Kit is initialized')),
      ),
    );
  }
}
