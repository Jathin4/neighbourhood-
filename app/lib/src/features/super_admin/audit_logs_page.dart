import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/app_exception.dart';
import 'panel_data.dart';

class _AuditEntry {
  _AuditEntry(this.action, this.entity, this.entityId, this.actorMobile, this.createdAt, this.meta);
  final String action, entity;
  final String? entityId, actorMobile;
  final DateTime createdAt;
  final Map<String, dynamic> meta;

  factory _AuditEntry.fromJson(Map<String, dynamic> j) => _AuditEntry(
        j['action'] as String,
        j['entity'] as String,
        j['entity_id'] as String?,
        j['actor_mobile'] as String?,
        DateTime.parse(j['created_at'] as String).toLocal(),
        Map<String, dynamic>.from(j['meta'] as Map? ?? {}),
      );
}

final _auditLogsProvider = FutureProvider.autoDispose<List<_AuditEntry>>((ref) async {
  try {
    final res = await ref.read(apiClientProvider).raw.get('/admin/audit-logs');
    return (res.data as List)
        .map((e) => _AuditEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});

/// GET /admin/audit-logs — real, requires audit.view (super_admin only, §1).
class AuditLogsPage extends ConsumerWidget {
  const AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(_auditLogsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 60),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Audit Logs',
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AC.ink900)),
                  SizedBox(height: 4),
                  Text('Actor, action, entity and timestamp for sensitive changes.',
                      style: TextStyle(fontSize: 14, color: AC.ink600)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(_auditLogsProvider),
            ),
          ],
        ),
        const SizedBox(height: 20),
        logs.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('$e', style: const TextStyle(color: AC.red)),
          data: (list) => list.isEmpty
              ? const Text('No audit entries yet.')
              : Container(
                  decoration: BoxDecoration(
                    color: AC.surface,
                    border: Border.all(color: AC.line),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      for (final e in list)
                        ListTile(
                          title: Text(e.action, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${e.entity}${e.entityId != null ? ' · ${e.entityId!.substring(0, 8)}' : ''}'
                            '${e.actorMobile != null ? ' · by ${e.actorMobile}' : ''}',
                          ),
                          trailing: Text(
                            '${e.createdAt.hour.toString().padLeft(2, '0')}:'
                            '${e.createdAt.minute.toString().padLeft(2, '0')}  '
                            '${e.createdAt.day}/${e.createdAt.month}',
                            style: const TextStyle(fontSize: 12, color: AC.ink400),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
