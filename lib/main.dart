import 'package:flutter/material.dart';
import 'screens/itinerary_screen.dart';

void main() {
  runApp(const VoyageApp());
}

class VoyageApp extends StatelessWidget {
  const VoyageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voyage',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const ItineraryScreen(),
    );
  }
}