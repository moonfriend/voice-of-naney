import 'package:flutter/material.dart';

/// A round badge with a count, used for single places and for clusters.
class CountBadge extends StatelessWidget {
  const CountBadge({required this.count, this.selected = false, this.label, super.key});

  final int count;
  final bool selected;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? colors.tertiary : colors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: colors.surface, width: 2),
          boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Center(
          child: Text(
            '$count',
            style: TextStyle(
              color: selected ? colors.onTertiary : colors.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
