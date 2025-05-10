import 'package:flutter/material.dart';
import 'dart:math' as math;

class WirelessAnimation extends StatefulWidget {
  final double size;
  final Color color;
  final int waveCount;
  final double opacity;

  const WirelessAnimation({
    Key? key,
    this.size = 300.0,
    this.color = Colors.blue,
    this.waveCount = 3,
    this.opacity = 0.3,
  }) : super(key: key);

  @override
  State<WirelessAnimation> createState() => _WirelessAnimationState();
}

class _WirelessAnimationState extends State<WirelessAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _animationControllers = List.generate(
      widget.waveCount,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2000 + (index * 200)),
      ),
    );

    _animations = _animationControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Stagger the start of each animation
    for (int i = 0; i < _animationControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        if (mounted) {
          _animationControllers[i].repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(widget.waveCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Opacity(
                opacity: math.max(
                    0,
                    widget.opacity -
                        (_animations[index].value * widget.opacity)),
                child: Container(
                  width: widget.size * _animations[index].value,
                  height: widget.size * _animations[index].value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withOpacity(
                        math.max(0, 1.0 - _animations[index].value),
                      ),
                      width: 2.0,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
