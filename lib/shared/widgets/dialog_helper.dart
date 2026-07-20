import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DialogHelper {
  /// Standard cancel button for all dialogs
  static Widget cancelButton(BuildContext context, {VoidCallback? onPressed}) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed ?? () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.border(context)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  /// Standard confirm/primary button for all dialogs
  static Widget confirmButton(BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
    Color? color,
    IconData? icon,
  }) {
    final btnColor = color ?? AppColors.electricPurple;
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }

  /// Standard danger/red button (delete, remove, leave)
  static Widget dangerButton(BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }

  /// Standard actions row (Cancel + Confirm) — equal width buttons
  static List<Widget> cancelConfirmActions(BuildContext context, {
    required String confirmLabel,
    required VoidCallback? onConfirm,
    Color? confirmColor,
    IconData? confirmIcon,
  }) {
    return [
      Expanded(child: cancelButton(context)),
      const SizedBox(width: 12),
      Expanded(child: confirmButton(
        context,
        label: confirmLabel,
        onPressed: onConfirm,
        color: confirmColor,
        icon: confirmIcon,
      )),
    ];
  }

  /// Standard actions row (Cancel + Danger) — equal width buttons
  static List<Widget> cancelDangerActions(BuildContext context, {
    required String dangerLabel,
    required VoidCallback? onDanger,
    IconData? dangerIcon,
  }) {
    return [
      Expanded(child: cancelButton(context)),
      const SizedBox(width: 12),
      Expanded(child: dangerButton(
        context,
        label: dangerLabel,
        onPressed: onDanger,
        icon: dangerIcon,
      )),
    ];
  }

  /// Standard dialog title with icon
  static Widget titleWithIcon(IconData icon, Color color, String title) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// Standard text field for dialogs
  static Widget dialogTextField({
    required TextEditingController controller,
    required String hintText,
    required BuildContext context,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: AppColors.text(context)),
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.textMuted(context)),
        filled: true,
        fillColor: AppColors.cardBg(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.electricPurple, width: 1.5),
        ),
      ),
    );
  }
}
