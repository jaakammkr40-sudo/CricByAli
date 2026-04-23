import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isGold;
  final bool isOutlined;
  final bool isFullWidth;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isGold = false,
    this.isOutlined = false,
    this.isFullWidth = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) return _outlined();
    return _filled();
  }

  Widget _filled() {
    return Container(
      width: isFullWidth ? double.infinity : width,
      decoration: BoxDecoration(
        gradient: isGold ? AppColors.goldGradient : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (isGold ? AppColors.secondary : AppColors.primary)
                .withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        icon: icon != null
            ? Icon(icon, size: 20, color: isGold ? Colors.black87 : Colors.white)
            : const SizedBox.shrink(),
        label: Text(
          label,
          style: TextStyle(
            color: isGold ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _outlined() {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.secondary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: icon != null
            ? Icon(icon, size: 20, color: AppColors.secondary)
            : const SizedBox.shrink(),
        label: Text(
          label,
          style: const TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
