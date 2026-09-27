import 'package:flutter/material.dart';
import '../models/itinerary.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  final List<Itinerary> activities = [
    Itinerary(
      id: '1',
      tripId: 'trip01',
      title: 'Breakfast',
      place: 'Hotel Restaurant',
      date: '25 September 2026',
      startTime: '09:00 AM',
      endTime: '10:00 AM',
      description: 'Breakfast at the hotel',
    ),
    Itinerary(
      id: '2',
      tripId: 'trip01',
      title: 'Visit Statue of Unity',
      place: 'Kevadia, Gujarat',
      date: '25 September 2026',
      startTime: '11:00 AM',
      endTime: '01:00 PM',
      description: 'Visit the Statue of Unity',
    ),
    Itinerary(
      id: '3',
      tripId: 'trip01',
      title: 'Lunch',
      place: 'Local Restaurant',
      date: '25 September 2026',
      startTime: '02:00 PM',
      endTime: '03:00 PM',
      description: 'Lunch at a local restaurant',
    ),
  ];

  void showAddActivityDialog() {
    final titleController = TextEditingController();
    final placeController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Activity'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Activity Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: placeController,
                  decoration: const InputDecoration(
                    labelText: 'Place',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty ||
                    placeController.text.trim().isEmpty) {
                  return;
                }

                setState(() {
                  activities.add(
                    Itinerary(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      tripId: 'trip01',
                      title: titleController.text.trim(),
                      place: placeController.text.trim(),
                      date: '25 September 2026',
                      startTime: '04:00 PM',
                      endTime: '05:00 PM',
                      description: descriptionController.text.trim(),
                    ),
                  );
                });

                Navigator.pop(context);
              },
              child: const Text('Add Activity'),
            ),
          ],
        );
      },
    );
  }

  void showEditActivityDialog(Itinerary activity) {
    final titleController =
    TextEditingController(text: activity.title);
    final placeController =
    TextEditingController(text: activity.place);
    final descriptionController =
    TextEditingController(text: activity.description);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Activity'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Activity Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: placeController,
                  decoration: const InputDecoration(
                    labelText: 'Place',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty ||
                    placeController.text.trim().isEmpty) {
                  return;
                }

                setState(() {
                  activity.title = titleController.text.trim();
                  activity.place = placeController.text.trim();
                  activity.description =
                      descriptionController.text.trim();
                });

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gujarat Trip'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Day 1',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '25 September 2026',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          for (final activity in activities)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(
                  activity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${activity.startTime} - ${activity.endTime}\n'
                      '${activity.place}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    showEditActivityDialog(activity);
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddActivityDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}