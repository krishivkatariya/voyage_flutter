import 'package:flutter/material.dart';
import 'package:voyage_flutter/models/trip_member.dart';

class MemberCard extends StatelessWidget {
  const MemberCard({
    required this.member,
    required this.canRemove,
    this.onRemove,
    super.key,
  });

  final TripMember member;
  final bool canRemove;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isOwner = member.role == 'owner';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(isOwner ? Icons.star_outline : Icons.person_outline),
        ),
        title: Text(member.name.isEmpty ? 'Voyage member' : member.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member.email?.isNotEmpty ?? false) Text(member.email!),
            const SizedBox(height: 4),
            Text(isOwner ? 'Owner' : 'Member'),
          ],
        ),
        isThreeLine: member.email?.isNotEmpty ?? false,
        trailing: canRemove && !isOwner
            ? IconButton(
                tooltip: 'Remove member',
                onPressed: onRemove,
                icon: const Icon(Icons.person_remove_outlined),
              )
            : null,
      ),
    );
  }
}
