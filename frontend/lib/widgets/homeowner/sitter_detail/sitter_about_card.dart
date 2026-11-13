import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'sitter_detail_card.dart';

class SitterAboutCard extends StatefulWidget {
  const SitterAboutCard({super.key, required this.experience});

  final String experience;

  @override
  State<SitterAboutCard> createState() => _SitterAboutCardState();
}

class _SitterAboutCardState extends State<SitterAboutCard> {
  static const int _collapsedLines = 4;
  static const TextStyle _textStyle = TextStyle(fontSize: 13, height: 1.5, color: Colors.black87);

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return SitterDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SitterSectionTitle('About & experience'),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              // Only offer "Read more" when the text really runs past the collapsed height.
              final painter = TextPainter(
                text: TextSpan(text: widget.experience, style: _textStyle),
                maxLines: _collapsedLines,
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(maxWidth: constraints.maxWidth);
              final overflows = painter.didExceedMaxLines;
              painter.dispose();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: Text(
                      widget.experience,
                      style: _textStyle,
                      maxLines: _expanded ? null : _collapsedLines,
                      overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ),
                  if (overflows)
                    TextButton(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.only(top: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.primaryRust,
                      ),
                      child: Text(
                        _expanded ? 'Show less' : 'Read more',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
