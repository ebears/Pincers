import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: AppConstants.typingLoopMs),
      );
      Future.delayed(Duration(milliseconds: i * AppConstants.typingStaggerMs), () {
        if (mounted) controller.repeat(reverse: true);
      });
      return controller;
    });
    _animations = _controllers.map((c) =>
        Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: c, curve: Curves.easeInOut),
        )).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.space12,
        horizontal: AppConstants.space16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.space16,
              vertical: AppConstants.space12,
            ),
            decoration: BoxDecoration(
              color: AppColors.botBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.radiusSmall),
                topRight: Radius.circular(AppConstants.radiusBubble),
                bottomLeft: Radius.circular(AppConstants.radiusBubble),
                bottomRight: Radius.circular(AppConstants.radiusBubble),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Padding(
                padding: EdgeInsets.only(left: i > 0 ? 4.0 : 0),
                child: AnimatedBuilder(
                  animation: _animations[i],
                  builder: (context, child) => Transform.scale(
                    scale: _animations[i].value,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.typing,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}
