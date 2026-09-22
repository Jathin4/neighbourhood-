import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnn_app/src/features/auth/email_login_screen.dart';
import 'package:tnn_app/src/features/auth/otp_screen.dart';
import 'package:tnn_app/src/features/auth/phone_screen.dart';
import 'package:tnn_app/src/shared/role.dart';

void main() {
  group('PhoneScreen', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [roleProvider.overrideWith((ref) => AppRole.resident)],
          child: const MaterialApp(home: PhoneScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the selected role as a badge', (tester) async {
      await pump(tester);
      expect(find.text('Resident'), findsOneWidget);
      expect(find.text('Verify your number'), findsOneWidget);
    });

    testWidgets('Send OTP stays disabled until 10 digits are entered', (tester) async {
      await pump(tester);
      final sendButton = find.widgetWithText(FilledButton, 'Send OTP');
      expect(tester.widget<FilledButton>(sendButton).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '+91 98765432');
      await tester.pump();
      expect(tester.widget<FilledButton>(sendButton).onPressed, isNull); // only 8 digits

      await tester.enterText(find.byType(TextField), '+91 9876543210');
      await tester.pump();
      expect(tester.widget<FilledButton>(sendButton).onPressed, isNotNull);
    });

    testWidgets('the +91 prefix never duplicates while typing', (tester) async {
      await pump(tester);
      final field = find.byType(TextField);
      await tester.enterText(field, '+91 9');
      await tester.pump();
      await tester.enterText(field, '+91 91');
      await tester.pump();
      // Regression check: the formatter used to re-extract digits from the
      // whole string including the fixed "+91" prefix, producing "+91 9191".
      final value = tester.widget<TextField>(field).controller!.text;
      expect(value, '+91 91');
    });
  });

  group('OtpScreen', () {
    testWidgets('pre-fills from the dev debug code and enables Verify', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [roleProvider.overrideWith((ref) => AppRole.superAdmin)],
          child: const MaterialApp(
            home: OtpScreen(mobile: '+919398391265', debugCode: '123456'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Super Admin'), findsOneWidget);
      expect(find.text('Dev code: 123456'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget); // back to the phone screen
      final verifyButton = find.widgetWithText(FilledButton, 'Verify & continue');
      expect(tester.widget<FilledButton>(verifyButton).onPressed, isNotNull);
    });

    testWidgets('Verify stays disabled until all 6 boxes are filled', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OtpScreen(mobile: '+919398391265')),
        ),
      );
      await tester.pumpAndSettle();

      final verifyButton = find.widgetWithText(FilledButton, 'Verify & continue');
      expect(tester.widget<FilledButton>(verifyButton).onPressed, isNull);

      final boxes = find.byType(TextField);
      for (var i = 0; i < 5; i++) {
        await tester.enterText(boxes.at(i), '1');
      }
      await tester.pump();
      expect(tester.widget<FilledButton>(verifyButton).onPressed, isNull); // only 5 of 6

      await tester.enterText(boxes.at(5), '1');
      await tester.pump();
      expect(tester.widget<FilledButton>(verifyButton).onPressed, isNotNull);
    });
  });

  group('EmailLoginScreen', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [roleProvider.overrideWith((ref) => AppRole.superAdmin)],
          child: const MaterialApp(home: EmailLoginScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the Super Admin badge and back button', (tester) async {
      await pump(tester);
      expect(find.text('Super Admin'), findsOneWidget);
      expect(find.text('Staff sign in'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Continue stays disabled until both fields are filled', (tester) async {
      await pump(tester);
      final button = find.widgetWithText(FilledButton, 'Continue');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, 'admin@tnnetwork.in');
      await tester.pump();
      expect(tester.widget<FilledButton>(button).onPressed, isNull); // password still empty

      await tester.enterText(find.byType(TextField).last, 'secret');
      await tester.pump();
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    });
  });
}
