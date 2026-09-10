import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/core/router.dart';
import 'src/core/theme.dart';

void main() {
  runApp(const ProviderScope(child: TnnApp()));
}

class TnnApp extends ConsumerWidget {
  const TnnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Trusted Neighbourhood Network',
      theme: tnnTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
