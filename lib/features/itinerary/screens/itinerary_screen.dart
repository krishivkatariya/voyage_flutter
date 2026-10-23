import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/itinerary/screens/add_activity_screen.dart';
import 'package:voyage_flutter/features/itinerary/screens/edit_activity_screen.dart';
import 'package:voyage_flutter/features/itinerary/services/itinerary_service.dart';
import 'package:voyage_flutter/features/itinerary/services/activity_validators.dart';
import 'package:voyage_flutter/features/itinerary/widgets/activity_card.dart';
import 'package:voyage_flutter/models/activity.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({required this.tripId, super.key});

  final String tripId;

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  final _itineraryService = ItineraryService();

  late Stream<List<Activity>> _activitiesStream;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() {
    _activitiesStream = _itineraryService.getActivities(tripId: widget.tripId);
  }

  Future<void> _addActivity() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddActivityScreen(tripId: widget.tripId),
      ),
    );

    if (added == true && mounted) {
      _showMessage('Activity added successfully.');
    }
  }

  Future<void> _editActivity(Activity activity) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditActivityScreen(
          tripId: widget.tripId,
          activityId: activity.activityId,
        ),
      ),
    );

    if (updated == true && mounted) {
      _showMessage('Activity updated successfully.');
    }
  }

  Future<void> _deleteActivity(Activity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.redAccent,
          size: 32,
        ),
        title: const Text('Delete activity?'),
        content: Text(
          'Are you sure you want to delete "${activity.title}" '
          'from your itinerary?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _itineraryService.deleteActivity(
        tripId: widget.tripId,
        activityId: activity.activityId,
      );

      if (mounted) {
        _showMessage('Activity deleted successfully.');
      }
    } on ItineraryServiceException catch (error) {
      _showMessage(error.message);
    } on Object catch (error) {
      _showMessage(ItineraryService.userMessage(error));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F6FC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'My Itinerary',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
      ),
      body: StreamBuilder<List<Activity>>(
        stream: _activitiesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ItineraryMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Unable to load itinerary',
              message: ItineraryService.userMessage(snapshot.error!),
              buttonLabel: 'Try again',
              onPressed: () {
                setState(_loadActivities);
              },
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: colors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Preparing your itinerary...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final activities = snapshot.data!;

          final groupedActivities = <DateTime, List<Activity>>{};

          for (final activity in activities) {
            final day = DateTime(
              activity.date.year,
              activity.date.month,
              activity.date.day,
            );

            groupedActivities.putIfAbsent(day, () => []).add(activity);
          }

          final days = groupedActivities.keys.toList()..sort();

          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth > 700
                  ? 32.0
                  : 18.0;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      110,
                    ),
                    children: [
                      _ItineraryHeader(
                        activityCount: activities.length,
                        dayCount: days.length,
                      ),
                      const SizedBox(height: 30),
                      if (activities.isEmpty)
                        _ItineraryMessage(
                          icon: Icons.luggage_outlined,
                          title: 'Your journey starts here',
                          message:
                              'Plan your trip one activity at a time. '
                              'Add places to visit, meals, and experiences '
                              'to build your itinerary.',
                          buttonLabel: 'Add your first activity',
                          onPressed: _addActivity,
                        )
                      else ...[
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              color: colors.primary,
                              size: 23,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Your schedule',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        for (
                          int dayIndex = 0;
                          dayIndex < days.length;
                          dayIndex++
                        ) ...[
                          _DaySectionHeader(
                            dayNumber: dayIndex + 1,
                            date: days[dayIndex],
                            activityCount:
                                groupedActivities[days[dayIndex]]!.length,
                          ),
                          const SizedBox(height: 12),
                          ...groupedActivities[days[dayIndex]]!.map(
                            (activity) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ActivityCard(
                                activity: activity,
                                onEdit: () => _editActivity(activity),
                                onDelete: () => _deleteActivity(activity),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addActivity,
        elevation: 4,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Activity',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ItineraryHeader extends StatelessWidget {
  const _ItineraryHeader({required this.activityCount, required this.dayCount});

  final int activityCount;
  final int dayCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6548E8), Color(0xFF8B72F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6548E8).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Make every moment count.',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All your plans, places, and experiences in one place.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _HeaderStat(
                  icon: Icons.event_note_rounded,
                  value: '$activityCount',
                  label: activityCount == 1 ? 'Activity' : 'Activities',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderStat(
                  icon: Icons.calendar_today_rounded,
                  value: '$dayCount',
                  label: dayCount == 1 ? 'Travel day' : 'Travel days',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 23),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySectionHeader extends StatelessWidget {
  const _DaySectionHeader({
    required this.dayNumber,
    required this.date,
    required this.activityCount,
  });

  final int dayNumber;
  final DateTime date;
  final int activityCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final dateLabel = ActivityValidators.formatDate(date);
    final countLabel = activityCount == 1
        ? '1 activity'
        : '$activityCount activities';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$dayNumber',
            style: TextStyle(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Day $dayNumber',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                dateLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            countLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ItineraryMessage extends StatelessWidget {
  const _ItineraryMessage({
    required this.message,
    required this.title,
    required this.icon,
    this.buttonLabel,
    this.onPressed,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(icon, size: 38, color: colors.onPrimaryContainer),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
                if (buttonLabel != null) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(buttonLabel!),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 15,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
