import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/itinerary/services/activity_validators.dart';
import 'package:voyage_flutter/features/itinerary/services/itinerary_service.dart';
import 'package:voyage_flutter/features/itinerary/widgets/activity_form.dart';
import 'package:voyage_flutter/models/activity.dart';

class EditActivityScreen extends StatefulWidget {
  const EditActivityScreen({
    required this.tripId,
    required this.activityId,
    super.key,
  });

  final String tripId;
  final String activityId;

  @override
  State<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends State<EditActivityScreen> {
  final _itineraryService = ItineraryService();

  late Future<Activity?> _activityFuture;

  @override
  void initState() {
    super.initState();
    _activityFuture = _loadActivity();
  }

  Future<Activity?> _loadActivity() async {
    final activity = await _itineraryService.getActivity(
      tripId: widget.tripId,
      activityId: widget.activityId,
    );

    if (activity != null && activity.tripId != widget.tripId) {
      throw const ItineraryServiceException(
        'This activity does not belong to the selected trip.',
      );
    }

    return activity;
  }

  Future<void> _updateActivity(
    Activity activity, {
    required String title,
    required String placeName,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await _itineraryService.updateActivity(
        activity: Activity(
          activityId: activity.activityId,
          tripId: widget.tripId,
          title: title.trim(),
          placeName: placeName.trim(),
          date: date,
          startTime: ActivityValidators.serializeTime(startTime),
          endTime: ActivityValidators.serializeTime(endTime),
          description: description,
          latitude: latitude,
          longitude: longitude,
          createdBy: activity.createdBy,
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ItineraryServiceException catch (error) {
      _showError(error.message);
    } on Object catch (error) {
      _showError(ItineraryService.userMessage(error));
    }
  }

  void _showError(String message) {
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
          'Edit Activity',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.4),
        ),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<Activity?>(
          future: _activityFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: colors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Loading activity details...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return _EditActivityMessage(
                icon: Icons.cloud_off_rounded,
                title: 'Unable to load activity',
                message: ItineraryService.userMessage(snapshot.error!),
                onRetry: () {
                  setState(() {
                    _activityFuture = _loadActivity();
                  });
                },
              );
            }

            final activity = snapshot.data;

            if (activity == null) {
              return const _EditActivityMessage(
                icon: Icons.event_busy_rounded,
                title: 'Activity not found',
                message: 'This activity no longer exists.',
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth > 700
                    ? 32.0
                    : 18.0;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 850),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        18,
                        horizontalPadding,
                        36,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6548E8), Color(0xFF8B72F4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.edit_calendar_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Update your plans',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.5,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Adjust the details to keep your '
                                        'journey up to date.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.88,
                                              ),
                                              height: 1.45,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Activity details',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Make your changes below and save when ready.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: colors.outlineVariant.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.025),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ActivityForm(
                              initialActivity: activity,
                              submitLabel: 'Save changes',
                              onSubmit:
                                  ({
                                    required title,
                                    required placeName,
                                    required date,
                                    required startTime,
                                    required endTime,
                                    description,
                                    latitude,
                                    longitude,
                                  }) => _updateActivity(
                                    activity,
                                    title: title,
                                    placeName: placeName,
                                    date: date,
                                    startTime: startTime,
                                    endTime: endTime,
                                    description: description,
                                    latitude: latitude,
                                    longitude: longitude,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EditActivityMessage extends StatelessWidget {
  const _EditActivityMessage({
    required this.title,
    required this.message,
    required this.icon,
    this.onRetry,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: colors.primary),
                const SizedBox(height: 18),
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
                    height: 1.5,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
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
