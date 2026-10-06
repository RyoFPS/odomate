import 'package:flutter/material.dart';

class RideControlButton extends StatefulWidget {
  final bool active;
  final String label;
  final VoidCallback? onPressed;
  final bool floating;

  const RideControlButton({
    super.key,
    required this.active,
    required this.label,
    required this.onPressed,
    this.floating = false,
  });

  @override
  State<RideControlButton> createState() => _RideControlButtonState();
}

class _RideControlButtonState extends State<RideControlButton>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final _scale = Tween<double>(
    begin: 1,
    end: 1.07,
  ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant RideControlButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) _syncPulse();
  }

  void _syncPulse() {
    if (widget.active && !MediaQuery.of(context).disableAnimations) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = widget.active ? colors.error : colors.primary;
    final foreground = widget.active ? colors.onError : colors.onPrimary;
    final control = widget.floating
        ? SizedBox.square(
            dimension: 64,
            child: FloatingActionButton(
              shape: const CircleBorder(),
              elevation: 6,
              backgroundColor: background,
              foregroundColor: foreground,
              onPressed: widget.onPressed,
              tooltip: widget.label,
              child: Icon(widget.active ? Icons.stop : Icons.play_arrow),
            ),
          )
        : SizedBox(
            width: double.infinity,
            height: 64,
            child: FilledButton.icon(
              onPressed: widget.onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: background,
                foregroundColor: foreground,
              ),
              icon: Icon(widget.active ? Icons.stop : Icons.play_arrow),
              label: Text(widget.label),
            ),
          );

    if (widget.active && !MediaQuery.of(context).disableAnimations) {
      return ScaleTransition(scale: _scale, child: control);
    }
    return control;
  }
}
