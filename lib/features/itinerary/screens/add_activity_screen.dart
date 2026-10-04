import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/itinerary/services/activity_validators.dart';
import 'package:voyage_flutter/features/itinerary/services/itinerary_service.dart';
import 'package:voyage_flutter/features/itinerary/widgets/activity_form.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({required this.tripId, super.key});

  final String tripId;

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _itineraryService = ItineraryService();

  Future<void> _createActivity({
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
      await _itineraryService.createActivity(
        tripId: widget.tripId,
        title: title,
        placeName: placeName,
        date: date,
        startTime: ActivityValidators.serializeTime(startTime),
        endTime: ActivityValidators.serializeTime(endTime),
        description: description,
        latitude: latitude,
        longitude: longitude,
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
      appBar: AppBar(title: const Text('Add Activity')),
      body: ActivityForm(
        submitLabel: 'Add activity',
        onSubmit: _createActivity,
      ),
    );
  }
}
