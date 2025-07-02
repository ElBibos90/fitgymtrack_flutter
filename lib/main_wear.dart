import 'package:flutter/material.dart';

void main() {
  runApp(const WearApp());
}

class WearApp extends StatelessWidget {
  const WearApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitGymTrack Wear',
      theme: ThemeData.dark(),
      home: const WearHomePage(),
    );
  }
}

class WearHomePage extends StatelessWidget {
  const WearHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Benvenuto su FitGymTrack\nper Wear OS!',
              style: const TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
} 