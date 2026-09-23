import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/ticket_ui.dart' show TStatus;

class ServiceCategory {
  const ServiceCategory(this.id, this.cat, this.name, this.blurb);
  final String id, cat, name, blurb;
}

class SupportTicket {
  const SupportTicket(this.id, this.subject, this.status, this.statusLabel, this.date);
  final String id, subject, statusLabel, date;
  final TStatus status;
}

class ResidentData {
  const ResidentData({required this.services, required this.support});

  final List<ServiceCategory> services;
  final List<SupportTicket> support;

  ResidentData copyWith({List<SupportTicket>? support}) => ResidentData(
        services: services,
        support: support ?? this.support,
      );

  factory ResidentData.seed() =>
      ResidentData(services: _seedServices, support: List.of(_seedSupport));
}

final residentProvider = NotifierProvider<ResidentController, ResidentData>(ResidentController.new);

class ResidentController extends Notifier<ResidentData> {
  @override
  ResidentData build() => ResidentData.seed();

  void addSupportTicket(String subject) => state = state.copyWith(
        support: [
          SupportTicket('SUP-R${1000 + state.support.length}',
              subject.isEmpty ? 'Untitled issue' : subject, TStatus.blue, 'Open', 'Today'),
          ...state.support,
        ],
      );
}

const _seedServices = [
  ServiceCategory('SVC-1', 'bolt', 'Electrician', 'Wiring, switchboards, fittings'),
  ServiceCategory('SVC-2', 'wrench', 'Plumber', 'Leaks, taps, blockages'),
  ServiceCategory('SVC-3', 'wrench', 'Carpenter', 'Furniture, doors, fittings'),
  ServiceCategory('SVC-4', 'fan', 'AC Technician', 'Servicing, gas top-up, repair'),
  ServiceCategory('SVC-5', 'spray', 'Pest Control', 'Full-flat and kitchen treatment'),
  ServiceCategory('SVC-6', 'build', 'Cleaning', 'Deep cleaning, sofa & carpet'),
];

const _seedSupport = [
  SupportTicket('SUP-R1001', 'Wrong amount charged for AC service', TStatus.amber, 'In review', '2 Sep'),
];
