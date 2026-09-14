import 'package:flutter/material.dart';

/// Compact metric tile shared by summary cards.
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final IconData icon;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
              Icon(icon, size: 16, color: colors.primary),
            ],
          ),
          const SizedBox(height: 5),
          Text.rich(
            TextSpan(
              text: value,
              children: suffix == null
                  ? const []
                  : [
                      TextSpan(
                        text: ' $suffix',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
            ),
            style: theme.textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
