import 'package:flutter/material.dart';

import '../../shared/role_scaffold.dart';

/// Committee members get configurable per-membership capabilities (§1) rather
/// than fixed screens — real assigned workflows land here once notices/issues/
/// polls/events ship (requirements §19).
class CommitteeMemberHome extends StatelessWidget {
  const CommitteeMemberHome({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      title: 'Committee Member',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          GreetingHeader(),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Assigned operational workflows — notices, issues, polls, events — '
                'show up here once your community admin grants specific capabilities. '
                'Nothing assigned yet.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
