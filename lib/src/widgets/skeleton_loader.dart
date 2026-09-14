import 'package:flutter/material.dart';

/// Lightweight loading placeholder that keeps the page layout stable while
/// local data is read. It deliberately uses only Flutter primitives.
class SkeletonLoader extends StatelessWidget {
  final int rows;
  final bool inline;

  const SkeletonLoader({super.key, this.rows = 3}) : inline = false;

  const SkeletonLoader.inline({super.key}) : rows = 0, inline = true;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    if (inline) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _box(color, width: 72, height: 12),
          const SizedBox(width: 8),
          _box(color, width: 42, height: 12),
        ],
      );
    }
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Row(
          children: [
            _box(color, width: 86, height: 34),
            const SizedBox(width: 8),
            _box(color, width: 86, height: 34),
            const SizedBox(width: 8),
            _box(color, width: 110, height: 34),
          ],
        ),
        const SizedBox(height: 16),
        _card(color, height: 150),
        const SizedBox(height: 18),
        _box(color, width: 150, height: 20),
        const SizedBox(height: 10),
        for (var index = 0; index < rows; index++) ...[
          _card(color, height: 110),
          if (index < rows - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  static Widget _card(Color color, {required double height}) => Container(
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _box(color, width: 120, height: 14),
        const SizedBox(height: 12),
        _box(color, width: double.infinity, height: 18),
        const SizedBox(height: 8),
        _box(color, width: 180, height: 14),
      ],
    ),
  );

  static Widget _box(
    Color color, {
    required double width,
    required double height,
  }) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}
