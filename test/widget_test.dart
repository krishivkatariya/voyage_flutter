import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/itinerary/screens/itinerary_screen.dart';

void main() {
  testWidgets('Itinerary screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ItineraryScreen(tripId: 'trip01')),
    );

    expect(find.byType(ItineraryScreen), findsOneWidget);
  });
}
