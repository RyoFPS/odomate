import 'package:flutter/material.dart';

/// Consistent period selector used by history and statistics screens.
class DateRangeChips extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const DateRangeChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          ChoiceChip(
            label: Text(labels[index], textAlign: TextAlign.center),
            selected: index == selectedIndex,
            showCheckmark: false,
            onSelected: (_) => onSelected(index),
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFFEFF6FF),
            side: BorderSide(
              color: index == selectedIndex
                  ? const Color(0xFFBFDBFE)
                  : const Color(0xFFE2E8F0),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            labelStyle: TextStyle(
              color: index == selectedIndex
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF475569),
              fontSize: 12,
              fontWeight: index == selectedIndex
                  ? FontWeight.w600
                  : FontWeight.w500,
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ],
    ),
  );
}
