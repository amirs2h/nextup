import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import 'glass_container.dart';

class ModernShowCard extends StatelessWidget {
  final int id;
  final String title;
  final String? posterPath;
  final double rating;
  final VoidCallback onTap;
  final bool isMovie;

  const ModernShowCard({
    super.key,
    required this.id,
    required this.title,
    this.posterPath,
    required this.rating,
    required this.onTap,
    this.isMovie = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: posterPath != null
                    ? CachedNetworkImage(
                        imageUrl: AppConfig.getImageUrl(posterPath, size: 'w500'),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: AppColors.cardBg(context),
                          highlightColor: AppColors.cardBgStrong(context),
                          child: Container(color: AppColors.cardBg(context)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.cardBg(context),
                          child: Center(child: Icon(Icons.movie_rounded, color: AppColors.iconMuted(context), size: 40)),
                        ),
                      )
                    : Container(
                        color: AppColors.cardBg(context),
                        child: Center(child: Icon(Icons.movie_rounded, color: AppColors.iconMuted(context), size: 40)),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.text(context), fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
              const SizedBox(width: 4),
              Text(rating.toStringAsFixed(1), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
          ],
        ),
      ),
    );
  }
}

class ModernEpisodeCard extends StatelessWidget {
  final int episodeNumber;
  final String title;
  final String? stillPath;
  final int? runtime;
  final bool isWatched;
  final VoidCallback onTap;
  final VoidCallback onWatchToggle;

  const ModernEpisodeCard({
    super.key,
    required this.episodeNumber,
    required this.title,
    this.stillPath,
    this.runtime,
    required this.isWatched,
    required this.onTap,
    required this.onWatchToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(16),
      borderColor: isWatched ? AppColors.success.withOpacity(0.3) : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                width: 120,
                height: 68,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.cardBg(context)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: stillPath != null
                      ? CachedNetworkImage(
                          imageUrl: AppConfig.getImageUrl(stillPath, size: 'w300'),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: AppColors.cardBg(context),
                            highlightColor: AppColors.cardBgStrong(context),
                            child: Container(color: AppColors.cardBg(context)),
                          ),
                          errorWidget: (context, url, error) => Center(child: Icon(Icons.play_circle_outline, color: AppColors.iconMuted(context))),
                        )
                      : Center(child: Icon(Icons.play_circle_outline, color: AppColors.iconMuted(context))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('E$episodeNumber • $title', style: TextStyle(color: isWatched ? AppColors.textMuted(context) : AppColors.text(context), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (runtime != null) ...[
                      const SizedBox(height: 4),
                      Text('$runtime min', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onWatchToggle();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isWatched ? AppColors.success.withOpacity(0.2) : AppColors.cardBg(context),
                    border: Border.all(color: isWatched ? AppColors.success : AppColors.border(context)),
                  ),
                  child: Icon(
                    isWatched ? Icons.check_circle : Icons.add_circle_outline,
                    color: isWatched ? AppColors.success : AppColors.iconMuted(context),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModernGenreChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ModernGenreChip({
    super.key,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.purpleGradient : null,
          color: isSelected ? null : AppColors.glassBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : AppColors.glassBorder(context)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary(context), fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class ModernSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;

  const ModernSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onClear,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      borderRadius: BorderRadius.circular(16),
      height: 52,
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.textMuted(context), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(color: AppColors.text(context)),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: AppColors.textMuted(context)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.close_rounded, color: AppColors.textMuted(context), size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

class RatingBadge extends StatelessWidget {
  final double rating;
  final double size;

  const RatingBadge({
    super.key,
    required this.rating,
    this.size = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.ratingColor(rating);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * size, vertical: 4 * size),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6 * size),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: color, size: 14 * size),
          SizedBox(width: 3 * size),
          Text(rating.toStringAsFixed(1), style: TextStyle(color: color, fontSize: 12 * size, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardBg(context),
      highlightColor: AppColors.cardBgStrong(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}
