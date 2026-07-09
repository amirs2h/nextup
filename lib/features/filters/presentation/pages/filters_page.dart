import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../discover/domain/discover_cubit.dart';

class FiltersPage extends StatefulWidget {
  const FiltersPage({super.key});

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  String _mediaType = 'tv';
  String _sortBy = 'popularity.desc';
  int? _selectedYear;
  double _minRating = 0;
  int? _selectedGenre;
  int? _selectedShowStatus;
  bool _initialized = false;

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'popularity.desc', 'label': 'Most Popular'},
    {'value': 'vote_average.desc', 'label': 'Highest Rated'},
    {'value': 'first_air_date.desc', 'label': 'Newest'},
    {'value': 'first_air_date.asc', 'label': 'Oldest'},
  ];

  final List<Map<String, dynamic>> _showStatuses = [
    {'value': null, 'label': 'All'},
    {'value': 0, 'label': 'Returning'},
    {'value': 4, 'label': 'Ended'},
    {'value': 5, 'label': 'Canceled'},
  ];

  @override
  Widget build(BuildContext context) {
    // Sync with current cubit state on first build
    if (!_initialized) {
      final cubitState = context.read<DiscoverCubit>().state;
      if (cubitState is DiscoverLoaded) {
        _mediaType = cubitState.mediaType;
        _sortBy = cubitState.sortBy;
        _selectedYear = cubitState.year;
        _minRating = cubitState.minRating;
        _selectedGenre = cubitState.selectedGenreId;
        _selectedShowStatus = cubitState.showStatus;
      }
      _initialized = true;
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildContent(context)),
              _buildApplyButton(context),
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
          Text('Filters', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const Spacer(),
          TextButton(
            onPressed: _resetFilters,
            child: Text('Reset', style: TextStyle(color: AppColors.electricPurple, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMediaTypeSelector(context),
          if (_mediaType == 'tv') ...[
            const SizedBox(height: 16),
            _buildShowStatusSelector(context),
          ],
          const SizedBox(height: 16),
          _buildSortSelector(context),
          const SizedBox(height: 16),
          _buildYearSelector(context),
          const SizedBox(height: 16),
          _buildRatingSlider(context),
          const SizedBox(height: 16),
          _buildGenreSelector(context),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text(context))),
    );
  }

  Widget _buildMediaTypeSelector(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Type'),
          Row(
            children: [
              Expanded(child: _buildTypeChip('TV Shows', 'tv')),
              const SizedBox(width: 10),
              Expanded(child: _buildTypeChip('Movies', 'movie')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, String value) {
    final isSelected = _mediaType == value;
    return GestureDetector(
      onTap: () => setState(() {
        _mediaType = value;
        _selectedYear = null;
        if (value == 'movie') _selectedShowStatus = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(colors: [AppColors.primary, Color(0xFFFF3D47)]) : null,
          color: isSelected ? null : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.transparent : AppColors.border(context)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.text(context),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShowStatusSelector(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Show Status'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _showStatuses.map((status) {
              final isSelected = _selectedShowStatus == status['value'];
              return GestureDetector(
                onTap: () => setState(() => _selectedShowStatus = status['value']),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.purpleGradient : null,
                    color: isSelected ? null : AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.transparent : AppColors.border(context)),
                  ),
                  child: Text(
                    status['label'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary(context),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSelector(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Sort By'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sortOptions.map((option) {
              final isSelected = _sortBy == option['value'];
              return GestureDetector(
                onTap: () => setState(() => _sortBy = option['value']),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.electricPurple.withValues(alpha: 0.15) : AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.electricPurple : AppColors.border(context)),
                  ),
                  child: Text(
                    option['label'],
                    style: TextStyle(
                      color: isSelected ? AppColors.electricPurple : AppColors.text(context),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(30, (index) => currentYear - index);

    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Year'),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: years.length + 1,
              itemBuilder: (context, index) {
                final isAll = index == 0;
                final year = isAll ? null : years[index - 1];
                final isSelected = isAll ? _selectedYear == null : _selectedYear == year;

                return GestureDetector(
                  onTap: () => setState(() => _selectedYear = year),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.electricPurple.withValues(alpha: 0.15) : AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: isSelected ? AppColors.electricPurple : AppColors.border(context)),
                    ),
                    child: Center(
                      child: Text(
                        isAll ? 'All' : '$year',
                        style: TextStyle(
                          color: isSelected ? AppColors.electricPurple : AppColors.text(context),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSlider(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Minimum Rating', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text(context))),
              Text(
                _minRating > 0 ? '${_minRating.toStringAsFixed(0)}+' : 'Any',
                style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.warning,
              inactiveTrackColor: AppColors.border(context),
              thumbColor: AppColors.warning,
              overlayColor: AppColors.warning.withValues(alpha: 0.1),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _minRating,
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (value) => setState(() => _minRating = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreSelector(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Genre'),
          BlocBuilder<DiscoverCubit, DiscoverState>(
            builder: (context, state) {
              final genres = state is DiscoverLoaded ? state.genres : <dynamic>[];
              if (genres.isEmpty) {
                return Text('Loading genres...', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13));
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: genres.map((genre) {
                  final isSelected = _selectedGenre == genre.id;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedGenre = isSelected ? null : genre.id;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.electricPurple.withValues(alpha: 0.15) : AppColors.cardBg(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppColors.electricPurple : AppColors.border(context)),
                      ),
                      child: Text(
                        genre.name,
                        style: TextStyle(
                          color: isSelected ? AppColors.electricPurple : AppColors.text(context),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GlassButton(
        text: 'Apply Filters',
        icon: Icons.check,
        onPressed: () {
          // Apply filters directly to the DiscoverCubit
          context.read<DiscoverCubit>().applyFilters(
            mediaType: _mediaType,
            sortBy: _sortBy,
            year: _selectedYear,
            minRating: _minRating > 0 ? _minRating : null,
            genreId: _selectedGenre,
            showStatus: _selectedShowStatus,
          );
          // Navigate back to discover
          context.pop();
        },
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _mediaType = 'tv';
      _sortBy = 'popularity.desc';
      _selectedYear = null;
      _minRating = 0;
      _selectedGenre = null;
      _selectedShowStatus = null;
    });
  }
}














