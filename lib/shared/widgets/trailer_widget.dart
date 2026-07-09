import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/app_config.dart';

class TrailerWidget extends StatelessWidget {
  final List<Map<String, dynamic>> videos;

  const TrailerWidget({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    final trailers = videos.where((v) => 
      v['site'] == 'YouTube' && (v['type'] == 'Trailer' || v['type'] == 'Teaser')
    ).toList();

    if (trailers.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Trailers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: trailers.length,
            itemBuilder: (context, index) {
              final trailer = trailers[index];
              final key = trailer['key'] ?? '';
              final name = trailer['name'] ?? 'Trailer';
              final thumbnailUrl = 'https://img.youtube.com/vi/$key/0.jpg';

              return GestureDetector(
                onTap: () => _playTrailer(key),
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.cardBg(context),
                            child: const Center(child: Icon(Icons.videocam, color: Colors.white24, size: 40)),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Center(
                          child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _playTrailer(String key) async {
    final url = Uri.parse('https://www.youtube.com/watch?v=$key');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class WatchProvidersWidget extends StatelessWidget {
  final Map<String, dynamic>? providers;

  const WatchProvidersWidget({super.key, this.providers});

  @override
  Widget build(BuildContext context) {
    if (providers == null) return const SizedBox();

    final results = providers!['results'] as Map<String, dynamic>? ?? {};
    
    // Try US first, then any country
    final countryData = results['US'] ?? results.values.firstOrNull;
    if (countryData == null) return const SizedBox();

    final flatrate = countryData['flatrate'] as List? ?? [];
    final rent = countryData['rent'] as List? ?? [];
    final buy = countryData['buy'] as List? ?? [];

    if (flatrate.isEmpty && rent.isEmpty && buy.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Where to Watch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        const SizedBox(height: 12),
        if (flatrate.isNotEmpty) ...[
          Text('Stream', style: TextStyle(fontSize: 14, color: AppColors.textSecondary(context), fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _buildProviderRow(context, flatrate),
          const SizedBox(height: 12),
        ],
        if (rent.isNotEmpty) ...[
          Text('Rent', style: TextStyle(fontSize: 14, color: AppColors.textSecondary(context), fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _buildProviderRow(context, rent),
          const SizedBox(height: 12),
        ],
        if (buy.isNotEmpty) ...[
          Text('Buy', style: TextStyle(fontSize: 14, color: AppColors.textSecondary(context), fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _buildProviderRow(context, buy),
        ],
      ],
    );
  }

  Widget _buildProviderRow(BuildContext context, List providers) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: providers.length,
        itemBuilder: (context, index) {
          final provider = providers[index];
          final logoPath = provider['logo_path'];
          final name = provider['provider_name'] ?? '';

          return Container(
            width: 50,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.cardBg(context),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: logoPath != null
                  ? Image.network(
                      AppConfig.getImageUrl(logoPath, size: 'w92'),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(child: Text(name.isNotEmpty ? name.substring(0, name.length.clamp(0, 2)) : '?', style: TextStyle(color: AppColors.text(context), fontSize: 10))),
                    )
                  : Center(child: Text(name.isNotEmpty ? name.substring(0, name.length.clamp(0, 2)) : '?', style: TextStyle(color: AppColors.text(context), fontSize: 10))),
            ),
          );
        },
      ),
    );
  }
}
