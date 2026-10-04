import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyage_flutter/features/trips/widgets/trip_card.dart';
import 'package:voyage_flutter/models/trip.dart';

void main() {
  testWidgets('shows trip details and opens when tapped', (tester) async {
    var tapped = false;
    final trip = Trip(
      tripId: 'generated-document-id',
      ownerId: 'auth-user-id',
      tripName: 'Rome weekend',
      destination: 'Rome',
      startDate: DateTime(2026, 10, 8),
      endDate: DateTime(2026, 10, 10),
      tripType: TripType.solo,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripCard(trip: trip, onTap: () => tapped = true),
        ),
      ),
    );

    expect(find.text('Rome weekend'), findsOneWidget);
    expect(find.text('Rome'), findsOneWidget);
    expect(find.text('Oct 8, 2026 – Oct 10, 2026'), findsOneWidget);
    expect(find.text('Solo'), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    expect(tapped, isTrue);
  });
}
