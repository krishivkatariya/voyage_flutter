import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/itinerary/screens/add_activity_screen.dart';
import 'package:voyage_flutter/features/itinerary/screens/edit_activity_screen.dart';
import 'package:voyage_flutter/features/itinerary/services/itinerary_service.dart';
import 'package:voyage_flutter/features/itinerary/services/activity_validators.dart';
import 'package:voyage_flutter/features/itinerary/widgets/activity_card.dart';
import 'package:voyage_flutter/models/activity.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({required this.tripId, super.key});

  final String tripId;

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  final _itineraryService = ItineraryService();
  late Stream<List<Activity>> _activitiesStream;

  @override
  void initState() {
    super.initState();
    _activitiesStream = _itineraryService.getActivities(tripId: widget.tripId);
  }

  Future<void> _addActivity() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddActivityScreen(tripId: widget.tripId),
      ),
    );
    if (added == true && mounted) {
      _showMessage('Activity added.');
    }
  }

  Future<void> _editActivity(Activity activity) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditActivityScreen(
          tripId: widget.tripId,
          activityId: activity.activityId,
        ),
      ),
    );
    if (updated == true && mounted) {
      _showMessage('Activity updated.');
    }
  }

  Future<void> _deleteActivity(Activity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete activity?'),
        content: Text('Delete "${activity.title}" from this itinerary?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _itineraryService.deleteActivity(
        tripId: widget.tripId,
        activityId: activity.activityId,
      );
      if (mounted) {
        _showMessage('Activity deleted.');
      }
    } on ItineraryServiceException catch (error) {
      _showMessage(error.message);
    } on Object catch (error) {
      _showMessage(ItineraryService.userMessage(error));
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Itinerary')),
      body: StreamBuilder<List<Activity>>(
        stream: _activitiesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ItineraryMessage(
              message: ItineraryService.userMessage(snapshot.error!),
              retryLabel: 'Retry',
              onPressed: () {
                setState(() {
                  _activitiesStream = _itineraryService.getActivities(
                    tripId: widget.tripId,
                  );
                });
              },
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final activities = snapshot.data!;
          if (activities.isEmpty) {
            return _ItineraryMessage(
              message: 'No activities yet. Add one to start this itinerary.',
              buttonLabel: 'Add Activity',
              onPressed: _addActivity,
            );
          }

          final groupedActivities = <DateTime, List<Activity>>{};
          for (final activity in activities) {
            final day = DateTime(
              activity.date.year,
              activity.date.month,
              activity.date.day,
            );
            groupedActivities.putIfAbsent(day, () => []).add(activity);
          }

          final days = groupedActivities.keys.toList()..sort();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: days.length,
            itemBuilder: (context, dayIndex) {
              final day = days[dayIndex];
              final dayActivities = groupedActivities[day]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      'Day ${dayIndex + 1} — '
                      '${ActivityValidators.formatDate(day)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ...dayActivities.map(
                    (activity) => ActivityCard(
                      activity: activity,
                      onEdit: () => _editActivity(activity),
                      onDelete: () => _deleteActivity(activity),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addActivity,
        icon: const Icon(Icons.add),
        label: const Text('Add Activity'),
      ),
    );
  }
}

class _ItineraryMessage extends StatelessWidget {
  const _ItineraryMessage({
    required this.message,
    this.buttonLabel,
    this.retryLabel,
    this.onPressed,
  });

  final String message;
  final String? buttonLabel;
  final String? retryLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (buttonLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add),
                label: Text(buttonLabel!),
              ),
            ],
            if (retryLabel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onPressed, child: Text(retryLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
