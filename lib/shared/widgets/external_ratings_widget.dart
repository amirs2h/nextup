import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ExternalRatingsWidget extends StatelessWidget {
  final String? imdbId;
  final int? rottenTomatoesScore;
  final String? imdbRating;
  final String? contentRating;
  final int voteCount;

  const ExternalRatingsWidget({
    super.key,
    this.imdbId,
    this.rottenTomatoesScore,
    this.imdbRating,
    this.contentRating,
    this.voteCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          if (imdbRating != null && imdbRating != 'N/A')
            _buildRatingChip(
              context,
              label: 'IMDB',
              value: imdbRating!,
              color: const Color(0xFFF5C518),
              icon: Icons.movie,
            ),
          if (rottenTomatoesScore != null)
            _buildRatingChip(
              context,
              label: 'RT',
              value: '$rottenTomatoesScore%',
              color: rottenTomatoesScore! >= 60
                  ? const Color(0xFF5C7C2E)
                  : rottenTomatoesScore! >= 40
                      ? const Color(0xFFFFD93D)
                      : const Color(0xFFFA320A),
              icon: rottenTomatoesScore! >= 60 ? Icons.thumb_up : Icons.thumb_down,
            ),
          if (contentRating != null && contentRating!.isNotEmpty)
            _buildContentRatingBadge(context, contentRating!),
          if (voteCount > 0)
            _buildVoteCountChip(context),
        ],
      ),
    );
  }

  Widget _buildRatingChip(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildContentRatingBadge(BuildContext context, String rating) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield, color: AppColors.textSecondary(context), size: 16),
          const SizedBox(height: 4),
          Text('Rating', style: TextStyle(color: AppColors.textMuted(context), fontSize: 10, fontWeight: FontWeight.w600)),
          Text(rating, style: TextStyle(color: AppColors.text(context), fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildVoteCountChip(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people, color: AppColors.textSecondary(context), size: 16),
          const SizedBox(height: 4),
          Text('Votes', style: TextStyle(color: AppColors.textMuted(context), fontSize: 10, fontWeight: FontWeight.w600)),
          Text(_formatVoteCount(voteCount), style: TextStyle(color: AppColors.text(context), fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatVoteCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
