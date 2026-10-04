import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/auth/services/auth_service.dart';
import 'package:voyage_flutter/features/trips/screens/create_trip_screen.dart';
import 'package:voyage_flutter/features/trips/screens/trips_screen.dart';
import 'package:voyage_flutter/features/trips/services/trip_service.dart';
import 'package:voyage_flutter/models/trip.dart';
import 'package:voyage_flutter/screens/itinerary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.user, required this.authService, super.key});

  final firebase_auth.User user;
  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _profileStream;
  late final Stream<List<Trip>> _tripsStream;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _profileStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots();
    _tripsStream = TripService().getUserTrips(ownerId: widget.user.uid);
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() => _isLoggingOut = true);
    try {
      await widget.authService.logoutUser();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(AuthService.errorMessage(error))),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  void _openCreateTrip() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CreateTripScreen()));
  }

  void _openTrips() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const TripsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voyage'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Welcome,', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _profileStream,
            builder: (context, snapshot) {
              final nameValue = snapshot.data?.data()?['name'];
              final name = nameValue is String && nameValue.trim().isNotEmpty
                  ? nameValue.trim()
                  : widget.user.email ?? 'Traveler';
              return Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall,
              );
            },
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<Trip>>(
            stream: _tripsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _DashboardCounts(
                  message: TripService.userMessage(snapshot.error!),
                );
              }
              if (!snapshot.hasData) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final today = DateTime.now();
              final todayStart = DateTime(today.year, today.month, today.day);
              final trips = snapshot.data!;
              final upcomingCount = trips
                  .where(
                    (trip) => !_dateOnly(trip.endDate).isBefore(todayStart),
                  )
                  .length;
              final completedCount = trips
                  .where((trip) => _dateOnly(trip.endDate).isBefore(todayStart))
                  .length;

              return Row(
                children: [
                  Expanded(
                    child: _CountCard(
                      label: 'Upcoming trips',
                      count: upcomingCount,
                      icon: Icons.flight_takeoff,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CountCard(
                      label: 'Completed trips',
                      count: completedCount,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _openTrips,
            icon: const Icon(Icons.luggage_outlined),
            label: const Text('My Trips'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openCreateTrip,
            icon: const Icon(Icons.add),
            label: const Text('Create Trip'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ItineraryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.event_note),
            label: const Text('Open existing itinerary'),
          ),
          const SizedBox(height: 16),
          Text(
            widget.user.email ?? 'Signed in',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class _DashboardCounts extends StatelessWidget {
  const _DashboardCounts({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.label,
    required this.count,
    required this.icon,
  });

  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text('$count', style: Theme.of(context).textTheme.headlineMedium),
            Text(label),
          ],
        ),
      ),
    );
  }
}
