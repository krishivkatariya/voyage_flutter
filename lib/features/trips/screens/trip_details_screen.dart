import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/collaboration/screens/members_screen.dart';
import 'package:voyage_flutter/features/collaboration/screens/voting_screen.dart';
import 'package:voyage_flutter/features/expenses/screens/expenses_screen.dart';
import 'package:voyage_flutter/features/itinerary/screens/itinerary_screen.dart';
import 'package:voyage_flutter/features/trips/screens/edit_trip_screen.dart';
import 'package:voyage_flutter/features/trips/services/trip_service.dart';
import 'package:voyage_flutter/features/trips/widgets/trip_card.dart';
import 'package:voyage_flutter/models/trip.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({required this.tripId, super.key});

  final String tripId;

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final _tripService = TripService();
  late Future<Trip?> _tripFuture;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _tripFuture = _tripService.getTrip(tripId: widget.tripId);
  }

  void _reloadTrip() {
    setState(() {
      _tripFuture = _tripService.getTrip(tripId: widget.tripId);
    });
  }

  Future<void> _editTrip(Trip trip) async {
    final wasUpdated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => EditTripScreen(trip: trip)),
    );
    if (wasUpdated == true && mounted) {
      _reloadTrip();
    }
  }

  Future<void> _deleteTrip(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete trip?'),
        content: const Text(
          'This trip document will be deleted. Related members, activities, '
          'votes, and expenses will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete trip'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _isDeleting) {
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await _tripService.deleteTrip(tripId: trip.tripId);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Trip deleted.')));
      }
    } on TripServiceException catch (error) {
      _showError(error.message);
    } on Object catch (error) {
      _showError(TripService.userMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
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
      appBar: AppBar(title: const Text('Trip Details')),
      body: FutureBuilder<Trip?>(
        future: _tripFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _DetailsMessage(
              message: TripService.userMessage(snapshot.error!),
              onRetry: _reloadTrip,
            );
          }
          final trip = snapshot.data;
          if (trip == null) {
            return const _DetailsMessage(
              message: 'This trip no longer exists.',
            );
          }

          final isOwner =
              firebase_auth.FirebaseAuth.instance.currentUser?.uid ==
              trip.ownerId;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                trip.tripName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                trip.destination,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              _DetailRow(
                label: 'Start date',
                value: formatTripDate(trip.startDate),
              ),
              _DetailRow(
                label: 'End date',
                value: formatTripDate(trip.endDate),
              ),
              _DetailRow(label: 'Trip type', value: trip.tripType.label),
              if (trip.description?.isNotEmpty ?? false)
                _DetailRow(label: 'Description', value: trip.description!),
              const SizedBox(height: 16),
              _OwnerInformation(ownerId: trip.ownerId),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MembersScreen(tripId: trip.tripId),
                    ),
                  );
                },
                icon: const Icon(Icons.people_outline),
                label: const Text('Members'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => VotingScreen(tripId: trip.tripId),
                    ),
                  );
                },
                icon: const Icon(Icons.how_to_vote_outlined),
                label: const Text('Voting'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ExpensesScreen(tripId: trip.tripId),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Expenses'),
              ),
              const SizedBox(height: 8),
              if (isOwner) ...[
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ItineraryScreen(tripId: trip.tripId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.event_note),
                  label: const Text('Itinerary'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _isDeleting ? null : () => _editTrip(trip),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Trip'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isDeleting ? null : () => _deleteTrip(trip),
                  icon: const Icon(Icons.delete_outline),
                  label: _isDeleting
                      ? const Text('Deleting...')
                      : const Text('Delete Trip'),
                ),
                const SizedBox(height: 24),
              ] else
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Text(
                    'Only the trip owner can edit or delete this trip.',
                  ),
                ),
              Text(
                'More trip features',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ComingSoonChip(label: 'Places / Map'),
                  _ComingSoonChip(label: 'Members'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OwnerInformation extends StatelessWidget {
  const _OwnerInformation({required this.ownerId});

  final String ownerId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .snapshots(),
      builder: (context, snapshot) {
        final name = snapshot.data?.data()?['name'];
        final ownerName = name is String && name.trim().isNotEmpty
            ? name.trim()
            : 'Trip owner';
        return _DetailRow(label: 'Owner', value: ownerName);
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ComingSoonChip extends StatelessWidget {
  const _ComingSoonChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text('$label · Coming soon'), onPressed: null);
  }
}

class _DetailsMessage extends StatelessWidget {
  const _DetailsMessage({required this.message, this.onRetry});

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
