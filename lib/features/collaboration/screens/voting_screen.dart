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

  static const _background = Color(0xFFF7F6FC);

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

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Activity Voting',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4),
        ),
      ),
      body: SafeArea(
        top: false,
        child: userId == null
            ? const _VotingMessage(
                icon: Icons.lock_outline_rounded,
                title: 'Sign in to vote',
                message: 'Sign in before voting on trip activities.',
              )
            : FutureBuilder<bool>(
                future: _membershipFuture,
                builder: (context, membershipSnapshot) {
                  if (membershipSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const _VotingLoading();
                  }

                  if (membershipSnapshot.hasError) {
                    return _VotingMessage(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not check membership',
                      message: VotingService.userMessage(
                        membershipSnapshot.error!,
                      ),
                      buttonLabel: 'Try again',
                      onPressed: _retry,
                    );
                  }

                  if (membershipSnapshot.data != true) {
                    return const _VotingMessage(
                      icon: Icons.group_outlined,
                      title: 'Trip members only',
                      message: 'You must be a member of this trip to vote.',
                    );
                  }

                  return StreamBuilder<List<Activity>>(
                    stream: _activitiesStream,
                    builder: (context, activitiesSnapshot) {
                      if (activitiesSnapshot.hasError) {
                        return _VotingMessage(
                          icon: Icons.cloud_off_rounded,
                          title: 'Could not load activities',
                          message: ItineraryService.userMessage(
                            activitiesSnapshot.error!,
                          ),
                          buttonLabel: 'Try again',
                          onPressed: _retry,
                        );
                      }

                      if (!activitiesSnapshot.hasData) {
                        return const _VotingLoading();
                      }

                      final activities = activitiesSnapshot.data!;

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1000),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _VotingHeader(
                                    activityCount: activities.length,
                                  ),
                                  const SizedBox(height: 26),
                                  const Text(
                                    'Choose your favourites',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF25213A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Vote for the activities you want to do '
                                    'during your trip.',
                                    style: TextStyle(
                                      color: Color(0xFF77738A),
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  if (activities.isEmpty)
                                    const _VotingMessage(
                                      icon: Icons.event_note_rounded,
                                      title: 'Nothing to vote on yet',
                                      message:
                                          'Add activities to your itinerary '
                                          'before voting.',
                                    )
                                  else
                                    for (final activity in activities)
                                      _VotingActivityCard(
                                        key: ValueKey(activity.activityId),
                                        activity: activity,
                                        userId: userId,
                                        votingService: _votingService,
                                      ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _VotingHeader extends StatelessWidget {
  const _VotingHeader({required this.activityCount});

  final int activityCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Make your trip yours',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Help your group decide what to explore '
                  'together.',
                  style: TextStyle(
                    color: Color(0xFFEDE8FF),
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$activityCount ${activityCount == 1 ? 'activity' : 'activities'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.how_to_vote_rounded,
              color: Colors.white,
              size: 35,
            ),
          ),
        ],
      ),
    );
  }
}

class _VotingActivityCard extends StatefulWidget {
  const _VotingActivityCard({
    required this.activity,
    required this.userId,
    required this.votingService,
    super.key,
  });

  final Activity activity;
  final String userId;
  final VotingService votingService;

  @override
  State<_VotingActivityCard> createState() => _VotingActivityCardState();
}

class _VotingActivityCardState extends State<_VotingActivityCard> {
  bool _isSubmitting = false;

  static const _purple = Color(0xFF6548E8);

  Future<void> _toggleVote(bool hasVoted) async {
    if (_isSubmitting) return;

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
    final activity = widget.activity;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAE6F4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34236B).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0ECFF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.place_rounded,
                  color: _purple,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        color: Color(0xFF25213A),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Color(0xFF817B96),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity.placeName,
                            style: const TextStyle(
                              color: Color(0xFF77738A),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9FE),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: _purple,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ActivityValidators.formatDate(activity.date),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF49445E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.schedule_rounded, size: 17, color: _purple),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    '${activity.startTime} – ${activity.endTime}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF77738A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<VoteStatus>(
            stream: widget.votingService.watchVoteStatus(
              tripId: activity.tripId,
              activityId: activity.activityId,
              userId: widget.userId,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  VotingService.userMessage(snapshot.error!),
                  style: const TextStyle(color: Colors.redAccent),
                );
              }

              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 44,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _purple,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              final status = snapshot.data!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.thumb_up_alt_outlined,
                        size: 19,
                        color: _purple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${status.count} ${status.count == 1 ? 'vote' : 'votes'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF49445E),
                        ),
                      ),
                      const Spacer(),
                      if (status.hasVoted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE8FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: _purple,
                                size: 16,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Voted',
                                style: TextStyle(
                                  color: _purple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: status.hasVoted
                        ? OutlinedButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () => _toggleVote(true),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _purple,
                              side: const BorderSide(color: _purple),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.undo_rounded),
                            label: const Text('Remove vote'),
                          )
                        : FilledButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () => _toggleVote(false),
                            style: FilledButton.styleFrom(
                              backgroundColor: _purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.thumb_up_alt_rounded),
                            label: const Text('Vote for this activity'),
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VotingLoading extends StatelessWidget {
  const _VotingLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF6548E8)),
    );
  }
}

class _VotingMessage extends StatelessWidget {
  const _VotingMessage({
    required this.title,
    required this.message,
    this.icon = Icons.info_outline_rounded,
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEAE6F4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0ECFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: const Color(0xFF6548E8), size: 32),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF25213A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF77738A), height: 1.5),
                ),
                if (buttonLabel != null) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6548E8),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(buttonLabel!),
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
