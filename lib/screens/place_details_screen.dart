import 'package:flutter/material.dart';

class PlaceDetailsScreen extends StatelessWidget {
  final String placeName;

  const PlaceDetailsScreen({
    super.key,
    required this.placeName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Details'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on,
                size: 80,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              placeName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Row(
              children: [
                Icon(Icons.location_on),
                SizedBox(width: 8),
                Text(
                  'India',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              'About this place',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Explore this destination and discover '
                  'interesting places, attractions and activities '
                  'that you can add to your trip itinerary.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'This place can be viewed on the map '
                  'in the next step.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}