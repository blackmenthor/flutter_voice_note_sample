import 'package:flutter/material.dart';

class AnimatedSizeIcon extends StatefulWidget {
  const AnimatedSizeIcon({
    Key? key,
    required this.iconData,
    this.startSize = 56.0,
    this.endSize = 96.0,
    this.duration = const Duration(seconds: 3),
    this.color,
  }) : super(key: key);

  final IconData iconData;
  final double startSize;
  final double endSize;
  final Duration duration;
  final Color? color;

  @override
  State<AnimatedSizeIcon> createState() => _AnimatedSizeIconState();
}

class _AnimatedSizeIconState extends State<AnimatedSizeIcon>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;
  late Animation<double> animation;
  late Duration animDuration = widget.duration;
  late double sizeStart = widget.startSize;
  late double sizeEnd = widget.endSize;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
        vsync: this,
        duration: animDuration,
        reverseDuration: animDuration,
    );
    animation = Tween<double>(
        begin: sizeStart,
        end: sizeEnd,
    ).animate(controller);

    controller.forward();
    animation.addListener(() {
      if (animation.isCompleted) {
        controller.reverse();
      } else if (animation.isDismissed) {
        controller.forward();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      widget.iconData,
      size: animation.value,
      color: widget.color,
    );
  }
}
