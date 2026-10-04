import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyage_flutter/features/itinerary/widgets/activity_card.dart';
import 'package:voyage_flutter/models/activity.dart';

void main() {
  testWidgets('shows activity details and exposes edit/delete actions', (
    tester,
  ) async {
    final activity = Activity(
      activityId: 'activity-document-id',
      tripId: 'trip-document-id',
      title: 'Museum visit',
      placeName: 'City museum',
      date: DateTime(2026, 10, 15),
      startTime: '09:30',
      endTime: '11:00',
      description: 'Meet at the front entrance',
      createdBy: 'auth-user-id',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityCard(
            activity: activity,
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(find.text('Museum visit'), findsOneWidget);
    expect(find.text('City museum'), findsOneWidget);
    expect(find.text('15 Oct 2026'), findsOneWidget);
    expect(find.text('9:30 AM – 11:00 AM'), findsOneWidget);
    expect(find.text('Meet at the front entrance'), findsOneWidget);
    expect(find.byTooltip('Edit activity'), findsOneWidget);
    expect(find.byTooltip('Delete activity'), findsOneWidget);
  });
}
