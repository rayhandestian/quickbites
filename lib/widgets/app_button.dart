import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum ButtonType { primary, secondary, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? width;
  final double height;
  final EdgeInsets? padding;

  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.width,
    this.height = 50,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonWidth = isFullWidth 
        ? double.infinity 
        : width;

    final buttonPadding = padding ?? 
        const EdgeInsets.symmetric(vertical: 12, horizontal: 16);

    final textColor = type == ButtonType.primary
        ? Colors.white
        : type == ButtonType.secondary
            ? AppColors.primaryAccent
            : AppColors.primaryAccent;

    final backgroundColor = type == ButtonType.primary
        ? AppColors.primaryAccent
        : type == ButtonType.secondary
            ? Colors.transparent
            : Colors.transparent;

    final border = type == ButtonType.secondary
        ? Border.all(color: AppColors.primaryAccent, width: 1.5)
        : null;

    final buttonContent = isLoading
        ? SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    return SizedBox(
      width: buttonWidth,
      height: height,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: buttonPadding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: border,
            ),
            child: Center(child: buttonContent),
          ),
        ),
      ),
    );
  }
} 