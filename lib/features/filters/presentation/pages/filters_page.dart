import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/app_colors.dart';

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

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'popularity.desc', 'label': 'Most Popular'},
    {'value': 'vote_average.desc', 'label': 'Highest Rated'},
    {'value': 'first_air_date.desc', 'label': 'Newest'},
    {'value': 'first_air_date.asc', 'label': 'Oldest'},
  ];

  final List<Map<String, dynamic>> _genres = [
    {'id': 28, 'name': 'Action'},
    {'id': 12, 'name': 'Adventure'},
    {'id': 16, 'name': 'Animation'},
    {'id': 35, 'name': 'Comedy'},
    {'id': 80, 'name': 'Crime'},
    {'id': 99, 'name': 'Documentary'},
    {'id': 18, 'name': 'Drama'},
    {'id': 10751, 'name': 'Family'},
    {'id': 14, 'name': 'Fantasy'},
    {'id': 36, 'name': 'History'},
    {'id': 27, 'name': 'Horror'},
    {'id': 10402, 'name': 'Music'},
    {'id': 9648, 'name': 'Mystery'},
    {'id': 10749, 'name': 'Romance'},
    {'id': 878, 'name': 'Sci-Fi'},
    {'id': 53, 'name': 'Thriller'},
    {'id': 10752, 'name': 'War'},
    {'id': 37, 'name': 'Western'},
  ];

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildContent(context)),
            _buildApplyButton(context),
          ],
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
          Text('Filters', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const Spacer(),
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Reset', style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMediaTypeSelector(context),
          const SizedBox(height: 24),
          _buildSortSelector(context),
          const SizedBox(height: 24),
          _buildYearSelector(context),
          const SizedBox(height: 24),
          _buildRatingSlider(context),
          const SizedBox(height: 24),
          _buildGenreSelector(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMediaTypeSelector(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTypeChip('TV Shows', 'tv')),
              const SizedBox(width: 12),
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
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(colors: [Color(0xFFE50914), Color(0xFFFF3D47)]) : null,
          color: isSelected ? null : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : AppColors.border(context)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.text(context),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortSelector(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sort By', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sortOptions.map((option) {
              final isSelected = _sortBy == option['value'];
              return GestureDetector(
                onTap: () => setState(() => _sortBy = option['value']),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.2) : AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF6C63FF) : AppColors.border(context),
                    ),
                  ),
                  child: Text(
                    option['label'],
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF6C63FF) : AppColors.text(context),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Year', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: years.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedYear == null;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedYear = null),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.2) : AppColors.cardBg(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6C63FF) : AppColors.border(context),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'All',
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF6C63FF) : AppColors.text(context),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final year = years[index - 1];
                final isSelected = _selectedYear == year;
                return GestureDetector(
                  onTap: () => setState(() => _selectedYear = year),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.2) : AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6C63FF) : AppColors.border(context),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$year',
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF6C63FF) : AppColors.text(context),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Minimum Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
              Text(
                _minRating > 0 ? '${_minRating.toStringAsFixed(0)}+' : 'Any',
                style: TextStyle(color: const Color(0xFFFFD93D), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _minRating,
            min: 0,
            max: 10,
            divisions: 10,
            activeColor: const Color(0xFFFFD93D),
            inactiveColor: AppColors.border(context),
            onChanged: (value) => setState(() => _minRating = value),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreSelector(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Genre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genres.map((genre) {
              final isSelected = _selectedGenre == genre['id'];
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedGenre = isSelected ? null : genre['id'];
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.2) : AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF6C63FF) : AppColors.border(context),
                    ),
                  ),
                  child: Text(
                    genre['name'],
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF6C63FF) : AppColors.text(context),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildApplyButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassButton(
        text: 'Apply Filters',
        icon: Icons.check,
        onPressed: () {
          context.push('/discover', extra: {
            'mediaType': _mediaType,
            'sortBy': _sortBy,
            'year': _selectedYear,
            'minRating': _minRating,
            'genreId': _selectedGenre,
          });
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
    });
  }
}
