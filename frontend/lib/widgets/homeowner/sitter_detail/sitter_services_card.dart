import 'package:flutter/material.dart';

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
          for (final service in services) _ServiceRow(service: service),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});

  final SitterServiceItem service;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_serviceIcon(service.serviceType), color: AppColors.primaryRust, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              service.serviceType,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
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
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  IconData _serviceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'stay over night':
      case 'overnight sitting':
        return Icons.nights_stay_outlined;
      case 'walk dog':
      case 'dog walking':
        return Icons.directions_walk;
      case 'feed dog':
      case 'drop-in visit':
        return Icons.restaurant_outlined;
      default:
        return Icons.pets;
    }
  }
}