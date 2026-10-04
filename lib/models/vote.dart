import 'package:cloud_firestore/cloud_firestore.dart';

class Vote {
  final String voterId;
  final DateTime votedAt;

  const Vote({required this.voterId, required this.votedAt});

  factory Vote.fromMap(Map<String, dynamic> map, {required String voterId}) {
    return Vote(voterId: voterId, votedAt: _readDate(map['votedAt']));
  }

  Map<String, dynamic> toMap() {
    return {'userId': voterId, 'votedAt': Timestamp.fromDate(votedAt)};
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
  throw FormatException('Invalid vote date: $value');
}
