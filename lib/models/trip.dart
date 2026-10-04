import 'package:cloud_firestore/cloud_firestore.dart';

enum TripType {
  solo('Solo'),
  group('Group');

  const TripType(this.label);

  final String label;

  static TripType fromValue(Object? value) {
    if (value is String) {
      for (final type in TripType.values) {
        if (type.label.toLowerCase() == value.toLowerCase()) {
          return type;
        }
      }
    }

    throw FormatException('Invalid trip type: $value');
  }
}

class Trip {
  final String tripId;
  final String ownerId;
  final String tripName;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final TripType tripType;
  final String? description;

  const Trip({
    required this.tripId,
    required this.ownerId,
    required this.tripName,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.tripType,
    this.description,
  });

  factory Trip.fromMap(Map<String, dynamic> map, {required String tripId}) {
    return Trip(
      tripId: tripId,
      ownerId: map['ownerId'] as String,
      tripName: map['tripName'] as String,
      destination: map['destination'] as String,
      startDate: _readDateTime(map['startDate'], 'startDate'),
      endDate: _readDateTime(map['endDate'], 'endDate'),
      tripType: TripType.fromValue(map['tripType']),
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'tripName': tripName,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'tripType': tripType.label,
      'description': description,
    };
  }
}

DateTime _readDateTime(Object? value, String fieldName) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.parse(value);
  }

  throw FormatException('Invalid date value for $fieldName: $value');
}
