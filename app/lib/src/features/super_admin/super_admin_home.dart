import 'package:flutter/widgets.dart';

import 'admin_shell.dart';

/// Entry point kept stable for the router; the real UI lives in AdminShell.
class SuperAdminHome extends StatelessWidget {
  const SuperAdminHome({super.key});

  @override
  Widget build(BuildContext context) => const AdminShell();
}
