import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String activityId;
  final String tripId;
  final String title;
  final String placeName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String createdBy;

  const Activity({
    required this.activityId,
    required this.tripId,
    required this.title,
    required this.placeName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.description,
    this.latitude,
    this.longitude,
    required this.createdBy,
  });

  factory Activity.fromMap(
    Map<String, dynamic> map, {
    required String activityId,
    required String tripId,
  }) {
    return Activity(
      activityId: activityId,
      tripId: tripId,
      title: map['title'] as String,
      placeName: map['placeName'] as String,
      date: _readDate(map['date']),
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      description: map['description'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdBy: map['createdBy'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'placeName': placeName,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'createdBy': createdBy,
    };
  }
}

DateTime _readDate(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.parse(value);
  }
  throw FormatException('Invalid activity date: $value');
}
