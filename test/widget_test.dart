import 'package:flutter_test/flutter_test.dart';
import 'package:voyage_flutter/main.dart';

void main() {
  testWidgets('Itinerary screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const VoyageApp());

    expect(find.text('Gujarat Trip'), findsOneWidget);
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Visit Statue of Unity'), findsOneWidget);
  });
}