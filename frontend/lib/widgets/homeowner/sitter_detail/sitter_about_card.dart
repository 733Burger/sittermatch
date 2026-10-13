import 'package:flutter/material.dart';

import 'sitter_detail_card.dart';

class SitterAboutCard extends StatelessWidget {
  const SitterAboutCard({super.key, required this.experience});

  final String experience;

  @override
  Widget build(BuildContext context) {
    return SitterDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SitterSectionTitle('About & experience'),
          const SizedBox(height: 10),
          Text(
            experience,
            style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}