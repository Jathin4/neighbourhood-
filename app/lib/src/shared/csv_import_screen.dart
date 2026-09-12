import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/app_exception.dart';

/// Bulk resident import (§6 "Bulk resident import using validated CSV").
/// No file-picker dependency: the admin pastes CSV text, which we send as
/// the same multipart upload the backend already expects.
class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({required this.communityId, required this.communityName, super.key});

  final String communityId;
  final String communityName;

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  final _csv = TextEditingController(text: 'name,mobile,tower,unit,relationship\n');
  bool _busy = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _csv.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromString(_csv.text, filename: 'residents.csv'),
      });
      final res = await ref
          .read(apiClientProvider)
          .raw
          .post('/communities/${widget.communityId}/members/import', data: form);
      setState(() => _result = res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      setState(() => _error = AppException.fromDio(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Import residents — ${widget.communityName}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Required columns: name, mobile, tower, unit (relationship is optional). '
            'One resident per row.',
            style: TextStyle(color: Colors.grey, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _csv,
            maxLines: 10,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _import,
            child: Text(_busy ? 'Importing...' : 'Import'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Created: ${_result!['created']}   '
                        'Existing: ${_result!['existing']}   '
                        'Errors: ${_result!['errors']}'),
                    if ((_result!['results'] as List).any((r) => r['outcome'] == 'error')) ...[
                      const SizedBox(height: 8),
                      const Text('Rows with errors:', style: TextStyle(fontWeight: FontWeight.w600)),
                      for (final r in (_result!['results'] as List))
                        if (r['outcome'] == 'error')
                          Text('  Row ${r['row']}: ${r['detail']}',
                              style: const TextStyle(fontSize: 12, color: Colors.red)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
