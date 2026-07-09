import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double opacity;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final bool useBlur;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.opacity = 0.08,
    this.borderColor,
    this.boxShadow,
    this.gradient,
    this.useBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final radius = borderRadius ?? BorderRadius.circular(16);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: useBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: _buildContent(context, isDark, radius),
              )
            : _buildContent(context, isDark, radius),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, BorderRadius radius) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient ?? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.white.withValues(alpha: opacity), Colors.white.withValues(alpha: opacity * 0.5)]
              : [Colors.white.withValues(alpha: 0.85), Colors.white.withValues(alpha: 0.65)],
        ),
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.5)),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: GlassContainer(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(16),
        margin: margin,
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient? gradient;
  final double? width;
  final double height;

  const GlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.gradient,
    this.width,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isDisabled = onPressed == null;
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDisabled ? [] : [
          BoxShadow(
            color: (gradient != null ? AppColors.electricPurple : AppColors.primary).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: isDisabled ? null : gradient ?? LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.85 : 0.9),
                  AppColors.primaryLight.withValues(alpha: isDark ? 0.75 : 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              color: isDisabled ? AppColors.textMuted(context).withValues(alpha: 0.3) : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDisabled ? AppColors.border(context) : Colors.white.withValues(alpha: 0.15)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: isDisabled ? AppColors.textMuted(context) : Colors.white, size: 22),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: TextStyle(color: isDisabled ? AppColors.textMuted(context) : Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            maxLines: maxLines,
            style: TextStyle(color: AppColors.text(context)),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: AppColors.textMuted(context)),
              prefixIcon: Icon(prefixIcon, color: AppColors.textMuted(context)),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: AppColors.glassBg(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.glassBorder(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.electricPurple, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.error, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.error, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
