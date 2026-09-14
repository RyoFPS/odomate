import 'package:flutter/material.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bar(color, 24),
          const SizedBox(height: 16),
          _bar(color, 72),
          const SizedBox(height: 12),
          _bar(color, 72),
          const SizedBox(height: 12),
          _bar(color, 72),
        ],
      ),
    );
  }

  static Widget _bar(Color color, double height) => ColoredBox(
    color: color,
    child: SizedBox(height: height),
  );
}
