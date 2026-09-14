import 'package:flutter/material.dart';

/// Shared app-bar geometry used by detail and settings-style screens.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) => AppBar(
    leading: showBack
        ? IconButton(
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          )
        : null,
    title: subtitle == null
        ? Text(title, style: titleStyle)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle),
              Text(
                subtitle!,
                style:
                    subtitleStyle ??
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
    actions: actions,
  );

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
