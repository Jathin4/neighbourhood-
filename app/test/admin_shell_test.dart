import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnn_app/src/features/super_admin/admin_shell.dart';
import 'package:tnn_app/src/features/super_admin/audit_logs_page.dart';
import 'package:tnn_app/src/features/super_admin/users_page.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(ProviderScope(child: MaterialApp(home: child)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AuditLogsPage renders its real content (not a placeholder)', (tester) async {
    await _pump(tester, const AuditLogsPage());
    expect(find.text('Audit Logs'), findsOneWidget);
    expect(find.text('Actor, action, entity and timestamp for sensitive changes.'),
        findsOneWidget);
    expect(find.textContaining(' module'), findsNothing); // placeholder's own copy
  });

  testWidgets('UsersPage renders its real content and search controls', (tester) async {
    // Content-only widget (like DashboardPage) — hosted inside AdminShell's
    // own Scaffold in the real app; wrap it here to match.
    await _pump(tester, const Scaffold(body: UsersPage()));
    expect(find.text('All Users'), findsOneWidget);
    expect(find.text('Search, view, suspend or reactivate accounts.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('AdminShell boots on Dashboard by default', (tester) async {
    await _pump(tester, const AdminShell());
    expect(find.text('Super Admin Panel'), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
  });
}
