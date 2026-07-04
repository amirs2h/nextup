import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final bool allowRating;
  final ValueChanged<double>? onRatingChanged;

  const StarRating({
    super.key,
    this.rating = 0,
    this.size = 24,
    this.allowRating = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(10, (index) {
        final starValue = index + 1.0;
        final isHalfStar = rating >= starValue - 0.5 && rating < starValue;
        final isFullStar = rating >= starValue;

        return GestureDetector(
          onTap: allowRating ? () => onRatingChanged?.call(starValue) : null,
          child: Icon(
            isFullStar
                ? Icons.star_rounded
                : isHalfStar
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            color: isFullStar || isHalfStar ? const Color(0xFFFFD93D) : AppColors.textMuted(context),
            size: size,
          ),
        );
      }),
    );
  }
}

class RatingDisplay extends StatelessWidget {
  final double rating;
  final int? voteCount;
  final double size;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.voteCount,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: const Color(0xFFFFD93D), size: size),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            color: AppColors.text(context),
            fontSize: size * 0.85,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (voteCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($voteCount)',
            style: TextStyle(
              color: AppColors.textMuted(context),
              fontSize: size * 0.7,
            ),
          ),
        ],
      ],
    );
  }
}

class RatingDialog extends StatefulWidget {
  final double initialRating;
  final String title;

  const RatingDialog({
    super.key,
    this.initialRating = 0,
    required this.title,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Rate ${widget.title}',
        style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _rating > 0 ? '${_rating.toStringAsFixed(0)} / 10' : 'Tap to rate',
            style: TextStyle(
              color: _rating > 0 ? const Color(0xFFFFD93D) : AppColors.textMuted(context),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          StarRating(
            rating: _rating,
            size: 36,
            allowRating: true,
            onRatingChanged: (value) => setState(() => _rating = value),
          ),
          const SizedBox(height: 8),
          Text(
            _getRatingLabel(_rating),
            style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context))),
        ),
        ElevatedButton(
          onPressed: _rating > 0 ? () => Navigator.pop(context, _rating) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE50914),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Rate'),
        ),
      ],
    );
  }

  String _getRatingLabel(double rating) {
    if (rating == 0) return '';
    if (rating <= 2) return 'Terrible';
    if (rating <= 4) return 'Bad';
    if (rating <= 6) return 'Okay';
    if (rating <= 8) return 'Good';
    if (rating <= 9) return 'Great';
    return 'Masterpiece';
  }
}
