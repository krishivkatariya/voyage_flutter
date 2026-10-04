import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/itinerary/services/activity_validators.dart';
import 'package:voyage_flutter/models/activity.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    required this.activity,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Activity activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final start = ActivityValidators.parseTime(activity.startTime);
    final end = ActivityValidators.parseTime(activity.endTime);
    final timeLabel = start == null || end == null
        ? '${activity.startTime} – ${activity.endTime}'
        : '${start.format(context)} – ${end.format(context)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(activity.placeName),
                  const SizedBox(height: 4),
                  Text(ActivityValidators.formatDate(activity.date)),
                  const SizedBox(height: 4),
                  Text(timeLabel),
                  if (activity.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    Text(activity.description!),
                  ],
                  if (activity.latitude != null &&
                      activity.longitude != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${activity.latitude}, ${activity.longitude}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: 'Edit activity',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete activity',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
