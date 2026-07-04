import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/config/app_config.dart';

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
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: posterPath != null
                    ? CachedNetworkImage(
                        imageUrl: '${AppConfig.tmdbImageBaseUrl}${AppConfig.tmdbPosterSize}$posterPath',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[800]!,
                          highlightColor: Colors.grey[700]!,
                          child: Container(color: Colors.grey[800]),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(Icons.movie, color: Colors.white24, size: 40),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(Icons.movie, color: Colors.white24, size: 40),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            // Rating
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 16),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: isWatched
              ? const Color(0xFF00FF88).withOpacity(0.3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 120,
                  height: 68,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: stillPath != null
                        ? CachedNetworkImage(
                            imageUrl: '${AppConfig.tmdbImageBaseUrl}/w300$stillPath',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[800]!,
                              highlightColor: Colors.grey[700]!,
                              child: Container(color: Colors.grey[800]),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.play_circle_outline, color: Colors.white24),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.play_circle_outline, color: Colors.white24),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'E$episodeNumber • $title',
                        style: TextStyle(
                          color: isWatched ? Colors.white54 : Colors.white,
                          fontWeight: FontWeight.w500,
                          decoration: isWatched ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (runtime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$runtime min',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Watch Toggle
                GestureDetector(
                  onTap: onWatchToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isWatched
                          ? const Color(0xFF00FF88).withOpacity(0.2)
                          : Colors.white.withOpacity(0.08),
                      border: Border.all(
                        color: isWatched
                            ? const Color(0xFF00FF88)
                            : Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      isWatched ? Icons.check : Icons.check,
                      color: isWatched ? const Color(0xFF00FF88) : Colors.white24,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
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
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
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
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.5),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
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
                child: Icon(
                  Icons.close,
                  color: Colors.white.withOpacity(0.5),
                  size: 20,
                ),
              ),
            ),
          const SizedBox(width: 8),
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
    Color color;
    if (rating >= 7) {
      color = const Color(0xFF00FF88);
    } else if (rating >= 5) {
      color = const Color(0xFFFFD93D);
    } else {
      color = const Color(0xFFFF4757);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * size,
        vertical: 6 * size,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8 * size),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: color,
            size: 16 * size,
          ),
          SizedBox(width: 4 * size),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 14 * size,
              fontWeight: FontWeight.bold,
            ),
          ),
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
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.1),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}
