import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnn_app/src/features/provider/data.dart';
import 'package:tnn_app/src/features/provider/shell.dart';
import 'package:tnn_app/src/shared/ticket_ui.dart';

void main() {
  group('PortalController', () {
    late ProviderContainer c;
    setUp(() => c = ProviderContainer());
    tearDown(() => c.dispose());

    PortalController ctrl() => c.read(portalProvider.notifier);
    PortalData data() => c.read(portalProvider);

    test('seeds four leads', () => expect(data().leads.length, 4));

    test('accepting a lead removes it from the inbox', () {
      final id = data().leads.first.id;
      ctrl().acceptLead(id);
      expect(data().leads.length, 3);
      expect(data().leads.any((l) => l.id == id), isFalse);
    });

    test('declining a lead removes it too', () {
      ctrl().declineLead(data().leads.first.id);
      expect(data().leads.length, 3);
    });

    test('reset restores the full lead list', () {
      ctrl()
        ..acceptLead(data().leads.first.id)
        ..acceptLead(data().leads.first.id);
      expect(data().leads.length, 2);
      ctrl().resetLeads();
      expect(data().leads.length, 4);
    });

    test('completing a job flips it to awaiting confirmation', () {
      final b = data().bookings.firstWhere((b) => b.status == TStatus.success);
      ctrl().completeJob(b.id);
      final after = data().bookings.firstWhere((x) => x.id == b.id);
      expect(after.statusLabel, 'Awaiting confirmation');
      expect(after.status, TStatus.amber);
    });

    test('replying to a review stores the reply', () {
      final i = data().reviews.indexWhere((r) => r.reply == null);
      ctrl().replyReview(i, 'Thanks!');
      expect(data().reviews[i].reply, 'Thanks!');
    });

    test('toggling an availability slot adds then removes it', () {
      expect(data().blockedSlots.contains('0-0'), isFalse);
      ctrl().toggleSlot('0-0');
      expect(data().blockedSlots.contains('0-0'), isTrue);
      ctrl().toggleSlot('0-0');
      expect(data().blockedSlots.contains('0-0'), isFalse);
    });

    test('raising a support ticket prepends it', () {
      final before = data().support.length;
      ctrl().addSupportTicket('Payout mismatch');
      expect(data().support.length, before + 1);
      expect(data().support.first.subject, 'Payout mismatch');
    });
  });

  testWidgets('shell switches tabs, accepts a lead, opens a pushed sub-screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProviderShell())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Needs your response'), findsOneWidget);

    await tester.tap(find.text('Leads'));
    await tester.pumpAndSettle();
    expect(find.text('Lead inbox'), findsOneWidget);
    expect(find.text('TNN-2K402'), findsOneWidget);

    await tester.tap(find.text('Accept').first);
    await tester.pumpAndSettle();
    expect(find.text('TNN-2K402'), findsNothing); // accepted lead left the inbox
    expect(find.text('TNN-2K403'), findsOneWidget); // the rest stay

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reviews & reputation'));
    await tester.pumpAndSettle();
    expect(find.text('Reviews'), findsWidgets);
    expect(find.byType(BackButton), findsOneWidget); // pushed screen has a back button
  });
}
