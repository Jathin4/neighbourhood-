import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data.dart';
import '../../shared/ticket_ui.dart';

Scaffold _shell(String title, List<Widget> children) => Scaffold(
      backgroundColor: PC.bg,
      appBar: AppBar(
        backgroundColor: PC.panel,
        surfaceTintColor: PC.panel,
        title: Text(title,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w600, color: PC.ink)),
      ),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: children),
    );

InputDecoration _dec(String label) => InputDecoration(
      labelText: label,
      isDense: true,
      border: const OutlineInputBorder(),
    );

Widget _fullButton(String label, VoidCallback onTap, {bool primary = false}) =>
    SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: primary ? PC.navy : PC.panel,
          foregroundColor: primary ? Colors.white : PC.ink,
          side: primary ? null : const BorderSide(color: PC.line),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(3))),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );

// --- PROFILE & SERVICES -------------------------------------------------

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(portalProvider.select((d) => d.services));
    return _shell('Profile & services', [
      PanelCard(
        title: 'Services offered',
        child: Column(
          children: [
            for (final s in services)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w600)),
                          Text(s.cat,
                              style: const TextStyle(
                                  fontSize: 10.5, color: PC.inkSoft)),
                        ],
                      ),
                    ),
                    Text(s.price,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: PC.navy)),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () =>
                          showSnack(context, 'Editing “${s.name}”'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: PC.line),
                        foregroundColor: PC.ink,
                      ),
                      child:
                          const Text('Edit', style: TextStyle(fontSize: 11.5)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            _fullButton('+ Add a service',
                () => showSnack(context, 'New service — needs admin approval')),
          ],
        ),
      ),
      PanelCard(
        title: 'Business details',
        child: Column(
          children: [
            TextFormField(
                initialValue: 'Ramesh Kumar Electricals',
                decoration: _dec('Business name')),
            const SizedBox(height: 12),
            TextFormField(
                initialValue: 'Green Meadows + 3 nearby communities',
                decoration: _dec('Service area')),
            const SizedBox(height: 12),
            _fullButton(
                'Save changes',
                () => showSnack(
                    context, 'Saved. Category/pricing edits await approval.'),
                primary: true),
          ],
        ),
      ),
      PanelCard(
        title: 'Team',
        child: Column(
          children: [
            _teamRow('Ramesh Kumar', 'Owner',
                const Pill('Active', kind: PillKind.green)),
            _teamRow('Suresh Yadav', 'Technician',
                const Pill('Active', kind: PillKind.green)),
            _teamRow('Vijay Singh', 'Technician',
                const Pill('Off today', kind: PillKind.grey)),
            const SizedBox(height: 6),
            _fullButton(
                '+ Add technician', () => showSnack(context, 'Invite sent')),
          ],
        ),
      ),
    ]);
  }

  Widget _teamRow(String name, String role, Widget pill) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: name,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
                TextSpan(
                    text: '  ·  $role', style: const TextStyle(fontSize: 12.5)),
              ])),
            ),
            pill,
          ],
        ),
      );
}

// --- AVAILABILITY -----------------------------------------------------

class AvailabilityScreen extends ConsumerWidget {
  const AvailabilityScreen({super.key});

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _slots = ['9–11', '11–1', '1–3', '3–5', '5–7'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(portalProvider.select((d) => d.blockedSlots));
    final ctrl = ref.read(portalProvider.notifier);

    return _shell('Availability', [
      const Text(
          'Tap a slot to open or block it. Scroll sideways for the full week.',
          style: TextStyle(fontSize: 11.5, color: PC.inkSoft)),
      const SizedBox(height: 12),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var di = 0; di < _days.length; di++)
                    Container(
                      width: 66,
                      margin: const EdgeInsets.only(right: 6),
                      decoration:
                          BoxDecoration(border: Border.all(color: PC.line)),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            color: PC.blueBg,
                            child: Text(_days[di],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: PC.navy)),
                          ),
                          for (var si = 0; si < _slots.length; si++)
                            _slot(ctrl, blocked, di, si),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _legend(PC.greenBg, PC.green, 'Open'),
                const SizedBox(width: 14),
                _legend(PC.brickBg, PC.brick, 'Blocked'),
              ],
            ),
          ],
        ),
      ),
      PanelCard(
        title: 'Blackout dates',
        child: Column(
          children: [
            TextFormField(decoration: _dec('Date  (e.g. 15 Sep 2026)')),
            const SizedBox(height: 12),
            TextFormField(decoration: _dec('Reason (optional)')),
            const SizedBox(height: 12),
            _fullButton('Block day', () => showSnack(context, 'Day blocked'),
                primary: true),
          ],
        ),
      ),
    ]);
  }

  Widget _slot(PortalController ctrl, Set<String> blocked, int di, int si) {
    final key = '$di-$si';
    final isBlocked = blocked.contains(key);
    return InkWell(
      onTap: () => ctrl.toggleSlot(key),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isBlocked ? PC.brickBg : PC.greenBg,
          border: const Border(top: BorderSide(color: PC.lineSoft)),
        ),
        child: Text(
          _slots[si],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: isBlocked ? PC.brick : PC.green,
            decoration: isBlocked ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }

  Widget _legend(Color bg, Color border, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: bg, border: Border.all(color: border)),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(fontSize: 10.5, color: PC.inkSoft)),
        ],
      );
}

// --- REVIEWS --------------------------------------------------------

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(portalProvider.select((d) => d.reviews));
    final ctrl = ref.read(portalProvider.notifier);

    return _shell('Reviews', [
      PanelCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('4.8',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: PC.navy)),
                Text('★★★★★',
                    style: TextStyle(color: PC.marigold, fontSize: 13)),
                SizedBox(height: 2),
                Text('128 jobs · 94 reviews',
                    style: TextStyle(fontSize: 10, color: PC.inkFaint)),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                children: const [
                  _BarRow('5', 0.82),
                  _BarRow('4', 0.12),
                  _BarRow('3', 0.04),
                  _BarRow('2', 0.01),
                  _BarRow('1', 0.01),
                ],
              ),
            ),
          ],
        ),
      ),
      PanelCard(
        child: Column(
          children: [
            for (var i = 0; i < reviews.length; i++)
              _reviewTile(context, ctrl, reviews[i], i),
          ],
        ),
      ),
    ]);
  }

  Widget _reviewTile(
      BuildContext context, PortalController ctrl, Review r, int i) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: PC.lineSoft))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r.name,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600)),
              Text(r.date,
                  style: const TextStyle(fontSize: 10, color: PC.inkFaint)),
            ],
          ),
          Text('${'★' * r.stars}${'☆' * (5 - r.stars)}',
              style: const TextStyle(color: PC.marigold, fontSize: 12)),
          const SizedBox(height: 5),
          Text(r.text,
              style: const TextStyle(fontSize: 11.5, color: PC.inkSoft)),
          const SizedBox(height: 7),
          if (r.reply != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: PC.bg, border: Border.all(color: PC.lineSoft)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('YOUR REPLY',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: PC.navy,
                          letterSpacing: 0.4)),
                  const SizedBox(height: 2),
                  Text(r.reply!, style: const TextStyle(fontSize: 11)),
                ],
              ),
            )
          else
            OutlinedButton(
              onPressed: () {
                ctrl.replyReview(
                    i, 'Thank you for the feedback — really appreciate it!');
                showSnack(context, 'Reply posted');
              },
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                side: const BorderSide(color: PC.line),
                foregroundColor: PC.ink,
              ),
              child: const Text('Reply', style: TextStyle(fontSize: 11.5)),
            ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow(this.label, this.fraction);
  final String label;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
              width: 12,
              child: Text(label,
                  style: const TextStyle(fontSize: 10, color: PC.inkSoft))),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 5,
                backgroundColor: PC.lineSoft,
                valueColor: const AlwaysStoppedAnimation(PC.marigold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- SUPPORT & DISPUTES --------------------------------------------

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _subject = TextEditingController();
  String _related = 'Booking TNN-2K391';

  @override
  void dispose() {
    _subject.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(portalProvider.select((d) => d.support));
    final ctrl = ref.read(portalProvider.notifier);

    return _shell('Support & disputes', [
      if (tickets.isEmpty)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 26),
          decoration: BoxDecoration(border: Border.all(color: PC.line)),
          child: const Center(
              child: Text('No support tickets yet.',
                  style: TextStyle(fontSize: 12, color: PC.inkFaint))),
        )
      else
        for (final t in tickets)
          TicketCard(
            cat: 'wrench',
            status: t.status,
            id: t.id,
            title: t.subject,
            meta: ['Raised ${t.date}'],
            trailing: Pill(t.statusLabel,
                kind: switch (t.status) {
                  TStatus.success => PillKind.green,
                  TStatus.amber => PillKind.amber,
                  _ => PillKind.blue,
                }),
          ),
      PanelCard(
        title: 'Raise a new ticket',
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _related,
              isDense: true,
              decoration: _dec('Related to'),
              items: const [
                'Booking TNN-2K391',
                'Payout — week of 1 Sep',
                'Profile verification',
                'Other',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _related = v ?? _related),
            ),
            const SizedBox(height: 12),
            TextField(controller: _subject, decoration: _dec('Subject')),
            const SizedBox(height: 12),
            TextField(
                maxLines: 3,
                decoration: _dec('Details'),
                textInputAction: TextInputAction.newline),
            const SizedBox(height: 12),
            _fullButton('Submit ticket', () {
              ctrl.addSupportTicket(_subject.text.trim());
              _subject.clear();
              showSnack(
                  context, 'Ticket submitted — admin team will respond soon');
            }, primary: true),
          ],
        ),
      ),
    ]);
  }
}
