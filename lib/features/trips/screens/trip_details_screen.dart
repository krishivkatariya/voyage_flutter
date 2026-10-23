
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/collaboration/screens/members_screen.dart';
import 'package:voyage_flutter/features/collaboration/screens/voting_screen.dart';
import 'package:voyage_flutter/features/expenses/screens/expense_summary_screen.dart';
import 'package:voyage_flutter/features/expenses/screens/expenses_screen.dart';
import 'package:voyage_flutter/features/itinerary/screens/itinerary_screen.dart';
import 'package:voyage_flutter/features/trips/screens/edit_trip_screen.dart';
import 'package:voyage_flutter/features/trips/services/trip_service.dart';
import 'package:voyage_flutter/features/trips/widgets/trip_card.dart';
import 'package:voyage_flutter/models/trip.dart';
import 'package:voyage_flutter/screens/map_screen.dart';

const Color _purple = Color(0xFF6D4AFF);
const Color _darkPurple = Color(0xFF38216D);
const Color _background = Color(0xFFF8F7FC);
const Color _mutedText = Color(0xFF77738A);

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
      MaterialPageRoute<bool>(
        builder: (_) => EditTripScreen(trip: trip),
      ),
    );

    if (wasUpdated == true && mounted) {
      _reloadTrip();
    }
  }

  Future<void> _deleteTrip(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Delete this trip?'),
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
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
          ..showSnackBar(
            const SnackBar(content: Text('Trip deleted.')),
          );
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
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
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
          'Trip Details',
          style: TextStyle(
            color: _darkPurple,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: _darkPurple),
      ),
      body: FutureBuilder<Trip?>(
        future: _tripFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _purple),
            );
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

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 850;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 32 : 18,
                      vertical: 20,
                    ),
                    children: [
                      _TripHero(trip: trip),
                      const SizedBox(height: 24),
                      const _SectionHeading(
                        title: 'Your trip at a glance',
                        subtitle: 'Everything you need for your journey.',
                      ),
                      const SizedBox(height: 14),
                      _TripInformation(
                        trip: trip,
                        wide: wide,
                      ),
                      const SizedBox(height: 28),
                      const _SectionHeading(
                        title: 'Plan together',
                        subtitle: 'Organize every part of your adventure.',
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: wide ? 3 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: wide ? 1.65 : 1.12,
                        children: [
                          _FeatureCard(
                            title: 'Members',
                            subtitle: 'Your travel group',
                            icon: Icons.people_alt_rounded,
                            onTap: () => _openScreen(
                              MembersScreen(tripId: trip.tripId),
                            ),
                          ),
                          _FeatureCard(
                            title: 'Voting',
                            subtitle: 'Decide as a group',
                            icon: Icons.how_to_vote_rounded,
                            onTap: () => _openScreen(
                              VotingScreen(tripId: trip.tripId),
                            ),
                          ),
                          _FeatureCard(
                            title: 'Expenses',
                            subtitle: 'Track shared costs',
                            icon: Icons.account_balance_wallet_rounded,
                            onTap: () => _openScreen(
                              ExpensesScreen(tripId: trip.tripId),
                            ),
                          ),
                          _FeatureCard(
                            title: 'Expense Summary',
                            subtitle: 'Review trip spending',
                            icon: Icons.receipt_long_rounded,
                            onTap: () => _openScreen(
                              ExpenseSummaryScreen(tripId: trip.tripId),
                            ),
                          ),
                          if (isOwner)
                            _FeatureCard(
                              title: 'Itinerary',
                              subtitle: 'Manage your schedule',
                              icon: Icons.calendar_month_rounded,
                              onTap: () => _openScreen(
                                ItineraryScreen(tripId: trip.tripId),
                              ),
                            ),
                          _FeatureCard(
                            title: 'Explore Map',
                            subtitle: 'Explore your trip destination',
                            icon: Icons.explore_rounded,
                            onTap: () => _openScreen(
                              MapScreen(destination: trip.destination),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      if (isOwner) ...[
                        const _SectionHeading(
                          title: 'Manage trip',
                          subtitle: 'Update your trip settings.',
                        ),
                        const SizedBox(height: 14),
                        _ManagementCard(
                          icon: Icons.edit_rounded,
                          title: 'Edit trip',
                          subtitle: 'Change your trip information',
                          onTap: _isDeleting ? null : () => _editTrip(trip),
                        ),
                        const SizedBox(height: 10),
                        _ManagementCard(
                          icon: Icons.delete_outline_rounded,
                          title: 'Delete trip',
                          subtitle: 'Permanently remove this trip',
                          isDestructive: true,
                          onTap: _isDeleting
                              ? null
                              : () => _deleteTrip(trip),
                          trailing: _isDeleting
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : null,
                        ),
                      ] else
                        const Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Text(
                            'Only the trip owner can edit or delete this trip.',
                            style: TextStyle(color: _mutedText),
                          ),
                        ),
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'Made for the journey. Powered by Voyage.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: _mutedText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TripHero extends StatelessWidget {
  const _TripHero({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            color: _purple.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -14,
            child: Icon(
              Icons.flight_takeoff_rounded,
              size: 115,
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
                  color: Colors.white.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.luggage_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'YOUR NEXT ADVENTURE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                trip.tripName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white70,
                    size: 19,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      trip.destination,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroPill(
                    icon: Icons.calendar_today_rounded,
                    text: formatTripDate(trip.startDate),
                  ),
                  _HeroPill(
                    icon: Icons.group_rounded,
                    text: trip.tripType.label,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _darkPurple,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: _mutedText,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _TripInformation extends StatelessWidget {
  const _TripInformation({
    required this.trip,
    required this.wide,
  });

  final Trip trip;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE8FA)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.login_rounded,
                  label: 'START DATE',
                  value: formatTripDate(trip.startDate),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.flag_rounded,
                  label: 'END DATE',
                  value: formatTripDate(trip.endDate),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 17),
            child: Divider(height: 1, color: Color(0xFFF0EDF7)),
          ),
          _OwnerInformation(
            tripId: trip.tripId,
            ownerId: trip.ownerId,
          ),
          if (trip.description?.isNotEmpty ?? false) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Divider(height: 1, color: Color(0xFFF0EDF7)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notes_rounded,
                  color: _purple,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TRIP DESCRIPTION',
                        style: TextStyle(
                          fontSize: 10,
                          color: _mutedText,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        trip.description!,
                        style: const TextStyle(
                          color: _darkPurple,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: const Color(0xFFF0EBFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _purple, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: _mutedText,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  color: _darkPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnerInformation extends StatelessWidget {
  const _OwnerInformation({
    required this.tripId,
    required this.ownerId,
  });

  final String tripId;
  final String ownerId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .doc(tripId)
          .collection('members')
          .doc(ownerId)
          .snapshots(),
      builder: (context, snapshot) {
        final name = snapshot.data?.data()?['name'];

        final ownerName = name is String && name.trim().isNotEmpty
            ? name.trim()
            : 'Trip owner';

        return Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EBFF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: _purple,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRIP ORGANIZER',
                    style: TextStyle(
                      fontSize: 10,
                      color: _mutedText,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Managed by',
                    style: TextStyle(
                      color: _mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Text(
                ownerName,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: _darkPurple,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEDE8FA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF0EBFF), Color(0xFFE5DCFF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _purple, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _darkPurple,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade600 : _purple;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDestructive
                  ? const Color(0xFFF5DCDC)
                  : const Color(0xFFEDE8FA),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: color,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsMessage extends StatelessWidget {
  const _DetailsMessage({
    required this.message,
    this.onRetry,
  });

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
            const Icon(
              Icons.explore_off_rounded,
              color: _purple,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _darkPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
