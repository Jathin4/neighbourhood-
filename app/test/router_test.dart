import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnn_app/src/core/router.dart';
import 'package:tnn_app/src/features/auth/auth_controller.dart';

/// Skips secure-storage-backed restore() so this runs with no platform channels.
class _FakeSignedInAuth extends AuthController {
  @override
  AuthStatus build() => AuthStatus.signedIn;
}

Future<void> _pump(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [authControllerProvider.overrideWith(_FakeSignedInAuth.new)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      // Mirrors main.dart: must *watch* routerProvider (not read once), since
      // it rebuilds a fresh GoRouter whenever auth/role state changes.
      child: Consumer(
        builder: (context, ref, _) =>
            MaterialApp.router(routerConfig: ref.watch(routerProvider)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('signed-in user with no role picked sees the role picker', (tester) async {
    await _pump(tester);
    expect(find.text('Continue as'), findsOneWidget);
    expect(find.text('Resident'), findsOneWidget);
    expect(find.text('Super Admin'), findsOneWidget);
  });

  testWidgets('picking a role routes to that role\'s home', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Super Admin'));
    await tester.pumpAndSettle();
    // AppBar title on SuperAdminHome (via RoleScaffold).
    expect(find.widgetWithText(AppBar, 'Super Admin'), findsOneWidget);
    expect(find.text('Continue as'), findsNothing);
  });

  testWidgets('service provider role lands on the provider tab shell', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Service Provider'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget); // ProviderShell's Home tab title
    expect(find.text('Needs your response'), findsOneWidget);
  });
}
