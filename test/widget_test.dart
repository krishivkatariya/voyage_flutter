import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:voyage_flutter/screens/itinerary_screen.dart';

void main() {
  testWidgets('Itinerary screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ItineraryScreen()));

    expect(find.text('Gujarat Trip'), findsOneWidget);
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Visit Statue of Unity'), findsOneWidget);
  });
}
