import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/app_exception.dart';
import '../../shared/communities.dart';

class _Field {
  const _Field(this.label, {this.hint, this.options});
  final String label;
  final String? hint;
  final List<String>? options;
}

class _ActionConfig {
  const _ActionConfig(this.subtitle, this.fields);
  final String subtitle;
  final List<_Field> fields;
}

const _configs = {
  'Create Community': _ActionConfig(
    'Set up a new gated community or apartment complex.',
    [_Field('Community Name', hint: 'e.g. Palm Grove Residency'), _Field('City', hint: 'e.g. Hyderabad')],
  ),
  'Create User': _ActionConfig(
    'Add a new resident, admin, or committee member to the platform.',
    [
      _Field('Full Name', hint: 'e.g. Anjali Mehta'),
      _Field('Email Address', hint: 'name@email.com'),
      _Field('Role', options: ['Resident', 'Committee Member', 'Community Admin']),
    ],
  ),
  'Add Service Provider': _ActionConfig(
    'Onboard a new verified service provider to the marketplace.',
    [
      _Field('Business Name', hint: 'e.g. ABC Plumbing Services'),
      _Field('Category', options: ['Plumbing', 'Electrical', 'Cleaning', 'Security']),
      _Field('Contact Number', hint: '+91 98xxxxxxxx'),
    ],
  ),
  'Configure Categories': _ActionConfig(
    'Manage service categories shown across the platform.',
    [
      _Field('Category Name', hint: 'e.g. Home Cleaning'),
      _Field('Parent Category', options: ['None', 'Maintenance', 'Wellness', 'Utilities']),
    ],
  ),
  'Manage Roles & Permissions': _ActionConfig(
    'Create or edit roles and their permission scopes.',
    [
      _Field('Role Name', hint: 'e.g. Regional Moderator'),
      _Field('Access Level', options: ['Read Only', 'Standard', 'Full Access']),
    ],
  ),
  'View Audit Logs': _ActionConfig(
    'Review a filtered log of administrative activity.',
    [
      _Field('Date Range', hint: 'Last 7 days'),
      _Field('Filter by Action', options: ['All Actions', 'Logins', 'Deletions', 'Approvals']),
    ],
  ),
};

/// Only "Create Community" hits the real API (POST /communities is actually
/// built); every other quick action mirrors the prototype's own mock modal —
/// it just confirms and toasts, since those backend modules don't exist yet.
Future<void> showQuickActionDialog(BuildContext context, WidgetRef ref, String action) async {
  final cfg = _configs[action]!;
  final controllers = [for (final _ in cfg.fields) TextEditingController()];
  final selections = List<String?>.filled(cfg.fields.length, null);
  for (var i = 0; i < cfg.fields.length; i++) {
    if (cfg.fields[i].options != null) selections[i] = cfg.fields[i].options!.first;
  }

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(action),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cfg.subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
              const SizedBox(height: 16),
              for (var i = 0; i < cfg.fields.length; i++) ...[
                if (cfg.fields[i].options != null)
                  DropdownButtonFormField<String>(
                    initialValue: selections[i],
                    decoration: InputDecoration(labelText: cfg.fields[i].label),
                    items: [
                      for (final o in cfg.fields[i].options!)
                        DropdownMenuItem(value: o, child: Text(o)),
                    ],
                    onChanged: (v) => setState(() => selections[i] = v),
                  )
                else
                  TextField(
                    controller: controllers[i],
                    decoration: InputDecoration(
                      labelText: cfg.fields[i].label,
                      hintText: cfg.fields[i].hint,
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (action == 'Create Community') {
                await _createCommunity(context, ref, controllers[0].text.trim(),
                    controllers.length > 1 ? controllers[1].text.trim() : '');
              } else {
                Navigator.pop(context);
                _toast(context, '$action — saved successfully.');
              }
            },
            child: Text(action),
          ),
        ],
      ),
    ),
  );
}

Future<void> _createCommunity(
  BuildContext context,
  WidgetRef ref,
  String name,
  String city,
) async {
  if (name.isEmpty) return;
  try {
    await ref.read(apiClientProvider).raw.post('/communities', data: {
      'name': name,
      if (city.isNotEmpty) 'address': city,
    });
    ref.invalidate(communitiesProvider);
    if (context.mounted) {
      Navigator.pop(context);
      _toast(context, 'Create Community — saved successfully.');
    }
  } on DioException catch (e) {
    if (context.mounted) _toast(context, AppException.fromDio(e).message);
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}
