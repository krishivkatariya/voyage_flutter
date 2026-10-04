import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/itinerary/services/activity_validators.dart';
import 'package:voyage_flutter/features/itinerary/services/itinerary_service.dart';
import 'package:voyage_flutter/features/itinerary/widgets/activity_form.dart';
import 'package:voyage_flutter/models/activity.dart';

class EditActivityScreen extends StatefulWidget {
  const EditActivityScreen({
    required this.tripId,
    required this.activityId,
    super.key,
  });

  final String tripId;
  final String activityId;

  @override
  State<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends State<EditActivityScreen> {
  final _itineraryService = ItineraryService();
  late Future<Activity?> _activityFuture;

  @override
  void initState() {
    super.initState();
    _activityFuture = _loadActivity();
  }

  Future<Activity?> _loadActivity() async {
    final activity = await _itineraryService.getActivity(
      tripId: widget.tripId,
      activityId: widget.activityId,
    );
    if (activity != null && activity.tripId != widget.tripId) {
      throw const ItineraryServiceException(
        'This activity does not belong to the selected trip.',
      );
    }
    return activity;
  }

  Future<void> _updateActivity(
    Activity activity, {
    required String title,
    required String placeName,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await _itineraryService.updateActivity(
        activity: Activity(
          activityId: activity.activityId,
          tripId: widget.tripId,
          title: title.trim(),
          placeName: placeName.trim(),
          date: date,
          startTime: ActivityValidators.serializeTime(startTime),
          endTime: ActivityValidators.serializeTime(endTime),
          description: description,
          latitude: latitude,
          longitude: longitude,
          createdBy: activity.createdBy,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ItineraryServiceException catch (error) {
      _showError(error.message);
    } on Object catch (error) {
      _showError(ItineraryService.userMessage(error));
    }
  }

  void _showError(String message) {
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
      appBar: AppBar(title: const Text('Edit Activity')),
      body: FutureBuilder<Activity?>(
        future: _activityFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _EditActivityMessage(
              message: ItineraryService.userMessage(snapshot.error!),
              onRetry: () {
                setState(() => _activityFuture = _loadActivity());
              },
            );
          }
          final activity = snapshot.data;
          if (activity == null) {
            return const _EditActivityMessage(
              message: 'This activity no longer exists.',
            );
          }

          return ActivityForm(
            initialActivity: activity,
            submitLabel: 'Save changes',
            onSubmit:
                ({
                  required title,
                  required placeName,
                  required date,
                  required startTime,
                  required endTime,
                  description,
                  latitude,
                  longitude,
                }) => _updateActivity(
                  activity,
                  title: title,
                  placeName: placeName,
                  date: date,
                  startTime: startTime,
                  endTime: endTime,
                  description: description,
                  latitude: latitude,
                  longitude: longitude,
                ),
          );
        },
      ),
    );
  }
}

class _EditActivityMessage extends StatelessWidget {
  const _EditActivityMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
