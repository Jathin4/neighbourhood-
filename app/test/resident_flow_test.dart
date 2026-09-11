import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnn_app/src/features/resident/data.dart';
import 'package:tnn_app/src/features/resident/shell.dart';
import 'package:tnn_app/src/shared/ticket_ui.dart';

void main() {
  group('ResidentController', () {
    late ProviderContainer c;
    setUp(() => c = ProviderContainer());
    tearDown(() => c.dispose());

    ResidentController ctrl() => c.read(residentProvider.notifier);
    ResidentData data() => c.read(residentProvider);

    test('seeds notices, issues, events and bookings', () {
      expect(data().notices, isNotEmpty);
      expect(data().issues, isNotEmpty);
      expect(data().events, isNotEmpty);
      expect(data().bookings, isNotEmpty);
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

    test('requesting a service adds a booking in Requested state', () {
      final before = data().bookings.length;
      ctrl().requestService(data().services.first);
      expect(data().bookings.length, before + 1);
      expect(data().bookings.first.statusLabel, 'Requested');
    });

    test('cancelling a booking removes it', () {
      ctrl().requestService(data().services.first);
      final id = data().bookings.first.id;
      ctrl().cancelBooking(id);
      expect(data().bookings.any((b) => b.id == id), isFalse);
    });

    test('confirming completion flips status to success', () {
      final awaiting = data().bookings.firstWhere((b) => b.statusLabel == 'Awaiting confirmation');
      ctrl().confirmCompletion(awaiting.id);
      final after = data().bookings.firstWhere((b) => b.id == awaiting.id);
      expect(after.status, TStatus.success);
      expect(after.statusLabel, 'Completed');
    });

    test('raising a support ticket prepends it', () {
      final before = data().support.length;
      ctrl().addSupportTicket('Refund not received');
      expect(data().support.length, before + 1);
      expect(data().support.first.subject, 'Refund not received');
    });
  });

  testWidgets('shell switches tabs and requesting a service creates a booking', (tester) async {
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

    await tester.tap(find.text('Request').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();
    expect(find.text('Requested'), findsOneWidget);
  });
}
