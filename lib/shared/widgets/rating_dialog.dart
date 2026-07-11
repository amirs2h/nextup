import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

void showRatingDialog({
  required BuildContext context,
  required String title,
  required Future<void> Function(double rating) onRate,
}) {
  double rating = 0;
  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rate $title', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rating > 0 ? '${rating.toStringAsFixed(0)} / 10' : 'Tap to rate',
              style: TextStyle(
                color: rating > 0 ? const Color(0xFFFFD93D) : AppColors.textMuted(context),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(10, (index) {
                  final starValue = index + 1.0;
                  return GestureDetector(
                    onTap: () => setState(() => rating = starValue),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Icon(
                        rating >= starValue ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: rating >= starValue ? const Color(0xFFFFD93D) : AppColors.textMuted(context),
                        size: 24,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface(context),
              foregroundColor: AppColors.text(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: rating > 0 ? () async {
              final currentRating = rating;
              Navigator.pop(dialogContext);
              try {
                await onRate(currentRating);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Rated $currentRating/10'), backgroundColor: const Color(0xFF00FF88), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Failed to save rating'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  );
                }
              }
            } : null,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Rate'),
          ),
        ],
      ),
    ),
  );
}
