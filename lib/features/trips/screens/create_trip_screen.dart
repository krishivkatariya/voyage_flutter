import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/trips/screens/trip_details_screen.dart';
import 'package:voyage_flutter/features/trips/services/trip_service.dart';
import 'package:voyage_flutter/features/trips/widgets/trip_form.dart';
import 'package:voyage_flutter/models/trip.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _tripService = TripService();

  Future<void> _createTrip({
    required String tripName,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required TripType tripType,
    String? description,
  }) async {
    try {
      final tripId = await _tripService.createTrip(
        tripName: tripName,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        tripType: tripType,
        description: description,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => TripDetailsScreen(tripId: tripId),
          ),
        );
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
      appBar: AppBar(title: const Text('Create Trip')),
      body: TripForm(submitLabel: 'Create trip', onSubmit: _createTrip),
    );
  }
}
