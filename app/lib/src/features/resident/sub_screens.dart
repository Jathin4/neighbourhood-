import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/app_exception.dart';
import '../../shared/communities.dart';
import '../../shared/me.dart';
import '../../shared/role.dart';
import '../../shared/ticket_ui.dart';
import 'data.dart';

Scaffold _shell(String title, List<Widget> children) => Scaffold(
      backgroundColor: PC.bg,
      appBar: AppBar(
        backgroundColor: PC.panel,
        surfaceTintColor: PC.panel,
        title: Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: PC.ink)),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: children),
    );

// --- PROFILE ---------------------------------------------------------

class ProfileTabScreen extends ConsumerStatefulWidget {
  const ProfileTabScreen({super.key});

  @override
  ConsumerState<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends ConsumerState<ProfileTabScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _loadedOnce = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).raw.patch('/users/me', data: {
        'name': _name.text.trim(),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
      });
      ref.invalidate(meProvider);
      if (mounted) showSnack(context, 'Profile updated');
    } on DioException catch (e) {
      if (mounted) showSnack(context, AppException.fromDio(e).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider);
    // Fill the fields once from the loaded profile without stomping on typing.
    me.whenData((m) {
      if (!_loadedOnce) {
        _name.text = m.name ?? '';
        _email.text = m.email ?? '';
        _loadedOnce = true;
      }
    });

    return _shell('Profile', [
      me.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('$e'),
        data: (m) => PanelCard(
          title: 'Edit profile',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email (optional)'),
              ),
              const SizedBox(height: 12),
              _row('Mobile', m.mobile),
              _row('Account status', m.status ?? '—'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(backgroundColor: PC.navy),
                  child: Text(_saving ? 'Saving...' : 'Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
      PanelCard(
        child: Column(
          children: [
            InkWell(
              onTap: () {
                ref.read(roleProvider.notifier).state = null;
                context.go('/role');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Icon(Icons.switch_account_outlined, size: 18, color: PC.navy),
                  SizedBox(width: 10),
                  Text('Switch role', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
                width: 110,
                child: Text(label, style: const TextStyle(color: PC.inkSoft, fontSize: 12))),
            Expanded(
                child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
      );
}

// --- MY COMMUNITIES ----------------------------------------------------

class MyCommunitiesScreen extends ConsumerWidget {
  const MyCommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communities = ref.watch(communitiesProvider);
    return _shell('My communities', [
      communities.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('$e'),
        data: (list) => list.isEmpty
            ? const _Empty('Not part of any community yet.')
            : Column(
                children: [
                  for (final c in list)
                    PanelCard(
                      child: Row(children: [
                        const Icon(Icons.apartment, color: PC.navy),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text(c.address ?? c.status,
                                  style: const TextStyle(fontSize: 11.5, color: PC.inkSoft)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                ],
              ),
      ),
    ]);
  }
}

// --- ALL NOTICES -------------------------------------------------

class AllNoticesScreen extends ConsumerWidget {
  const AllNoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(residentProvider.select((d) => d.notices));
    final ctrl = ref.read(residentProvider.notifier);
    return _shell('Notices', [
      for (final n in notices)
        TicketCard(
          cat: 'notice',
          status: n.priority == 'Critical' ? TStatus.danger : TStatus.blue,
          id: n.date,
          title: n.title,
          meta: [n.body],
          trailing: Pill(n.priority, kind: n.priority == 'Critical' ? PillKind.brick : PillKind.blue),
          actions: n.read
              ? null
              : Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ctrl.markNoticeRead(n.id),
                      style: OutlinedButton.styleFrom(foregroundColor: PC.ink, side: const BorderSide(color: PC.line)),
                      child: const Text('Mark as read', style: TextStyle(fontSize: 11.5)),
                    ),
                  ),
                ]),
        ),
    ]);
  }
}

// --- ALL EVENTS ----------------------------------------------------

class AllEventsScreen extends ConsumerWidget {
  const AllEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(residentProvider.select((d) => d.events));
    final ctrl = ref.read(residentProvider.notifier);
    return _shell('Events & polls', [
      for (final e in events)
        TicketCard(
          cat: 'event',
          status: TStatus.blue,
          id: e.when,
          title: e.title,
          meta: [e.location],
          trailing: e.rsvped ? const Pill('Going', kind: PillKind.green) : null,
          actions: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => ctrl.toggleRsvp(e.id),
                style: OutlinedButton.styleFrom(foregroundColor: PC.ink, side: const BorderSide(color: PC.line)),
                child: Text(e.rsvped ? 'Cancel RSVP' : 'RSVP', style: const TextStyle(fontSize: 11.5)),
              ),
            ),
          ]),
        ),
    ]);
  }
}

// --- SUPPORT --------------------------------------------------------

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _subject = TextEditingController();

  @override
  void dispose() {
    _subject.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(residentProvider.select((d) => d.support));
    final ctrl = ref.read(residentProvider.notifier);

    return _shell('Support', [
      if (tickets.isEmpty)
        const _Empty('No support tickets yet.')
      else
        for (final t in tickets)
          TicketCard(
            cat: 'support',
            status: t.status,
            id: t.id,
            title: t.subject,
            meta: ['Raised ${t.date}'],
            trailing: Pill(t.statusLabel,
                kind: switch (t.status) {
                  TStatus.success => PillKind.green,
                  TStatus.amber => PillKind.amber,
                  TStatus.danger => PillKind.brick,
                  TStatus.blue => PillKind.blue,
                }),
          ),
      PanelCard(
        title: 'Raise a new ticket',
        child: Column(
          children: [
            TextField(controller: _subject, decoration: const InputDecoration(labelText: 'Subject')),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ctrl.addSupportTicket(_subject.text.trim());
                  _subject.clear();
                  showSnack(context, 'Ticket submitted — support team will respond soon');
                },
                style: FilledButton.styleFrom(backgroundColor: PC.navy),
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
        decoration: BoxDecoration(border: Border.all(color: PC.line)),
        child: Center(child: Text(text, style: const TextStyle(fontSize: 12, color: PC.inkFaint))),
      );
}
