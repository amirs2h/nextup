import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/calendar_cubit.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  void _loadCalendar() {
    context.read<CalendarCubit>().loadCalendar(_selectedMonth);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
    _loadCalendar();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
    _loadCalendar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildMonthSelector(context),
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
            onTap: () => Navigator.pop(context),
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
          Text('Calendar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _previousMonth,
              child: Icon(Icons.chevron_left, color: AppColors.text(context), size: 28),
            ),
            Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context)),
            ),
            GestureDetector(
              onTap: _nextMonth,
              child: Icon(Icons.chevron_right, color: AppColors.text(context), size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        if (state is CalendarLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
        }

        if (state is CalendarError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Color(0xFFFF4757)),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
              ],
            ),
          );
        }

        if (state is CalendarLoaded) {
          if (state.events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text('No episodes this month', style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Add shows to your watchlist to see their schedule', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                ],
              ),
            );
          }

          // Group events by date
          final groupedEvents = <String, List<CalendarEvent>>{};
          for (final event in state.events) {
            final dateKey = DateFormat('yyyy-MM-dd').format(event.airDate);
            groupedEvents[dateKey] = groupedEvents[dateKey] ?? [];
            groupedEvents[dateKey]!.add(event);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: groupedEvents.length,
            itemBuilder: (context, index) {
              final dateKey = groupedEvents.keys.elementAt(index);
              final events = groupedEvents[dateKey]!;
              final date = DateTime.parse(dateKey);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      DateFormat('EEEE, MMM d').format(date),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                    ),
                  ),
                  ...events.map((event) => _buildEventCard(context, event)),
                ],
              );
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildEventCard(BuildContext context, CalendarEvent event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.push('/show/${event.show.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 85,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: event.show.posterUrl != null
                      ? CachedNetworkImage(
                          imageUrl: event.show.posterUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.cardBg(context),
                            child: Icon(Icons.movie, color: AppColors.textMuted(context)),
                          ),
                        )
                      : Container(
                          color: AppColors.cardBg(context),
                          child: Icon(Icons.movie, color: AppColors.textMuted(context)),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.show.name,
                      style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'S${event.seasonNumber} E${event.episodeNumber}',
                      style: TextStyle(color: const Color(0xFF6C63FF), fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.episodeName,
                      style: TextStyle(color: AppColors.textMuted(context), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormat('MMM d').format(event.airDate),
                  style: const TextStyle(color: Color(0xFF00FF88), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
