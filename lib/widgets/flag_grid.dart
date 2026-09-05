import 'package:flutter/material.dart';

class FlagGrid extends StatelessWidget {
  const FlagGrid({
    super.key,
    required this.flags,
    required this.selected,
    required this.onToggle,
  });

  final List<String> flags;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final columns = constraints.maxWidth >= 520 ? 3 : 2;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final flag in flags)
                    SizedBox(
                      width: width,
                      child: FlagButton(
                        flag: flag,
                        selected: selected.contains(flag),
                        onPressed: () => onToggle(flag),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class FlagButton extends StatelessWidget {
  const FlagButton({
    super.key,
    required this.flag,
    required this.selected,
    required this.onPressed,
  });

  final String flag;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return FilledButton(
      key: Key('flag-$flag'),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: selected
            ? Colors.redAccent
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: selected ? Colors.white : onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        flag,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
