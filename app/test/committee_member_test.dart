import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnn_app/src/features/committee_member/committee_member_home.dart';
import 'package:tnn_app/src/shared/my_memberships.dart';

Widget _committeeSection() => const Scaffold(
      body: SingleChildScrollView(child: CommitteeMembershipsSection()),
    );

MyMembership _membership({required List<String> caps, String role = 'committee_member'}) =>
    MyMembership(
      id: 'm1',
      communityId: 'c1',
      communityName: 'Green Meadows',
      role: role,
      status: 'active',
      verificationStatus: 'verified',
      capabilities: caps,
    );

Future<void> _pump(WidgetTester tester, List<MyMembership> memberships) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [myMembershipsProvider.overrideWith((ref) async => memberships)],
      child: MaterialApp(home: _committeeSection()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no committee membership shows the "nothing assigned" placeholder', (tester) async {
    await _pump(tester, [_membership(caps: [], role: 'resident')]);
    expect(find.textContaining('Nothing assigned yet'), findsOneWidget);
    expect(find.text('Manage members'), findsNothing);
  });

  testWidgets('a committee membership with no granted capabilities says so', (tester) async {
    await _pump(tester, [_membership(caps: [])]);
    expect(find.text('Green Meadows'), findsOneWidget);
    expect(find.textContaining('No capabilities granted yet'), findsOneWidget);
    expect(find.text('Manage members'), findsNothing);
  });

  testWidgets('only buttons for granted capabilities are shown', (tester) async {
    await _pump(tester, [
      _membership(caps: ['community.member.manage']),
    ]);
    expect(find.text('Manage members'), findsOneWidget);
    expect(find.text('Units'), findsNothing);
    expect(find.text('Import CSV'), findsNothing);
  });

  testWidgets('all three granted capabilities show all three buttons', (tester) async {
    await _pump(tester, [
      _membership(caps: [
        'community.member.manage',
        'community.unit.manage',
        'community.resident.import',
      ]),
    ]);
    expect(find.text('Manage members'), findsOneWidget);
    expect(find.text('Units'), findsOneWidget);
    expect(find.text('Import CSV'), findsOneWidget);
  });
}
