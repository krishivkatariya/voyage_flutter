
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/trips/screens/create_trip_screen.dart';
import 'package:voyage_flutter/features/trips/screens/trip_details_screen.dart';
import 'package:voyage_flutter/features/trips/services/trip_service.dart';
import 'package:voyage_flutter/features/trips/widgets/trip_card.dart';
import 'package:voyage_flutter/models/trip.dart';

const Color _purple = Color(0xFF6D4AFF);
const Color _darkPurple = Color(0xFF38216D);
const Color _background = Color(0xFFF8F7FC);
const Color _mutedText = Color(0xFF77738A);

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

  Future<void> _openCreateTrip() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CreateTripScreen(),
      ),
    );
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
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Trips',
          style: TextStyle(
            color: _darkPurple,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: _darkPurple),
      ),
      body: _userId.isEmpty
          ? const _TripsMessage(
        icon: Icons.lock_outline_rounded,
        message: 'Sign in to view your trips.',
      )
          : StreamBuilder<List<Trip>>(
        stream: _tripsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _TripsMessage(
              icon: Icons.cloud_off_rounded,
              message: TripService.userMessage(snapshot.error!),
              showRetryHint: true,
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _purple),
            );
          }

          final trips = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 850;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1150),
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 32 : 18,
                      vertical: 18,
                    ),
                    children: [
                      _TripsHero(
                        tripCount: trips.length,
                        onCreate: _openCreateTrip,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your adventures',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: _darkPurple,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'All your journeys, in one place.',
                                  style: TextStyle(
                                    color: _mutedText,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE7FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${trips.length} ${trips.length == 1 ? 'trip' : 'trips'}',
                              style: const TextStyle(
                                color: _purple,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (trips.isEmpty)
                        _EmptyTrips(onCreate: _openCreateTrip)
                      else if (wide)
                        GridView.builder(
                          shrinkWrap: true,
                          physics:
                          const NeverScrollableScrollPhysics(),
                          itemCount: trips.length,
                          gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 520,
                            mainAxisExtent: 205,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemBuilder: (context, index) {
                            final trip = trips[index];
                            return TripCard(
                              trip: trip,
                              onTap: () => _openTrip(trip),
                            );
                          },
                        )
                      else
                        ...trips.map(
                              (trip) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: TripCard(
                              trip: trip,
                              onTap: () => _openTrip(trip),
                            ),
                          ),
                        ),
                      const SizedBox(height: 28),
                      const Center(
                        child: Text(
                          'Every journey starts somewhere. ✦',
                          style: TextStyle(
                            color: _mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTrip,
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        elevation: 5,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Create Trip',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _TripsHero extends StatelessWidget {
  const _TripsHero({
    required this.tripCount,
    required this.onCreate,
  });

  final int tripCount;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_purple, _darkPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -18,
            child: Icon(
              Icons.flight_takeoff_rounded,
              size: 125,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'YOUR TRAVEL SPACE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Your next story\nstarts here.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$tripCount ${tripCount == 1 ? 'journey' : 'journeys'} planned. '
                    'More memories waiting.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _darkPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Plan a new trip',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE8FA)),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EBFF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.luggage_rounded,
              color: _purple,
              size: 37,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your adventures await',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _darkPurple,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first trip and start planning '
                'an unforgettable journey.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create your first trip'),
          ),
        ],
      ),
    );
  }
}

class _TripsMessage extends StatelessWidget {
  const _TripsMessage({
    required this.message,
    required this.icon,
    this.showRetryHint = false,
  });

  final String message;
  final IconData icon;
  final bool showRetryHint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: _purple),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _darkPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showRetryHint) ...[
              const SizedBox(height: 8),
              const Text(
                'Return to this screen to try again.',
                style: TextStyle(color: _mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
