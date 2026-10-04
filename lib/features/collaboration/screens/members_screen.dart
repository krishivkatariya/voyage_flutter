import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/collaboration/services/collaboration_service.dart';
import 'package:voyage_flutter/features/collaboration/widgets/add_member_form.dart';
import 'package:voyage_flutter/features/collaboration/widgets/member_card.dart';
import 'package:voyage_flutter/models/trip_member.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({required this.tripId, super.key});

  final String tripId;

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _collaborationService = CollaborationService();
  late Future<List<TripMember>> _membersFuture;
  bool _isRemovingMember = false;

  @override
  void initState() {
    super.initState();
    _membersFuture = _loadMembers();
  }

  Future<List<TripMember>> _loadMembers() {
    return _collaborationService.getMembers(tripId: widget.tripId);
  }

  void _refreshMembers() {
    setState(() => _membersFuture = _loadMembers());
  }

  Future<void> _addMember() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => AddMemberForm(
        collaborationService: _collaborationService,
        tripId: widget.tripId,
      ),
    );
    if (added == true && mounted) {
      _refreshMembers();
      _showMessage('Member added to the trip.');
    }
  }

  Future<void> _removeMember(TripMember member) async {
    if (_isRemovingMember || member.role == 'owner') {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('Remove ${member.name} from this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isRemovingMember = true);
    try {
      await _collaborationService.removeMember(
        tripId: widget.tripId,
        userId: member.userId,
      );
      if (mounted) {
        _refreshMembers();
        _showMessage('Member removed from the trip.');
      }
    } on Object catch (error) {
      _showMessage(CollaborationService.userMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isRemovingMember = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Members')),
      body: FutureBuilder<List<TripMember>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MembersMessage(
              message: CollaborationService.userMessage(snapshot.error!),
              buttonLabel: 'Retry',
              onPressed: _refreshMembers,
            );
          }

          final members = snapshot.data ?? const <TripMember>[];
          if (members.isEmpty) {
            return _MembersMessage(
              message: 'There are no members to display.',
              buttonLabel: 'Retry',
              onPressed: _refreshMembers,
            );
          }

          final owner = members.firstWhere(
            (member) => member.role == 'owner',
            orElse: () => members.first,
          );
          final isOwner = owner.userId == currentUserId;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final member in members)
                MemberCard(
                  member: member,
                  canRemove:
                      isOwner &&
                      !_isRemovingMember &&
                      member.role != 'owner' &&
                      member.userId != currentUserId,
                  onRemove: () => _removeMember(member),
                ),
              if (!isOwner)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Only the trip owner can add or remove members.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<List<TripMember>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          final members = snapshot.data;
          final currentUserId =
              firebase_auth.FirebaseAuth.instance.currentUser?.uid;
          final isOwner =
              members?.any(
                (member) =>
                    member.userId == currentUserId && member.role == 'owner',
              ) ??
              false;
          if (!isOwner) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: _isRemovingMember ? null : _addMember,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add Member'),
          );
        },
      ),
    );
  }
}

class _MembersMessage extends StatelessWidget {
  const _MembersMessage({
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
