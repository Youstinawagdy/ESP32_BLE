import 'package:flutter/material.dart';
import 'ble_scanner_screen.dart';

void main() {
  runApp(const BLEScannerApp());
}

class BLEScannerApp extends StatelessWidget {
  const BLEScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BLEScannerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
