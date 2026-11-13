import 'package:flutter/material.dart';

import '../../../models/booking_model.dart';
import '../../../models/sitter_details_model.dart';
import '../../../theme/app_colors.dart';
import 'sitter_detail_card.dart';

class SitterServicesCard extends StatelessWidget {
  const SitterServicesCard({super.key, required this.services});

  final List<SitterServiceItem> services;

  @override
  Widget build(BuildContext context) {
    return SitterDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SitterSectionTitle('Services & rates'),
          const SizedBox(height: 2),
          const Text(
            'Prices are in rand (R).',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < services.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 34, color: Colors.grey.shade200),
            _ServiceRow(service: services[i]),
          ],
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});

  final SitterServiceItem service;

  static const Map<ServiceKind, IconData> _icons = {
    ServiceKind.night: Icons.nights_stay_outlined,
    ServiceKind.visit: Icons.restaurant_outlined,
    ServiceKind.walk: Icons.directions_walk,
  };

  /// The service code from the backend, e.g. STAY_OVER_NIGHT, as one known service.
  ServiceKind? get _kind {
    final kinds = servicesForBookingType(service.serviceType);
    return kinds.length == 1 ? kinds.first : null;
  }

  /// "Overnight stay" for STAY_OVER_NIGHT; an unknown code is shown as "Some code".
  String get _label {
    final kind = _kind;
    if (kind != null) return bookingServiceLabels[kind]!;
    final words = service.serviceType.replaceAll('_', ' ').trim().toLowerCase();
    return words.isEmpty ? 'Service' : words[0].toUpperCase() + words.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(_icons[_kind] ?? Icons.pets, color: AppColors.primaryRust, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            'R${service.price.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryRust,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}