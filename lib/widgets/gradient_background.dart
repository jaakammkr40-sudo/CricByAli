import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool addSafeArea;

  const GradientBackground({
    super.key,
    required this.child,
    this.addSafeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: addSafeArea ? SafeArea(child: child) : child,
    );
  }
}
