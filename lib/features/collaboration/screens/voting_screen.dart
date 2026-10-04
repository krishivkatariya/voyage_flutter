import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/collaboration/services/voting_service.dart';
import 'package:voyage_flutter/features/itinerary/services/activity_validators.dart';
import 'package:voyage_flutter/features/itinerary/services/itinerary_service.dart';
import 'package:voyage_flutter/models/activity.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({required this.tripId, super.key});

  final String tripId;

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  final _votingService = VotingService();
  final _itineraryService = ItineraryService();
  late Stream<List<Activity>> _activitiesStream;
  Future<bool>? _membershipFuture;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _activitiesStream = _itineraryService.getActivities(tripId: widget.tripId);
    _loadMembership();
  }

  void _loadMembership() {
    _userId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    _membershipFuture = _userId == null
        ? null
        : _votingService.isTripMember(tripId: widget.tripId, userId: _userId!);
  }

  void _retry() {
    setState(() {
      _activitiesStream = _itineraryService.getActivities(
        tripId: widget.tripId,
      );
      _loadMembership();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Activity Voting')),
        body: const _VotingMessage(message: 'Sign in before voting.'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Voting')),
      body: FutureBuilder<bool>(
        future: _membershipFuture,
        builder: (context, membershipSnapshot) {
          if (membershipSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (membershipSnapshot.hasError) {
            return _VotingMessage(
              message: VotingService.userMessage(membershipSnapshot.error!),
              buttonLabel: 'Retry',
              onPressed: _retry,
            );
          }
          if (membershipSnapshot.data != true) {
            return const _VotingMessage(
              message: 'You must be a member of this trip to vote.',
            );
          }

          return StreamBuilder<List<Activity>>(
            stream: _activitiesStream,
            builder: (context, activitiesSnapshot) {
              if (activitiesSnapshot.hasError) {
                return _VotingMessage(
                  message: ItineraryService.userMessage(
                    activitiesSnapshot.error!,
                  ),
                  buttonLabel: 'Retry',
                  onPressed: _retry,
                );
              }
              if (!activitiesSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final activities = activitiesSnapshot.data!;
              if (activities.isEmpty) {
                return const _VotingMessage(
                  message: 'There are no activities to vote on yet.',
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final activity in activities)
                    _VotingActivityCard(
                      activity: activity,
                      userId: userId,
                      votingService: _votingService,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _VotingActivityCard extends StatefulWidget {
  const _VotingActivityCard({
    required this.activity,
    required this.userId,
    required this.votingService,
  });

  final Activity activity;
  final String userId;
  final VotingService votingService;

  @override
  State<_VotingActivityCard> createState() => _VotingActivityCardState();
}

class _VotingActivityCardState extends State<_VotingActivityCard> {
  bool _isSubmitting = false;

  Future<void> _toggleVote(bool hasVoted) async {
    if (_isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      if (hasVoted) {
        await widget.votingService.removeVote(
          tripId: widget.activity.tripId,
          activityId: widget.activity.activityId,
        );
      } else {
        await widget.votingService.addVote(
          tripId: widget.activity.tripId,
          activityId: widget.activity.activityId,
        );
      }
      if (mounted) {
        _showMessage(hasVoted ? 'Vote removed.' : 'Vote added.');
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage(VotingService.userMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            Text(
              '${ActivityValidators.formatDate(activity.date)} · '
              '${activity.startTime} – ${activity.endTime}',
            ),
            const SizedBox(height: 12),
            StreamBuilder<VoteStatus>(
              stream: widget.votingService.watchVoteStatus(
                tripId: activity.tripId,
                activityId: activity.activityId,
                userId: widget.userId,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(VotingService.userMessage(snapshot.error!));
                }
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 40,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final status = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.thumb_up_alt_outlined, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '${status.count} '
                          '${status.count == 1 ? 'vote' : 'votes'}',
                        ),
                        const Spacer(),
                        if (status.hasVoted)
                          const Chip(
                            avatar: Icon(Icons.check, size: 16),
                            label: Text('Voted'),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: status.hasVoted
                          ? TextButton.icon(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => _toggleVote(true),
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.undo),
                              label: const Text('Remove Vote'),
                            )
                          : OutlinedButton.icon(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => _toggleVote(false),
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.thumb_up_alt_outlined),
                              label: const Text('Vote'),
                            ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VotingMessage extends StatelessWidget {
  const _VotingMessage({
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (buttonLabel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onPressed, child: Text(buttonLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
