import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/app_exception.dart';

class _Unit {
  _Unit(this.tower, this.unitNumber);
  final String tower, unitNumber;
  factory _Unit.fromJson(Map<String, dynamic> j) =>
      _Unit(j['tower'] as String, j['unit_number'] as String);
}

final _unitsProvider = FutureProvider.autoDispose.family<List<_Unit>, String>((ref, communityId) async {
  try {
    final res = await ref.read(apiClientProvider).raw.get('/communities/$communityId/units');
    return (res.data as List).map((e) => _Unit.fromJson(e as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});

/// Towers/blocks and units management (§6) for a single community.
class UnitsScreen extends ConsumerStatefulWidget {
  const UnitsScreen({required this.communityId, required this.communityName, super.key});

  final String communityId;
  final String communityName;

  @override
  ConsumerState<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends ConsumerState<UnitsScreen> {
  final _tower = TextEditingController();
  final _unit = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _tower.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _addUnit() async {
    final tower = _tower.text.trim();
    final unit = _unit.text.trim();
    if (tower.isEmpty || unit.isEmpty) return;
    setState(() => _adding = true);
    try {
      await ref.read(apiClientProvider).raw.post('/communities/${widget.communityId}/units', data: {
        'units': [
          {'tower': tower, 'unit_number': unit}
        ],
      });
      _tower.clear();
      _unit.clear();
      ref.invalidate(_unitsProvider(widget.communityId));
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppException.fromDio(e).message)));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(_unitsProvider(widget.communityId));

    return Scaffold(
      appBar: AppBar(title: Text('Units — ${widget.communityName}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tower,
                      decoration: const InputDecoration(labelText: 'Tower', hintText: 'A'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _unit,
                      decoration: const InputDecoration(labelText: 'Unit number', hintText: '101'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _adding ? null : _addUnit,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          units.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
            data: (list) => list.isEmpty
                ? const Text('No units yet.')
                : Text('${list.length} units', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          units.maybeWhen(
            data: (list) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final u in list)
                  Chip(label: Text('${u.tower}-${u.unitNumber}')),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
