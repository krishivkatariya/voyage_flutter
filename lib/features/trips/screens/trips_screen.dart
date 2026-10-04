import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/trips/screens/create_trip_screen.dart';
import 'package:voyage_flutter/features/trips/screens/trip_details_screen.dart';
import 'package:voyage_flutter/features/trips/services/trip_service.dart';
import 'package:voyage_flutter/features/trips/widgets/trip_card.dart';
import 'package:voyage_flutter/models/trip.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  late final Stream<List<Trip>> _tripsStream;
  late final String _userId;

  @override
  void initState() {
    super.initState();
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? '';
    _tripsStream = _userId.isEmpty
        ? const Stream.empty()
        : TripService().getUserTrips(ownerId: _userId);
  }

  void _openCreateTrip() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CreateTripScreen()));
  }

  void _openTrip(Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripDetailsScreen(tripId: trip.tripId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Trips')),
      body: _userId.isEmpty
          ? const _TripsMessage(message: 'Sign in to view your trips.')
          : StreamBuilder<List<Trip>>(
              stream: _tripsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _TripsMessage(
                    message: TripService.userMessage(snapshot.error!),
                    showRetryHint: true,
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final trips = snapshot.data!;
                if (trips.isEmpty) {
                  return _TripsMessage(
                    message: 'You do not have any trips yet.',
                    buttonLabel: 'Create your first trip',
                    onPressed: _openCreateTrip,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trips.length,
                  itemBuilder: (context, index) => TripCard(
                    trip: trips[index],
                    onTap: () => _openTrip(trips[index]),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTrip,
        icon: const Icon(Icons.add),
        label: const Text('Create Trip'),
      ),
    );
  }
}

class _TripsMessage extends StatelessWidget {
  const _TripsMessage({
    required this.message,
    this.buttonLabel,
    this.onPressed,
    this.showRetryHint = false,
  });

  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;
  final bool showRetryHint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (showRetryHint) ...[
              const SizedBox(height: 8),
              const Text('Return to this screen to try again.'),
            ],
            if (buttonLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onPressed, child: Text(buttonLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
