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
      date: '26 September 2026',
      startTime: '02:00 PM',
      endTime: '03:00 PM',
      description: 'Lunch at a local restaurant',
    ),
    Itinerary(
      id: '4',
      tripId: 'trip01',
      title: 'Visit Ahmedabad',
      place: 'Ahmedabad, Gujarat',
      date: '27 September 2026',
      startTime: '10:00 AM',
      endTime: '01:00 PM',
      description: 'Visit Ahmedabad',
    ),
  ];

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  DateTime _parseDate(String date) {
    final parts = date.split(' ');

    final day = int.parse(parts[0]);

    const months = {
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12,
    };

    final month = months[parts[1]]!;
    final year = int.parse(parts[2]);

    return DateTime(year, month, day);
  }

  Map<String, List<Itinerary>> _groupActivitiesByDate() {
    final Map<String, List<Itinerary>> grouped = {};

    for (final activity in activities) {
      if (!grouped.containsKey(activity.date)) {
        grouped[activity.date] = [];
      }

      grouped[activity.date]!.add(activity);
    }

    return grouped;
  }

  void showAddActivityDialog() {
    final titleController = TextEditingController();
    final placeController = TextEditingController();
    final descriptionController = TextEditingController();

    DateTime selectedDate = DateTime(2026, 9, 25);

    TimeOfDay selectedStartTime = const TimeOfDay(
      hour: 16,
      minute: 0,
    );

    TimeOfDay selectedEndTime = const TimeOfDay(
      hour: 17,
      minute: 0,
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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

                    const SizedBox(height: 12),

                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date'),
                      subtitle: Text(
                        '${selectedDate.day} '
                            '${_monthName(selectedDate.month)} '
                            '${selectedDate.year}',
                      ),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2026),
                          lastDate: DateTime(2030),
                        );

                        if (pickedDate != null) {
                          setDialogState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Start Time'),
                      subtitle: Text(
                        _formatTime(selectedStartTime),
                      ),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedStartTime,
                        );

                        if (pickedTime != null) {
                          setDialogState(() {
                            selectedStartTime = pickedTime;
                          });
                        }
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.access_time_filled),
                      title: const Text('End Time'),
                      subtitle: Text(
                        _formatTime(selectedEndTime),
                      ),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedEndTime,
                        );

                        if (pickedTime != null) {
                          setDialogState(() {
                            selectedEndTime = pickedTime;
                          });
                        }
                      },
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
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          tripId: 'trip01',
                          title: titleController.text.trim(),
                          place: placeController.text.trim(),
                          date:
                          '${selectedDate.day} '
                              '${_monthName(selectedDate.month)} '
                              '${selectedDate.year}',
                          startTime:
                          _formatTime(selectedStartTime),
                          endTime:
                          _formatTime(selectedEndTime),
                          description:
                          descriptionController.text.trim(),
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
                  activity.title =
                      titleController.text.trim();

                  activity.place =
                      placeController.text.trim();

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

  void deleteActivity(Itinerary activity) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Activity'),

          content: const Text(
            'Are you sure you want to delete this activity?',
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
                setState(() {
                  activities.remove(activity);
                });

                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedActivities = _groupActivitiesByDate();

    final sortedDates = groupedActivities.keys.toList();

    sortedDates.sort(
          (a, b) => _parseDate(a).compareTo(_parseDate(b)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gujarat Trip'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          for (int dayIndex = 0;
          dayIndex < sortedDates.length;
          dayIndex++) ...[
            Text(
              'Day ${dayIndex + 1}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              sortedDates[dayIndex],
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            for (final activity
            in groupedActivities[sortedDates[dayIndex]]!)
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
                    '${activity.startTime} - '
                        '${activity.endTime}\n'
                        '${activity.place}',
                  ),

                  isThreeLine: true,

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          showEditActivityDialog(activity);
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          deleteActivity(activity);
                        },
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: showAddActivityDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}