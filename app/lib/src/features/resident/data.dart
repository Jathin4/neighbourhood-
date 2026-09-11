import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/ticket_ui.dart' show TStatus;

class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.priority,
    required this.date,
    this.read = false,
  });

  final String id, title, body, priority, date;
  final bool read;

  Notice markRead() => Notice(id: id, title: title, body: body, priority: priority, date: date, read: true);
}

class IssueTicket {
  const IssueTicket({
    required this.id,
    required this.cat,
    required this.title,
    required this.status,
    required this.statusLabel,
    required this.date,
  });

  final String id, cat, title, statusLabel, date;
  final TStatus status;

  IssueTicket copyWith({TStatus? status, String? statusLabel}) => IssueTicket(
        id: id,
        cat: cat,
        title: title,
        status: status ?? this.status,
        statusLabel: statusLabel ?? this.statusLabel,
        date: date,
      );
}

class EventItem {
  const EventItem(this.id, this.title, this.when, this.location, [this.rsvped = false]);
  final String id, title, when, location;
  final bool rsvped;

  EventItem toggleRsvp() => EventItem(id, title, when, location, !rsvped);
}

class ServiceCategory {
  const ServiceCategory(this.id, this.cat, this.name, this.blurb);
  final String id, cat, name, blurb;
}

class Booking {
  const Booking({
    required this.id,
    required this.cat,
    required this.title,
    required this.provider,
    required this.community,
    required this.when,
    required this.amount,
    required this.status,
    required this.statusLabel,
  });

  final String id, cat, title, provider, community, when, amount, statusLabel;
  final TStatus status;

  Booking copyWith({TStatus? status, String? statusLabel}) => Booking(
        id: id,
        cat: cat,
        title: title,
        provider: provider,
        community: community,
        when: when,
        amount: amount,
        status: status ?? this.status,
        statusLabel: statusLabel ?? this.statusLabel,
      );
}

class SupportTicket {
  const SupportTicket(this.id, this.subject, this.status, this.statusLabel, this.date);
  final String id, subject, statusLabel, date;
  final TStatus status;
}

class ResidentData {
  const ResidentData({
    required this.notices,
    required this.issues,
    required this.events,
    required this.services,
    required this.bookings,
    required this.support,
  });

  final List<Notice> notices;
  final List<IssueTicket> issues;
  final List<EventItem> events;
  final List<ServiceCategory> services;
  final List<Booking> bookings;
  final List<SupportTicket> support;

  ResidentData copyWith({
    List<Notice>? notices,
    List<IssueTicket>? issues,
    List<EventItem>? events,
    List<Booking>? bookings,
    List<SupportTicket>? support,
  }) =>
      ResidentData(
        notices: notices ?? this.notices,
        issues: issues ?? this.issues,
        events: events ?? this.events,
        services: services,
        bookings: bookings ?? this.bookings,
        support: support ?? this.support,
      );

  factory ResidentData.seed() => ResidentData(
        notices: List.of(_seedNotices),
        issues: List.of(_seedIssues),
        events: List.of(_seedEvents),
        services: _seedServices,
        bookings: List.of(_seedBookings),
        support: List.of(_seedSupport),
      );
}

final residentProvider = NotifierProvider<ResidentController, ResidentData>(ResidentController.new);

class ResidentController extends Notifier<ResidentData> {
  @override
  ResidentData build() => ResidentData.seed();

  void markNoticeRead(String id) => state = state.copyWith(
        notices: [for (final n in state.notices) n.id == id ? n.markRead() : n],
      );

  void raiseIssue(String category, String title) => state = state.copyWith(
        issues: [
          IssueTicket(
            id: 'ISS-${2000 + state.issues.length}',
            cat: category,
            title: title.isEmpty ? 'Untitled issue' : title,
            status: TStatus.blue,
            statusLabel: 'Submitted',
            date: 'Today',
          ),
          ...state.issues,
        ],
      );

  void reopenIssue(String id) => state = state.copyWith(
        issues: [
          for (final i in state.issues)
            i.id == id ? i.copyWith(status: TStatus.blue, statusLabel: 'Reopened') : i,
        ],
      );

  void toggleRsvp(String id) => state = state.copyWith(
        events: [for (final e in state.events) e.id == id ? e.toggleRsvp() : e],
      );

  void requestService(ServiceCategory category) => state = state.copyWith(
        bookings: [
          Booking(
            id: 'BK-${3000 + state.bookings.length}',
            cat: category.cat,
            title: category.name,
            provider: 'Matching a verified provider…',
            community: 'Your community',
            when: 'Awaiting provider response',
            amount: '—',
            status: TStatus.blue,
            statusLabel: 'Requested',
          ),
          ...state.bookings,
        ],
      );

  void cancelBooking(String id) => state = state.copyWith(
        bookings: state.bookings.where((b) => b.id != id).toList(),
      );

  void confirmCompletion(String id) => state = state.copyWith(
        bookings: [
          for (final b in state.bookings)
            b.id == id ? b.copyWith(status: TStatus.success, statusLabel: 'Completed') : b,
        ],
      );

  void addSupportTicket(String subject) => state = state.copyWith(
        support: [
          SupportTicket('SUP-R${1000 + state.support.length}',
              subject.isEmpty ? 'Untitled issue' : subject, TStatus.blue, 'Open', 'Today'),
          ...state.support,
        ],
      );

  void resetDemo() => state = ResidentData.seed();
}

const _seedNotices = [
  Notice(
    id: 'NOT-501',
    title: 'Water supply interruption — 12 Sep, 10 AM–2 PM',
    body: 'Maintenance work on the main line. Please store water in advance.',
    priority: 'Critical',
    date: 'Today',
  ),
  Notice(
    id: 'NOT-498',
    title: 'Diwali cultural night — sign up for stalls',
    body: 'Community hall, 7 PM onwards. Contact the committee to book a stall.',
    priority: 'General',
    date: 'Yesterday',
    read: true,
  ),
  Notice(
    id: 'NOT-492',
    title: 'New visitor gate policy from next week',
    body: 'All visitors must be pre-approved via the app or reception.',
    priority: 'General',
    date: '3 days ago',
    read: true,
  ),
];

const _seedIssues = [
  IssueTicket(
    id: 'ISS-1042',
    cat: 'issue',
    title: 'Lift in B-Block making a grinding noise',
    status: TStatus.amber,
    statusLabel: 'In Progress',
    date: '2 days ago',
  ),
  IssueTicket(
    id: 'ISS-1038',
    cat: 'issue',
    title: 'Streetlight near Tower C not working',
    status: TStatus.blue,
    statusLabel: 'Assigned',
    date: '4 days ago',
  ),
  IssueTicket(
    id: 'ISS-1020',
    cat: 'issue',
    title: 'Clubhouse AC not cooling',
    status: TStatus.success,
    statusLabel: 'Resolved',
    date: '2 weeks ago',
  ),
];

const _seedEvents = [
  EventItem('EVT-21', 'Diwali cultural night', '12 Sep, 7 PM', 'Community hall'),
  EventItem('EVT-19', 'Morning yoga & wellness camp', '14 Sep, 6:30 AM', 'Central lawn', true),
  EventItem('EVT-15', 'Kids painting competition', '20 Sep, 4 PM', 'Clubhouse'),
];

const _seedServices = [
  ServiceCategory('SVC-1', 'bolt', 'Electrician', 'Wiring, switchboards, fittings'),
  ServiceCategory('SVC-2', 'wrench', 'Plumber', 'Leaks, taps, blockages'),
  ServiceCategory('SVC-3', 'wrench', 'Carpenter', 'Furniture, doors, fittings'),
  ServiceCategory('SVC-4', 'fan', 'AC Technician', 'Servicing, gas top-up, repair'),
  ServiceCategory('SVC-5', 'spray', 'Pest Control', 'Full-flat and kitchen treatment'),
  ServiceCategory('SVC-6', 'build', 'Cleaning', 'Deep cleaning, sofa & carpet'),
];

const _seedBookings = [
  Booking(
    id: 'BK-2391',
    cat: 'bolt',
    title: 'Switchboard repair',
    provider: 'Ramesh Kumar Electricals',
    community: 'Green Meadows Residency',
    when: 'Today, 5 PM',
    amount: '₹400',
    status: TStatus.amber,
    statusLabel: 'Scheduled',
  ),
  Booking(
    id: 'BK-2378',
    cat: 'fan',
    title: 'Split AC servicing',
    provider: 'CoolFix AC Services',
    community: 'Green Meadows Residency',
    when: 'Yesterday, 11 AM',
    amount: '₹900',
    status: TStatus.success,
    statusLabel: 'Awaiting confirmation',
  ),
  Booking(
    id: 'BK-2340',
    cat: 'wrench',
    title: 'Kitchen tap replacement',
    provider: 'Suresh Plumbing Works',
    community: 'Green Meadows Residency',
    when: '3 Sep',
    amount: '₹350',
    status: TStatus.success,
    statusLabel: 'Completed',
  ),
];

const _seedSupport = [
  SupportTicket('SUP-R1001', 'Wrong amount charged for AC service', TStatus.amber, 'In review', '2 Sep'),
];
