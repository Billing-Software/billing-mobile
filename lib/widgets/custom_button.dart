import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum CustomButtonVariant { filled, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final CustomButtonVariant variant;
  final bool fullWidth;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.icon,
    this.variant = CustomButtonVariant.filled,
    this.fullWidth = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? const Color(0xFF006A61);
    final foreground = textColor ?? (variant == CustomButtonVariant.filled ? Colors.white : primaryColor);

    Widget content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    final minSize = Size(fullWidth ? double.infinity : 0, 48);

    switch (variant) {
      case CustomButtonVariant.outline:
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: foreground,
            side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
            shape: shape,
            minimumSize: minSize,
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          onPressed: isLoading ? null : onPressed,
          child: content,
        );
      case CustomButtonVariant.text:
        return TextButton(
          style: TextButton.styleFrom(
            foregroundColor: foreground,
            shape: shape,
            minimumSize: minSize,
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          onPressed: isLoading ? null : onPressed,
          child: content,
        );
      case CustomButtonVariant.filled:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: foreground,
            elevation: 0,
            shape: shape,
            minimumSize: minSize,
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          onPressed: isLoading ? null : onPressed,
          child: content,
        );
    }
  }
}
