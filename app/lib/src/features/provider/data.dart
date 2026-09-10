import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Visual status shared by tickets, bookings and support rows.
enum TStatus { blue, amber, success, danger }

IconData catIcon(String cat) => switch (cat) {
      'bolt' => Icons.electrical_services,
      'wrench' => Icons.plumbing,
      'fan' => Icons.ac_unit,
      'spray' => Icons.pest_control,
      _ => Icons.build,
    };

class Lead {
  const Lead({
    required this.id,
    required this.cat,
    required this.title,
    required this.customer,
    required this.community,
    required this.pref,
    required this.budget,
    required this.mins,
  });

  final String id, cat, title, customer, community, pref, budget, mins;
}

class Booking {
  const Booking({
    required this.id,
    required this.cat,
    required this.title,
    required this.customer,
    required this.community,
    required this.when,
    required this.amount,
    required this.status,
    required this.statusLabel,
  });

  final String id, cat, title, customer, community, when, amount, statusLabel;
  final TStatus status;

  Booking copyWith({TStatus? status, String? statusLabel}) => Booking(
        id: id,
        cat: cat,
        title: title,
        customer: customer,
        community: community,
        when: when,
        amount: amount,
        status: status ?? this.status,
        statusLabel: statusLabel ?? this.statusLabel,
      );
}

class Payout {
  const Payout(
      this.id, this.customer, this.gross, this.fee, this.net, this.status);
  final String id, customer, status;
  final int gross, fee, net;
}

class Review {
  const Review(this.name, this.date, this.stars, this.text, [this.reply]);
  final String name, date, text;
  final int stars;
  final String? reply;

  Review withReply(String r) => Review(name, date, stars, text, r);
}

class SupportTicket {
  const SupportTicket(
      this.id, this.subject, this.status, this.statusLabel, this.date);
  final String id, subject, statusLabel, date;
  final TStatus status;
}

class ServiceItem {
  const ServiceItem(this.name, this.cat, this.price);
  final String name, cat, price;
}

class PortalData {
  const PortalData({
    required this.leads,
    required this.bookings,
    required this.payouts,
    required this.reviews,
    required this.support,
    required this.services,
    required this.blockedSlots,
  });

  final List<Lead> leads;
  final List<Booking> bookings;
  final List<Payout> payouts;
  final List<Review> reviews;
  final List<SupportTicket> support;
  final List<ServiceItem> services;
  final Set<String> blockedSlots; // key: "<dayIndex>-<slotIndex>"

  PortalData copyWith({
    List<Lead>? leads,
    List<Booking>? bookings,
    List<Review>? reviews,
    List<SupportTicket>? support,
    Set<String>? blockedSlots,
  }) =>
      PortalData(
        leads: leads ?? this.leads,
        bookings: bookings ?? this.bookings,
        payouts: payouts,
        reviews: reviews ?? this.reviews,
        support: support ?? this.support,
        services: services,
        blockedSlots: blockedSlots ?? this.blockedSlots,
      );

  factory PortalData.seed() => PortalData(
        leads: List.of(_seedLeads),
        bookings: List.of(_seedBookings),
        payouts: _seedPayouts,
        reviews: List.of(_seedReviews),
        support: List.of(_seedSupport),
        services: _seedServices,
        blockedSlots: {'5-3', '5-4', '6-0', '6-1', '6-2', '6-3', '6-4'},
      );
}

final portalProvider =
    NotifierProvider<PortalController, PortalData>(PortalController.new);

class PortalController extends Notifier<PortalData> {
  @override
  PortalData build() => PortalData.seed();

  void _dropLead(String id) => state =
      state.copyWith(leads: state.leads.where((l) => l.id != id).toList());

  void acceptLead(String id) => _dropLead(id);
  void declineLead(String id) => _dropLead(id);
  // proposeAlt: resident is notified, lead stays in the inbox — no state change.

  void completeJob(String id) => state = state.copyWith(
        bookings: [
          for (final b in state.bookings)
            b.id == id
                ? b.copyWith(
                    status: TStatus.amber, statusLabel: 'Awaiting confirmation')
                : b,
        ],
      );

  void replyReview(int index, String text) => state = state.copyWith(
        reviews: [
          for (var i = 0; i < state.reviews.length; i++)
            i == index ? state.reviews[i].withReply(text) : state.reviews[i],
        ],
      );

  void toggleSlot(String key) {
    final next = {...state.blockedSlots};
    next.contains(key) ? next.remove(key) : next.add(key);
    state = state.copyWith(blockedSlots: next);
  }

  void addSupportTicket(String subject) => state = state.copyWith(
        support: [
          SupportTicket(
            'SUP-${1052 + state.support.length}',
            subject.isEmpty ? 'Untitled issue' : subject,
            TStatus.blue,
            'Open',
            'Today',
          ),
          ...state.support,
        ],
      );

  void resetLeads() => state = state.copyWith(leads: List.of(_seedLeads));
}

const _seedLeads = [
  Lead(
    id: 'TNN-2K402',
    cat: 'bolt',
    title: 'Switchboard sparking near kitchen',
    customer: 'Anjali Rao · B-Block 1204',
    community: 'Green Meadows Residency',
    pref: 'Today, 5–7 PM',
    budget: '₹400–600',
    mins: '18 min left',
  ),
  Lead(
    id: 'TNN-2K403',
    cat: 'fan',
    title: 'AC not cooling — gas check',
    customer: 'Meera Iyer · Tower C 902',
    community: 'Sunrise Enclave',
    pref: 'Tomorrow AM',
    budget: 'Not specified',
    mins: '27 min left',
  ),
  Lead(
    id: 'TNN-2K404',
    cat: 'wrench',
    title: 'Kitchen tap leaking continuously',
    customer: 'Farhan Sheikh · A-Block 305',
    community: 'Green Meadows Residency',
    pref: 'This weekend',
    budget: '₹250–350',
    mins: '29 min left',
  ),
  Lead(
    id: 'TNN-2K406',
    cat: 'spray',
    title: 'Cockroach infestation in kitchen',
    customer: 'Neha Kapoor · C-Block 502',
    community: 'Palm Grove Society',
    pref: 'Tomorrow evening',
    budget: '₹500–800',
    mins: '12 min left',
  ),
];

const _seedBookings = [
  Booking(
    id: 'TNN-2K391',
    cat: 'bolt',
    title: 'Fan regulator replacement',
    customer: 'Priya Menon · D-Block 611',
    community: 'Green Meadows Residency',
    when: 'Today, 3:30 PM',
    amount: '₹350',
    status: TStatus.success,
    statusLabel: 'In progress',
  ),
  Booking(
    id: 'TNN-2K385',
    cat: 'wrench',
    title: 'Bathroom pipe joint repair',
    customer: 'Karthik Nair · Tower B 407',
    community: 'Sunrise Enclave',
    when: 'Today, 6:00 PM',
    amount: '₹450',
    status: TStatus.amber,
    statusLabel: 'Confirmed',
  ),
  Booking(
    id: 'TNN-2K378',
    cat: 'fan',
    title: 'Split AC servicing (2 units)',
    customer: 'Divya Shah · C-Block 908',
    community: 'Palm Grove Society',
    when: 'Tomorrow, 10 AM',
    amount: '₹900',
    status: TStatus.blue,
    statusLabel: 'Scheduled',
  ),
  Booking(
    id: 'TNN-2K370',
    cat: 'spray',
    title: 'Full-flat pest control',
    customer: 'Rohit Verma · A-Block 112',
    community: 'Green Meadows Residency',
    when: '12 Sep, 11 AM',
    amount: '₹1,200',
    status: TStatus.blue,
    statusLabel: 'Scheduled',
  ),
];

const _seedPayouts = [
  Payout('2K391', 'Priya Menon', 350, 42, 308, 'Pending'),
  Payout('2K385', 'Karthik Nair', 450, 54, 396, 'Pending'),
  Payout('2K360', 'Sanjana Rao', 820, 98, 722, 'Paid'),
  Payout('2K355', 'Imran Qureshi', 450, 54, 396, 'Paid'),
  Payout('2K349', 'Lakshmi Pillai', 1200, 144, 1056, 'Paid'),
];

const _seedReviews = [
  Review('Sanjana Rao', '4 Sep', 5,
      'Fixed the wiring issue quickly and explained what caused it. Very professional.'),
  Review(
      'Imran Qureshi',
      '3 Sep',
      5,
      'On time and reasonably priced. Would book again.',
      'Thank you, Imran! Glad it worked out.'),
  Review('Lakshmi Pillai', '31 Aug', 4,
      'Good work, took a little longer than expected but quality was solid.'),
];

const _seedSupport = [
  SupportTicket('SUP-1042', 'Payout for 2K349 shows wrong commission',
      TStatus.success, 'Resolved', '2 Sep'),
  SupportTicket('SUP-1051', 'Resident cancelled after I reached location',
      TStatus.amber, 'In review', '8 Sep'),
];

const _seedServices = [
  ServiceItem('Switchboard & wiring repair', 'Electrical', '₹250–600'),
  ServiceItem('Fan / light installation', 'Electrical', '₹150–400'),
  ServiceItem('Split AC servicing', 'AC Technician', '₹450/unit'),
  ServiceItem('AC gas top-up', 'AC Technician', '₹800–1,400'),
];
