import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnn_app/src/features/super_admin/create_community_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CreateCommunityScreen())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('total units recomputes as towers/floors/flats change', (tester) async {
    await pump(tester);
    expect(find.text('Total units: 1'), findsOneWidget); // 1x1x1 default

    await tester.enterText(find.widgetWithText(TextField, 'Number of towers'), '3');
    await tester.enterText(find.widgetWithText(TextField, 'Floors per tower'), '4');
    await tester.enterText(find.widgetWithText(TextField, 'Flats per floor'), '2');
    await tester.pump();

    expect(find.text('Total units: 24'), findsOneWidget);
  });

  testWidgets('rejects an empty community name before hitting the network', (tester) async {
    await pump(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Create Community'));
    await tester.pump();
    expect(find.text('Community name is required.'), findsOneWidget);
  });
}
