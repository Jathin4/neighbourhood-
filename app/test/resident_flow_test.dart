import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnn_app/src/features/resident/data.dart';
import 'package:tnn_app/src/features/resident/shell.dart';
import 'package:tnn_app/src/shared/marketplace.dart';
import 'package:tnn_app/src/shared/ticket_ui.dart';

void main() {
  group('ResidentController', () {
    late ProviderContainer c;
    setUp(() => c = ProviderContainer());
    tearDown(() => c.dispose());

    ResidentController ctrl() => c.read(residentProvider.notifier);
    ResidentData data() => c.read(residentProvider);

    test('seeds notices, issues and events', () {
      expect(data().notices, isNotEmpty);
      expect(data().issues, isNotEmpty);
      expect(data().events, isNotEmpty);
    });

    test('marking a notice read flips its read flag only', () {
      final id = data().notices.first.id;
      ctrl().markNoticeRead(id);
      expect(data().notices.firstWhere((n) => n.id == id).read, isTrue);
    });

    test('raising an issue prepends a new open ticket', () {
      final before = data().issues.length;
      ctrl().raiseIssue('Plumbing', 'Leaking pipe');
      expect(data().issues.length, before + 1);
      expect(data().issues.first.title, 'Leaking pipe');
      expect(data().issues.first.status, TStatus.blue);
    });

    test('reopening a resolved issue flips it back to open', () {
      final resolved = data().issues.firstWhere((i) => i.status == TStatus.success);
      ctrl().reopenIssue(resolved.id);
      final after = data().issues.firstWhere((i) => i.id == resolved.id);
      expect(after.statusLabel, 'Reopened');
      expect(after.status, TStatus.blue);
    });

    test('toggling RSVP flips and flips back', () {
      final id = data().events.first.id;
      final was = data().events.first.rsvped;
      ctrl().toggleRsvp(id);
      expect(data().events.first.rsvped, !was);
      ctrl().toggleRsvp(id);
      expect(data().events.first.rsvped, was);
    });

    test('raising a support ticket prepends it', () {
      final before = data().support.length;
      ctrl().addSupportTicket('Refund not received');
      expect(data().support.length, before + 1);
      expect(data().support.first.subject, 'Refund not received');
    });
  });

  testWidgets('shell switches tabs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ResidentShell())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Notices'), findsWidgets);

    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();
    expect(find.text('Electrician'), findsOneWidget);
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
