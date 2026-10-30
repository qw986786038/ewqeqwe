import 'package:flutter/material.dart';

class TopMenuAreaItem {
  TopMenuAreaItem({this.label, this.child})
    : assert(label != null || child != null);

  final String? label;
  final Widget? child;
}

class TopMenuAreaWidget extends StatefulWidget {
  const TopMenuAreaWidget({
    super.key,
    required this.items,
    this.initialSelectedIndex = 0,
    this.onSelected,
    this.overlap = 20,
    this.height = 40,
    this.tabMinWidth = 96,
    this.unselectedScale = 0.88,
    this.animationDuration = const Duration(milliseconds: 220),
  });

  final List<TopMenuAreaItem> items;
  final int initialSelectedIndex;
  final ValueChanged<int>? onSelected;
  final double overlap;
  final double height;
  final double tabMinWidth;
  final double unselectedScale;
  final Duration animationDuration;

  @override
  State<TopMenuAreaWidget> createState() => _TopMenuAreaWidgetState();
}

class _TopMenuAreaWidgetState extends State<TopMenuAreaWidget> {
  late int _selected = widget.initialSelectedIndex;

  List<int> _paintOrder(int count, int selected) {
    final List<int> order = <int>[];
    for (int i = count - 1; i >= 0; i--) {
      if (i != selected) {
        order.add(i);
      }
    }
    order.add(selected);
    return order;
  }

  void _onTap(int index) {
    if (_selected == index) {
      return;
    }
    setState(() => _selected = index);
    widget.onSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final int count = widget.items.length;
    if (count == 0) {
      return const SizedBox.shrink();
    }

    final int selected = _selected.clamp(0, count - 1);
    final double step = widget.tabMinWidth - widget.overlap;
    final double totalWidth = widget.tabMinWidth + (count - 1) * step;
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      height: widget.height,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomLeft,
        children: _paintOrder(count, selected).map((int index) {
          final bool isSelected = index == selected;
          final TopMenuAreaItem item = widget.items[index];

          return Positioned(
            key: ValueKey<int>(index),
            left: index * step,
            bottom: 0,
            child: _AnimatedScaleTab(
              selected: isSelected,
              unselectedScale: widget.unselectedScale,
              duration: widget.animationDuration,
              child: _TopMenuTab(
                height: widget.height,
                width: widget.tabMinWidth,
                selected: isSelected,
                duration: widget.animationDuration,
                onTap: () => _onTap(index),
                child:
                    item.child ??
                    Text(
                      item.label ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : null,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AnimatedScaleTab extends StatefulWidget {
  const _AnimatedScaleTab({
    required this.selected,
    required this.unselectedScale,
    required this.duration,
    required this.child,
  });

  final bool selected;
  final double unselectedScale;
  final Duration duration;
  final Widget child;

  @override
  State<_AnimatedScaleTab> createState() => _AnimatedScaleTabState();
}

class _AnimatedScaleTabState extends State<_AnimatedScaleTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.selected ? 1 : 0,
  );

  Animation<double> get _scale => Tween<double>(
    begin: widget.unselectedScale,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void didUpdateWidget(covariant _AnimatedScaleTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.selected != widget.selected) {
      if (widget.selected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Transform.scale(
          scale: _scale.value,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _TopMenuTab extends StatelessWidget {
  const _TopMenuTab({
    required this.height,
    required this.width,
    required this.selected,
    required this.duration,
    required this.onTap,
    required this.child,
  });

  final double height;
  final double width;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
        boxShadow: selected
            ? <BoxShadow>[
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.28),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
