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
  late DateTime _selectedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _selectedDay = now;
    _loadCalendar();
  }

  void _loadCalendar() {
    context.read<CalendarCubit>().loadCalendar(_selectedMonth);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _selectedDay = _selectedMonth;
    });
    _loadCalendar();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _selectedDay = _selectedMonth;
    });
    _loadCalendar();
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
              _buildMonthSelector(context),
              _buildCalendarGrid(context),
              Expanded(child: _buildEventsList(context)),
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
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _previousMonth,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.chevron_left_rounded, color: AppColors.text(context), size: 20),
              ),
            ),
            Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context)),
            ),
            GestureDetector(
              onTap: _nextMonth,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.chevron_right_rounded, color: AppColors.text(context), size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday;
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Day headers
            Row(
              children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: AppColors.textMuted(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Calendar days
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: (firstDayOfMonth - 1) + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstDayOfMonth - 1) {
                  return const SizedBox();
                }
                final day = index - (firstDayOfMonth - 2);
                final isToday = today.year == _selectedMonth.year &&
                    today.month == _selectedMonth.month &&
                    today.day == day;
                final isSelected = _selectedDay.year == _selectedMonth.year &&
                    _selectedDay.month == _selectedMonth.month &&
                    _selectedDay.day == day;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = DateTime(_selectedMonth.year, _selectedMonth.month, day)),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.3)
                          : isToday
                              ? AppColors.electricPurple.withOpacity(0.2)
                              : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: AppColors.electricPurple, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : isToday
                                  ? AppColors.electricPurple
                                  : AppColors.text(context),
                          fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        if (state is CalendarLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is CalendarError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadCalendar, child: const Text('Retry')),
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
                  Icon(Icons.calendar_today_rounded, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text('No episodes this month', style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Add shows to your watchlist to see them here', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                ],
              ),
            );
          }

          // Filter events for selected day
          final selectedDayEvents = state.events.where((e) =>
            e.airDate.year == _selectedDay.year &&
            e.airDate.month == _selectedDay.month &&
            e.airDate.day == _selectedDay.day
          ).toList();

          final allEvents = state.events;

          return RefreshIndicator(
            onRefresh: () async => _loadCalendar(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (selectedDayEvents.isNotEmpty) ...[
                  Text(
                    'Episodes on ${DateFormat('MMM d').format(_selectedDay)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                  ),
                  const SizedBox(height: 12),
                  ...selectedDayEvents.map((event) => _buildEventCard(context, event)),
                  const SizedBox(height: 20),
                ],
                Text(
                  'All This Month',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                ),
                const SizedBox(height: 12),
                ..._buildGroupedEvents(context, allEvents),
                const SizedBox(height: 100),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  List<Widget> _buildGroupedEvents(BuildContext context, List<CalendarEvent> events) {
    final Map<String, List<CalendarEvent>> grouped = {};
    for (final event in events) {
      final key = DateFormat('yyyy-MM-dd').format(event.airDate);
      grouped.putIfAbsent(key, () => []).add(event);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      final date = DateTime.parse(entry.key);
      final isToday = DateTime.now().year == date.year &&
          DateTime.now().month == date.month &&
          DateTime.now().day == date.day;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.electricPurple.withOpacity(0.2) : AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(8),
                  border: isToday ? Border.all(color: AppColors.electricPurple, width: 1) : null,
                ),
                child: Text(
                  DateFormat('EEE, MMM d').format(date),
                  style: TextStyle(
                    color: isToday ? AppColors.electricPurple : AppColors.textSecondary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Text('Today', style: TextStyle(color: AppColors.electricPurple, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
      );

      for (final event in entry.value) {
        widgets.add(_buildEventCard(context, event));
      }
    }
    return widgets;
  }

  Widget _buildEventCard(BuildContext context, CalendarEvent event) {
    final now = DateTime.now();
    final isPast = event.airDate.isBefore(now);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.push('/show/${event.show.id}/season/${event.seasonNumber}/episode/${event.episodeNumber}'),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: event.show.posterUrl != null
                      ? CachedNetworkImage(
                          imageUrl: event.show.posterUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.cardBg(context),
                            child: Icon(Icons.tv_rounded, color: AppColors.textMuted(context)),
                          ),
                        )
                      : Container(
                          color: AppColors.cardBg(context),
                          child: Icon(Icons.tv_rounded, color: AppColors.textMuted(context)),
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
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.electricPurple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'S${event.seasonNumber} E${event.episodeNumber}',
                            style: TextStyle(color: AppColors.electricPurple, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.episodeName,
                            style: TextStyle(color: AppColors.textMuted(context), fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPast
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormat('MMM d').format(event.airDate),
                  style: TextStyle(
                    color: isPast ? AppColors.success : AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
