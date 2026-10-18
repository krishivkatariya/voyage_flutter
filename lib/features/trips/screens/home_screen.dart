
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/auth/services/auth_service.dart';
import 'package:voyage_flutter/features/trips/screens/create_trip_screen.dart';
import 'package:voyage_flutter/features/trips/screens/trips_screen.dart';
import 'package:voyage_flutter/features/trips/services/trip_service.dart';
import 'package:voyage_flutter/models/trip.dart';

const Color _purple = Color(0xFF6D4AFF);
const Color _darkPurple = Color(0xFF38216D);
const Color _background = Color(0xFFF8F7FC);
const Color _mutedText = Color(0xFF77738A);

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.user,
    required this.authService,
    super.key,
  });

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

    _tripsStream = TripService().getUserTrips(
      ownerId: widget.user.uid,
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);

    try {
      await widget.authService.logoutUser();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(AuthService.errorMessage(error)),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  void _openCreateTrip() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CreateTripScreen(),
      ),
    );
  }

  void _openTrips() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TripsScreen(),
      ),
    );
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 76,
        titleSpacing: 22,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_purple, _darkPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.explore_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voyage',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                    color: Color(0xFF241B35),
                    letterSpacing: -0.6,
                  ),
                ),
                Text(
                  'YOUR NEXT ADVENTURE',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.4,
                    color: _mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              tooltip: 'Log out',
              onPressed: _isLoggingOut ? null : _logout,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _darkPurple,
                side: const BorderSide(
                  color: Color(0xFFECE8F5),
                ),
                fixedSize: const Size(46, 46),
              ),
              icon: _isLoggingOut
                  ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.logout_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final horizontalPadding = isWide ? 40.0 : 20.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1180,
                ),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    18,
                    horizontalPadding,
                    36,
                  ),
                  children: [
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: _profileStream,
                      builder: (context, snapshot) {
                        final nameValue = snapshot.data?.data()?['name'];

                        final name =
                        nameValue is String &&
                            nameValue.trim().isNotEmpty
                            ? nameValue.trim()
                            : widget.user.email?.split('@').first ??
                            'Traveler';

                        return _WelcomeHero(
                          name: name,
                          isWide: isWide,
                          onCreateTrip: _openCreateTrip,
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    const _SectionHeading(
                      title: 'Your travel overview',
                      subtitle: 'A little progress, a lot of memories.',
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<Trip>>(
                      stream: _tripsStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _DashboardCounts(
                            message: TripService.userMessage(
                              snapshot.error!,
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(28),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          );
                        }

                        final today = DateTime.now();
                        final todayStart = DateTime(
                          today.year,
                          today.month,
                          today.day,
                        );

                        final trips = snapshot.data!;

                        final upcomingCount = trips.where((trip) {
                          return !_dateOnly(trip.endDate)
                              .isBefore(todayStart);
                        }).length;

                        final completedCount = trips.where((trip) {
                          return _dateOnly(trip.endDate)
                              .isBefore(todayStart);
                        }).length;

                        return Row(
                          children: [
                            Expanded(
                              child: _CountCard(
                                label: 'Upcoming trips',
                                count: upcomingCount,
                                icon: Icons.flight_takeoff_rounded,
                                accent: _purple,
                                background: const Color(0xFFF0EBFF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CountCard(
                                label: 'Completed trips',
                                count: completedCount,
                                icon: Icons.check_circle_outline_rounded,
                                accent: const Color(0xFF168A68),
                                background: const Color(0xFFE4F7EF),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    _SectionHeading(
                      title: 'Your journeys',
                      subtitle: 'Everything starts with a destination.',
                      trailing: TextButton(
                        onPressed: _openTrips,
                        child: const Text('View all'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, sectionConstraints) {
                        final wide = sectionConstraints.maxWidth >= 620;

                        final myTripsCard = _ActionCard(
                          icon: Icons.luggage_rounded,
                          title: 'My Trips',
                          description:
                          'Explore and manage your journeys.',
                          buttonLabel: 'View my trips',
                          iconBackground: const Color(0xFFECE6FF),
                          iconColor: _purple,
                          onTap: _openTrips,
                        );

                        final createTripCard = _ActionCard(
                          icon: Icons.add_location_alt_rounded,
                          title: 'Plan a trip',
                          description:
                          'Create a new adventure, your way.',
                          buttonLabel: 'Start planning',
                          iconBackground: const Color(0xFFFFEEDB),
                          iconColor: const Color(0xFFC57A23),
                          onTap: _openCreateTrip,
                        );

                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: myTripsCard),
                              const SizedBox(width: 18),
                              Expanded(child: createTripCard),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            myTripsCard,
                            const SizedBox(height: 14),
                            createTripCard,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFECE8F5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0EBFF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: _purple,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Signed in as',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _mutedText,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.user.email ?? 'Signed in',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF302944),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF168A68),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'MADE FOR THE JOURNEY',
                        style: TextStyle(
                          color: Color(0xFFAAA4BA),
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({
    required this.name,
    required this.isWide,
    required this.onCreateTrip,
  });

  final String name;
  final bool isWide;
  final VoidCallback onCreateTrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: EdgeInsets.all(isWide ? 32 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7655F5),
            Color(0xFF5734C9),
            Color(0xFF39216F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.20),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: -24,
            child: Icon(
              Icons.explore_rounded,
              size: isWide ? 190 : 145,
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          Positioned(
            right: isWide ? 30 : 8,
            bottom: -15,
            child: Icon(
              Icons.flight_rounded,
              size: isWide ? 105 : 75,
              color: Colors.white.withValues(alpha: 0.13),
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
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wb_sunny_outlined,
                      color: Colors.white,
                      size: 15,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'YOUR NEXT CHAPTER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Ready to explore,\n$name?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWide ? 34 : 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your next great memory starts here.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onCreateTrip,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Plan a new trip'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _darkPurple,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 19,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
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
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: Color(0xFF28213B),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _mutedText,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.accent,
    required this.background,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFECE8F5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38216D).withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 23,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF28213B),
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: _mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFECE8F5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38216D).withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 26,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF28213B),
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            style: const TextStyle(
              color: _mutedText,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 45),
                foregroundColor: _purple,
                side: const BorderSide(
                  color: Color(0xFFDCD2FF),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCounts extends StatelessWidget {
  const _DashboardCounts({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFECE8F5),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: _mutedText,
          height: 1.5,
        ),
      ),
    );
  }
}
