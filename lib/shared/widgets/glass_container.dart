import 'package:flutter/material.dart';
import 'dart:ui';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 10,
    this.opacity = 0.1,
    this.borderColor,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient ?? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Colors.white.withOpacity(opacity), Colors.white.withOpacity(opacity * 0.5)]
                    : [Colors.black.withOpacity(0.02), Colors.black.withOpacity(0.01)],
              ),
              borderRadius: borderRadius ?? BorderRadius.circular(20),
              border: Border.all(
                color: borderColor ?? (isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08)),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
  final VoidCallback onPressed;
  final IconData? icon;
  final Gradient? gradient;
  final double? width;
  final double height;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.gradient,
    this.width,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient ?? const LinearGradient(colors: [Color(0xFFE50914), Color(0xFFFF3D47)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (gradient != null ? const Color(0xFF6C63FF) : const Color(0xFFE50914)).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
              ],
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

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4)),
              prefixIcon: Icon(prefixIcon, color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.5)),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFFF4757), width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ),
    );
  }
}
