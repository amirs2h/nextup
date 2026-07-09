import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../shared/widgets/glass_container.dart';

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
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
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardBg(context),
                border: Border.all(color: AppColors.border(context)),
              ),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildOverviewCards(context, state),
                  const SizedBox(height: 24),
                  _buildWatchTimeChart(context, state),
                  const SizedBox(height: 24),
                  _buildDistributionChart(context, state),
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(context, 'Shows', stats.totalShows.toString(), Icons.tv, AppColors.primary),
        _buildStatCard(context, 'Movies', stats.totalMovies.toString(), Icons.movie, AppColors.electricPurple),
        _buildStatCard(context, 'Episodes', stats.totalEpisodes.toString(), Icons.play_circle, AppColors.success),
        _buildStatCard(context, 'Hours', stats.totalHours.toString(), Icons.access_time, AppColors.warning),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          Text(label, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildWatchTimeChart(BuildContext context, StatsLoaded stats) {
    // Get last 6 months of data
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
    final chartMaxY = maxY > 0 ? maxY * 1.2 : 10.0;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Watch Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMaxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < months.length) {
                          return Text(months[value.toInt()], style: TextStyle(color: AppColors.textMuted(context), fontSize: 11));
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
                    barRods: [BarChartRodData(toY: values[index], color: AppColors.primary, width: 20, borderRadius: BorderRadius.circular(4))],
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

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    value: stats.totalShows.toDouble(),
                    title: 'Shows',
                    color: AppColors.primary,
                    radius: 40,
                    titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: stats.totalMovies.toDouble(),
                    title: 'Movies',
                    color: AppColors.electricPurple,
                    radius: 40,
                    titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

















