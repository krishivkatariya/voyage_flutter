import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/trips/screens/trip_details_screen.dart';
import 'package:voyage_flutter/features/trips/services/trip_service.dart';
import 'package:voyage_flutter/features/trips/widgets/trip_form.dart';
import 'package:voyage_flutter/models/trip.dart';

const Color _createPurple = Color(0xFF6D4AFF);
const Color _createDarkPurple = Color(0xFF38216D);
const Color _createBackground = Color(0xFFF8F7FC);

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
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _createBackground,
      appBar: AppBar(
        backgroundColor: _createBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Create Trip',
          style: TextStyle(
            color: _createDarkPurple,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: _createDarkPurple),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 750;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 32 : 18,
                  vertical: 18,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_createPurple, _createDarkPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -8,
                          top: -12,
                          child: Icon(
                            Icons.flight_takeoff_rounded,
                            size: 100,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Text(
                                'LET THE ADVENTURE BEGIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Where to next?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create your trip, choose your dates, '
                              'and bring your travel plans together.',
                              style: TextStyle(
                                color: Colors.white70,
                                height: 1.5,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(wide ? 26 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFEDE8FA)),
                      boxShadow: [
                        BoxShadow(
                          color: _createDarkPurple.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.edit_calendar_rounded,
                              color: _createPurple,
                              size: 25,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Trip information',
                                style: TextStyle(
                                  color: _createDarkPurple,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Fill in the details below to get started.',
                          style: TextStyle(
                            color: Color(0xFF77738A),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TripForm(
                          submitLabel: 'Create trip',
                          onSubmit: _createTrip,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Center(
                    child: Text(
                      'Your next great memory starts here. ✦',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF77738A), fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
