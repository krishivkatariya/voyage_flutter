import 'package:flutter/material.dart';

class RouteDistanceScreen extends StatefulWidget {
  const RouteDistanceScreen({super.key});

  @override
  State<RouteDistanceScreen> createState() =>
      _RouteDistanceScreenState();
}

class _RouteDistanceScreenState
    extends State<RouteDistanceScreen> {
  final TextEditingController fromController =
  TextEditingController();

  final TextEditingController toController =
  TextEditingController();

  String distance = '';

  void calculateDistance() {
    final from = fromController.text.trim().toLowerCase();
    final to = toController.text.trim().toLowerCase();

    String result;

    if (from == 'ahmedabad' &&
        to == 'statue of unity') {
      result = 'Approximately 200 km';
    } else if (from == 'vadodara' &&
        to == 'statue of unity') {
      result = 'Approximately 90 km';
    } else if (from == 'ahmedabad' &&
        to == 'vadodara') {
      result = 'Approximately 110 km';
    } else if (from == 'mumbai' &&
        to == 'pune') {
      result = 'Approximately 150 km';
    } else {
      result = 'Distance data not available';
    }

    setState(() {
      distance = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route & Distance'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: fromController,
              decoration: const InputDecoration(
                labelText: 'From',
                hintText: 'Enter starting location',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: toController,
              decoration: const InputDecoration(
                labelText: 'To',
                hintText: 'Enter destination',
                prefixIcon: Icon(Icons.flag),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: calculateDistance,
                child: const Text('Calculate Distance'),
              ),
            ),

            const SizedBox(height: 30),

            if (distance.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    children: [
                      const Icon(
                        Icons.route,
                        size: 50,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Distance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        distance,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}