import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/trips/services/trip_service.dart';
import 'package:voyage_flutter/features/trips/widgets/trip_form.dart';
import 'package:voyage_flutter/models/trip.dart';

class EditTripScreen extends StatefulWidget {
  const EditTripScreen({required this.trip, super.key});

  final Trip trip;

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final _tripService = TripService();

  Future<void> _updateTrip({
    required String tripName,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required TripType tripType,
    String? description,
  }) async {
    try {
      await _tripService.updateTrip(
        trip: Trip(
          tripId: widget.trip.tripId,
          ownerId: widget.trip.ownerId,
          tripName: tripName,
          destination: destination,
          startDate: startDate,
          endDate: endDate,
          tripType: tripType,
          description: description,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on TripServiceException catch (error) {
      _showError(error.message);
    } on Object catch (error) {
      _showError(TripService.userMessage(error));
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
      appBar: AppBar(title: const Text('Edit Trip')),
      body: TripForm(
        initialTrip: widget.trip,
        submitLabel: 'Save changes',
        onSubmit: _updateTrip,
      ),
    );
  }
}
