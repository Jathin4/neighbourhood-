import 'package:flutter/material.dart';

/// Shared "ticket portal" design system — used by the Service Provider and
/// Resident portals so both roles get the same look and feel (colors,
/// ticket cards, panels, stat chips) with role-specific content on top.

/// Visual status shared by tickets, bookings and support rows.
enum TStatus { blue, amber, success, danger }

IconData catIcon(String cat) => switch (cat) {
      'bolt' => Icons.electrical_services,
      'wrench' => Icons.plumbing,
      'fan' => Icons.ac_unit,
      'spray' => Icons.pest_control,
      'notice' => Icons.campaign,
      'issue' => Icons.report_problem,
      'event' => Icons.event,
      'poll' => Icons.poll,
      'directory' => Icons.people,
      'support' => Icons.support_agent,
      _ => Icons.build,
    };

// Same earthy-green brand palette as shared/auth_ui.dart's LC.* (the login
// flow) so the Provider and Resident portals match the rest of the app.
abstract final class PC {
  static const bg = Color(0xFFF4F7EF);
  static const panel = Colors.white;
  static const ink = Color(0xFF1D2A1C);
  static const inkSoft = Color(0xFF5B6B58);
  static const inkFaint = Color(0xFF93A08E);
  static const line = Color(0xFFDFE6D6);
  static const lineSoft = Color(0xFFE3ECDC);
  static const navy = Color(0xFF2F5D3A);
  static const marigold = Color(0xFFE2A22A);
  static const marigoldDeep = Color(0xFFB9821A);
  static const brick = Color(0xFFB04A32);
  static const brickBg = Color(0xFFF7E7E1);
  static const green = Color(0xFF3E7D54);
  static const greenBg = Color(0xFFE7F1E8);
  static const amberBg = Color(0xFFFBEFD8);
  static const blueBg = Color(0xFFE3ECDC);
}

({Color bg, Color fg}) _statusColors(TStatus s) => switch (s) {
      TStatus.success => (bg: PC.greenBg, fg: PC.green),
      TStatus.amber => (bg: PC.amberBg, fg: PC.marigoldDeep),
      TStatus.danger => (bg: PC.brickBg, fg: PC.brick),
      TStatus.blue => (bg: PC.blueBg, fg: PC.navy),
    };

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF16311D),
        duration: const Duration(seconds: 2),
      ),
    );
}

enum PillKind { amber, green, brick, blue, grey }

class Pill extends StatelessWidget {
  const Pill(this.text, {this.kind = PillKind.grey, super.key});

  final String text;
  final PillKind kind;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      PillKind.amber => (PC.amberBg, PC.marigoldDeep),
      PillKind.green => (PC.greenBg, PC.green),
      PillKind.brick => (PC.brickBg, PC.brick),
      PillKind.blue => (PC.blueBg, PC.navy),
      PillKind.grey => (PC.lineSoft, PC.inkSoft),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class PanelCard extends StatelessWidget {
  const PanelCard({required this.child, this.title, super.key});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: PC.panel, border: Border.all(color: PC.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip(this.value, this.label, {this.highlight = false, super.key});

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: PC.panel, border: Border.all(color: PC.line)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: highlight ? PC.marigoldDeep : PC.navy,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: PC.inkSoft, height: 1.25),
          ),
        ],
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  const StatRow(this.chips, {super.key});

  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: chips,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Tappable settings-style row (icon, title, optional description, chevron)
/// used by every role's "More" tab.
class MenuRow extends StatelessWidget {
  const MenuRow({required this.icon, required this.title, this.desc, required this.onTap, super.key});

  final IconData icon;
  final String title;
  final String? desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: PC.panel, border: Border.all(color: PC.line)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: PC.blueBg,
              child: Icon(icon, size: 16, color: PC.navy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if (desc != null) Text(desc!, style: const TextStyle(fontSize: 10.5, color: PC.inkSoft)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: PC.inkFaint),
          ],
        ),
      ),
    );
  }
}

/// Plain info card (title + status pill + description, no icon strip) used
/// by Community Admin / Committee Member / Platform Ops' tab screens —
/// mirrors the prototype's `.db-card`.
class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.desc, this.tag, this.tagKind = PillKind.grey, super.key});

  final String title;
  final String desc;
  final String? tag;
  final PillKind tagKind;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PC.panel,
        border: Border.all(color: PC.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              ),
              if (tag != null) ...[const SizedBox(width: 8), Pill(tag!, kind: tagKind)],
            ],
          ),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(fontSize: 12.5, color: PC.inkSoft, height: 1.5)),
        ],
      ),
    );
  }
}

/// The perforated-stub ticket card used for leads, bookings, issues and
/// support rows across both the Provider and Resident portals.
class TicketCard extends StatelessWidget {
  const TicketCard({
    required this.cat,
    required this.status,
    required this.id,
    required this.title,
    required this.meta,
    this.trailing,
    this.actions,
    super.key,
  });

  final String cat;
  final TStatus status;
  final String id;
  final String title;
  final List<String> meta;
  final Widget? trailing;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final c = _statusColors(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(color: PC.panel, border: Border.all(color: PC.line)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 52,
              decoration: BoxDecoration(
                color: c.bg,
                border: const Border(right: BorderSide(color: PC.line)),
              ),
              child: Icon(catIcon(cat), size: 18, color: c.fg),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(id,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: PC.inkFaint,
                                      fontFeatures: [FontFeature.tabularFigures()])),
                              const SizedBox(height: 1),
                              Text(title,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600, height: 1.3)),
                            ],
                          ),
                        ),
                        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                      ],
                    ),
                    const SizedBox(height: 4),
                    for (final line in meta)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(line, style: const TextStyle(fontSize: 11, color: PC.inkSoft)),
                      ),
                    if (actions != null) ...[const SizedBox(height: 10), actions!],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
