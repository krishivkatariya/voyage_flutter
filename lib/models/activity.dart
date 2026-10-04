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
}
