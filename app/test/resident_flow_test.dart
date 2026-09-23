import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnn_app/src/features/resident/data.dart';
import 'package:tnn_app/src/features/resident/shell.dart';
import 'package:tnn_app/src/shared/community_content.dart';
import 'package:tnn_app/src/shared/marketplace.dart';
import 'package:tnn_app/src/shared/my_memberships.dart';

MyMembership _activeMembership({String communityId = 'c1', String communityName = 'Green Meadows'}) =>
    MyMembership(
      id: 'm1',
      communityId: communityId,
      communityName: communityName,
      role: 'resident',
      status: 'active',
      verificationStatus: 'verified',
      capabilities: const [],
    );

void main() {
  group('ResidentController', () {
    late ProviderContainer c;
    setUp(() => c = ProviderContainer());
    tearDown(() => c.dispose());

    ResidentController ctrl() => c.read(residentProvider.notifier);
    ResidentData data() => c.read(residentProvider);

    test('seeds a services catalog', () {
      expect(data().services, isNotEmpty);
    });

    test('raising a support ticket prepends it', () {
      final before = data().support.length;
      ctrl().addSupportTicket('Refund not received');
      expect(data().support.length, before + 1);
      expect(data().support.first.subject, 'Refund not received');
    });
  });

  testWidgets('with no active community, Home shows the "not part of a community" state',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [myActiveMembershipProvider.overrideWithValue(const AsyncData(null))],
        child: const MaterialApp(home: ResidentShell()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.textContaining('not part of a community'), findsOneWidget);

    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();
    expect(find.text('Electrician'), findsOneWidget);
  });

  testWidgets('Home renders live notices, issues and events for my community', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final membership = _activeMembership();
    final notice = CommunityNotice(
      id: 'n1',
      title: 'Water supply interruption',
      body: 'Maintenance work on the main line.',
      priority: 'critical',
      createdAt: DateTime(2026, 9, 22, 10),
      read: false,
    );
    final issue = CommunityIssue(
      id: 'i1',
      communityId: membership.communityId,
      raisedByName: 'Test Resident',
      category: 'issue',
      title: 'Lift making a grinding noise',
      status: 'in_progress',
      createdAt: DateTime(2026, 9, 20),
    );
    final event = CommunityEvent(
      id: 'e1',
      title: 'Diwali cultural night',
      startsAt: DateTime(2026, 10, 20, 19),
      location: 'Community hall',
      rsvpCount: 3,
      rsvped: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myActiveMembershipProvider.overrideWithValue(AsyncData(membership)),
          noticesProvider(membership.communityId).overrideWith((ref) async => [notice]),
          eventsProvider(membership.communityId).overrideWith((ref) async => [event]),
          myIssuesProvider.overrideWith((ref) async => [issue]),
        ],
        child: const MaterialApp(home: ResidentShell()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Water supply interruption'), findsOneWidget);
    expect(find.text('Lift making a grinding noise'), findsOneWidget);
    expect(find.text('Diwali cultural night'), findsOneWidget);
    expect(find.text('Mark as read'), findsOneWidget);
  });

  testWidgets('bookings tab renders a live (backend) booking with its status', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final booking = MarketBooking(
      id: 'b1',
      providerUserId: null,
      category: 'Electrician',
      title: 'Electrician',
      status: 'requested',
      createdAt: DateTime(2026, 9, 22, 16, 45),
      residentName: 'Test Resident',
      providerName: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [myBookingsProvider.overrideWith((ref) async => [booking])],
        child: const MaterialApp(home: ResidentShell()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();

    expect(find.text('Requested'), findsOneWidget);
    expect(find.text('Matching a verified provider…'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('an accepted booking shows the provider name and no cancel button', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final booking = MarketBooking(
      id: 'b1',
      providerUserId: 'p1',
      category: 'Electrician',
      title: 'Electrician',
      status: 'completed',
      createdAt: DateTime(2026, 9, 22, 16, 45),
      residentName: 'Test Resident',
      providerName: 'Ramesh Kumar Electricals',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [myBookingsProvider.overrideWith((ref) async => [booking])],
        child: const MaterialApp(home: ResidentShell()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Ramesh Kumar Electricals'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });
}
