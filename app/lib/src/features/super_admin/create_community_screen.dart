import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/app_exception.dart';
import '../../shared/communities.dart';
import 'panel_data.dart';

/// Full-screen community onboarding (§6): name, place, and the tower/floor/
/// flat structure — the backend auto-generates every Unit from these.
class CreateCommunityScreen extends ConsumerStatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  ConsumerState<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends ConsumerState<CreateCommunityScreen> {
  final _name = TextEditingController();
  final _place = TextEditingController();
  final _towers = TextEditingController(text: '1');
  final _floors = TextEditingController(text: '1');
  final _flats = TextEditingController(text: '1');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _place.dispose();
    _towers.dispose();
    _floors.dispose();
    _flats.dispose();
    super.dispose();
  }

  int _asInt(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  int get _totalUnits => _asInt(_towers) * _asInt(_floors) * _asInt(_flats);

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Community name is required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).raw.post('/communities', data: {
        'name': name,
        if (_place.text.trim().isNotEmpty) 'address': _place.text.trim(),
        'towers': _asInt(_towers),
        'floors_per_tower': _asInt(_floors),
        'flats_per_floor': _asInt(_flats),
      });
      ref.invalidate(communitiesProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (e) {
      setState(() => _error = AppException.fromDio(e).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      appBar: AppBar(title: const Text('Create Community')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _SectionCard(
                title: 'Basic details',
                children: [
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Community name',
                      hintText: 'e.g. Palm Grove Residency',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _place,
                    decoration: const InputDecoration(
                      labelText: 'Place',
                      hintText: 'e.g. Hyderabad',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Structure',
                subtitle: 'Units are generated automatically from these numbers.',
                children: [
                  Row(
                    children: [
                      Expanded(child: _numberField('Number of towers', _towers)),
                      const SizedBox(width: 12),
                      Expanded(child: _numberField('Floors per tower', _floors)),
                      const SizedBox(width: 12),
                      Expanded(child: _numberField('Flats per floor', _flats)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AC.blue50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Total units: $_totalUnits',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AC.blue),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: AC.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Creating...' : 'Create Community'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => setState(() {}),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children, this.subtitle});
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AC.surface,
        border: Border.all(color: AC.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: const TextStyle(fontSize: 12.5, color: AC.ink600)),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
