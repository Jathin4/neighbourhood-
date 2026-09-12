import 'package:flutter/material.dart';

// One brand palette for the whole app (matches shared/auth_ui.dart's LC.*
// used by the login flow) so every role — Community Admin, Committee Member
// and Platform Ops included, which lean on this ambient theme instead of a
// bespoke design system — reads as the same product.
const _brandAccent = Color(0xFF2F5D3A);
const _brandBg = Color(0xFFF4F7EF);

final tnnTheme = ThemeData(
  colorSchemeSeed: _brandAccent,
  useMaterial3: true,
  scaffoldBackgroundColor: _brandBg,
  appBarTheme: const AppBarTheme(
    backgroundColor: _brandBg,
    foregroundColor: Color(0xFF1D2A1C),
    elevation: 0,
  ),
  inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
);
