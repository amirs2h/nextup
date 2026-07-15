import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/stats_cubit.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  @override
  void initState() {
    super.initState();
    context.read<StatsCubit>().loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: GlassContainer(
              padding: const EdgeInsets.all(10),
              borderRadius: BorderRadius.circular(14),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text(context), size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Text('Statistics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<StatsCubit, StatsState>(
      builder: (context, state) {
        if (state is StatsLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is StatsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<StatsCubit>().loadStats(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is StatsLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<StatsCubit>().loadStats();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewCards(context, state),
                  const SizedBox(height: 20),
                  _buildWatchTimeChart(context, state),
                  const SizedBox(height: 20),
                  _buildDistributionChart(context, state),
                  const SizedBox(height: 20),
                  if (state.topGenres.isNotEmpty) ...[
                    _buildTopGenres(context, state),
                    const SizedBox(height: 20),
                  ],
                  _buildInsights(context, state),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildOverviewCards(BuildContext context, StatsLoaded stats) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, 'Shows', stats.totalShows.toString(), Icons.tv_rounded, const Color(0xFF6C63FF))),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard(context, 'Movies', stats.totalMovies.toString(), Icons.movie_rounded, const Color(0xFFE50914))),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard(context, 'Episodes', stats.totalEpisodes.toString(), Icons.play_circle_rounded, const Color(0xFF00D4FF))),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard(context, 'Hours', stats.totalHours.toString(), Icons.access_time_rounded, const Color(0xFFFFD93D))),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
            child: Center(child: Icon(icon, color: color, size: 18)),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          Text(label, style: TextStyle(color: AppColors.textMuted(context), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildWatchTimeChart(BuildContext context, StatsLoaded stats) {
    final now = DateTime.now();
    final months = <String>[];
    final values = <double>[];

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      months.add(monthNames[date.month - 1]);
      values.add((stats.monthlyWatched[monthKey] ?? 0).toDouble());
    }

    final maxY = values.reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxY > 0 ? maxY * 1.3 : 10.0;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Watch Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Last 6 months', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMaxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${months[group.x]}\n${rod.toY.toInt()} items',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(months[value.toInt()], style: TextStyle(color: AppColors.textMuted(context), fontSize: 11)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(6, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: values[index],
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.6),
                            AppColors.primary,
                          ],
                        ),
                        width: 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionChart(BuildContext context, StatsLoaded stats) {
    final total = stats.totalShows + stats.totalMovies;
    if (total == 0) return const SizedBox();

    final showPercent = total > 0 ? (stats.totalShows / total * 100).round() : 0;
    final moviePercent = total > 0 ? (stats.totalMovies / total * 100).round() : 0;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Content Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 35,
                    sections: [
                      PieChartSectionData(
                        value: stats.totalShows.toDouble(),
                        color: const Color(0xFF6C63FF),
                        radius: 30,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: stats.totalMovies.toDouble(),
                        color: const Color(0xFFE50914),
                        radius: 30,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem('TV Shows', stats.totalShows, showPercent, const Color(0xFF6C63FF)),
                    const SizedBox(height: 12),
                    _buildLegendItem('Movies', stats.totalMovies, moviePercent, const Color(0xFFE50914)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, int percent, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: TextStyle(color: AppColors.text(context), fontSize: 14)),
        ),
        Text('$count', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 8),
        Text('$percent%', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
      ],
    );
  }

  Widget _buildTopGenres(BuildContext context, StatsLoaded stats) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category_rounded, color: AppColors.electricPurple, size: 20),
              const SizedBox(width: 8),
              Text('Top Genres', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            ],
          ),
          const SizedBox(height: 16),
          ...stats.topGenres.asMap().entries.map((entry) {
            final index = entry.key;
            final genre = entry.value;
            final name = genre['name'] ?? '';
            final count = genre['count'] as int;
            final maxCount = stats.topGenres.first['count'] as int;
            final progress = maxCount > 0 ? count / maxCount : 0.0;
            final colors = [
              const Color(0xFF6C63FF),
              const Color(0xFFE50914),
              const Color(0xFF00D4FF),
              const Color(0xFFFFD93D),
              const Color(0xFF00FF88),
            ];
            final color = colors[index % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('#${index + 1}', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(name, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w500, fontSize: 14)),
                            Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.border(context),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsights(BuildContext context, StatsLoaded stats) {
    final totalItems = stats.totalShows + stats.totalMovies;
    final avgEpisodesPerShow = stats.totalShows > 0 ? (stats.totalEpisodes / stats.totalShows).round() : 0;
    final avgHoursPerDay = stats.totalHours > 0 ? (stats.totalHours / 365).toStringAsFixed(1) : '0';

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text('Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightRow(Icons.movie_rounded, 'Total Content', '$totalItems items', const Color(0xFF6C63FF)),
          _buildInsightRow(Icons.play_circle_rounded, 'Avg Episodes/Show', '$avgEpisodesPerShow episodes', const Color(0xFF00D4FF)),
          _buildInsightRow(Icons.access_time_rounded, 'Avg Watch Time', '$avgHoursPerDay hrs/day', const Color(0xFFFFD93D)),
          _buildInsightRow(Icons.local_fire_department_rounded, 'Longest Streak', 'Coming soon', AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(icon, color: color, size: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: AppColors.text(context), fontSize: 14)),
          ),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
