// lib/features/templates/presentation/screens/templates_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../bloc/template_bloc.dart';
import '../../models/template_models.dart';
import '../widgets/template_card.dart';
import '../widgets/template_filters.dart';
import '../widgets/template_search_bar.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  int? _selectedCategoryId;
  String? _selectedDifficulty;
  String? _selectedGoal;
  bool? _featuredOnly;
  String _searchQuery = '';
  
  bool _isLoadingMore = false;
  
  // Memorizza i template per evitarli di perderli quando riceve CategoriesLoaded
  List<WorkoutTemplate> _cachedTemplates = [];
  bool _cachedUserPremium = false;

  @override
  void initState() {
    super.initState();
    print('🔍 TemplatesScreen.initState: Initializing screen');
    _scrollController.addListener(_onScroll);
    
    // Carica template iniziali
    print('🔍 TemplatesScreen.initState: Dispatching LoadTemplates event');
    context.read<TemplateBloc>().add(const LoadTemplates(refresh: true));
    print('🔍 TemplatesScreen.initState: Dispatching LoadCategories event');
    context.read<TemplateBloc>().add(const LoadCategories(includeAll: true));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTemplates();
    }
  }

  void _loadMoreTemplates() {
    if (_isLoadingMore) return;
    
    final state = context.read<TemplateBloc>().state;
    if (state is TemplatesLoaded && state.hasMore) {
      setState(() {
        _isLoadingMore = true;
      });
      
      context.read<TemplateBloc>().add(LoadTemplates(
        categoryId: _selectedCategoryId,
        difficulty: _selectedDifficulty,
        goal: _selectedGoal,
        featured: _featuredOnly,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        offset: state.templates.length,
      ));
    }
  }

  void _applyFilters({
    int? categoryId,
    String? difficulty,
    String? goal,
    bool? featured,
    String? search,
  }) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedDifficulty = difficulty;
      _selectedGoal = goal;
      _featuredOnly = featured;
      _searchQuery = search ?? '';
      _searchController.text = _searchQuery;
    });

    context.read<TemplateBloc>().add(LoadTemplates(
      categoryId: categoryId,
      difficulty: difficulty,
      goal: goal,
      featured: featured,
      search: search,
      refresh: true,
    ));
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedDifficulty = null;
      _selectedGoal = null;
      _featuredOnly = null;
      _searchQuery = '';
      _searchController.clear();
    });

    context.read<TemplateBloc>().add(const LoadTemplates(refresh: true));
  }

  void _navigateToTemplateDetails(WorkoutTemplate template) {
    context.push('/template-details/${template.id}');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Template Schede'),
        backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFiltersDialog(),
          ),
        ],
      ),
      body: BlocConsumer<TemplateBloc, TemplateState>(
        listener: (context, state) {
          print('🔍 TemplatesScreen.BlocConsumer.listener: Received state: ${state.runtimeType}');
          
          if (state is TemplateError) {
            print('❌ TemplatesScreen.BlocConsumer.listener: TemplateError - ${state.message}');
            CustomSnackbar.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          } else if (state is TemplatesLoaded) {
            print('🔍 TemplatesScreen.BlocConsumer.listener: TemplatesLoaded - ${state.templates.length} templates');
            setState(() {
              _isLoadingMore = false;
              // Memorizza i template per evitarli di perderli quando riceve CategoriesLoaded
              _cachedTemplates = state.templates;
              _cachedUserPremium = state.userPremium;
            });
          } else if (state is TemplateLoading) {
            print('🔍 TemplatesScreen.BlocConsumer.listener: TemplateLoading');
          }
        },
        builder: (context, state) {
          print('🔍 TemplatesScreen.BlocConsumer.builder: Building with state: ${state.runtimeType}');
          
          if (state is TemplateLoading) {
            print('🔍 TemplatesScreen.BlocConsumer.builder: Showing loading overlay');
            return const LoadingOverlay(
              isLoading: true,
              child: SizedBox.shrink(),
            );
          }

          // Mostra i template se abbiamo TemplatesLoaded o se abbiamo template memorizzati
          if (state is TemplatesLoaded || _cachedTemplates.isNotEmpty) {
            final templates = state is TemplatesLoaded ? state.templates : _cachedTemplates;
            final userPremium = state is TemplatesLoaded ? state.userPremium : _cachedUserPremium;
            
            return RefreshIndicator(
              onRefresh: () async {
                _applyFilters(
                  categoryId: _selectedCategoryId,
                  difficulty: _selectedDifficulty,
                  goal: _selectedGoal,
                  featured: _featuredOnly,
                  search: _searchQuery.isNotEmpty ? _searchQuery : null,
                );
              },
              child: Column(
                children: [
                  // Barra di ricerca
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: TemplateSearchBar(
                      controller: _searchController,
                      onSearch: (query) => _applyFilters(search: query),
                      onClear: () => _applyFilters(search: ''),
                    ),
                  ),

                  // Filtri attivi
                  if (_hasActiveFilters())
                    _buildActiveFilters(),

                  // Lista template
                  Expanded(
                    child: templates.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            itemCount: templates.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= templates.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final template = templates[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: 16.h),
                                child: TemplateCard(
                                  template: template,
                                  userPremium: userPremium,
                                  onTap: () => _navigateToTemplateDetails(template),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: Text('Nessun template disponibile'),
          );
        },
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt,
            size: 16.sp,
            color: AppColors.primary,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _getActiveFiltersText(),
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearFilters,
            child: Icon(
              Icons.close,
              size: 16.sp,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64.sp,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            'Nessun template trovato',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Prova a modificare i filtri di ricerca',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _clearFilters,
            child: const Text('Rimuovi filtri'),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategoryId != null ||
        _selectedDifficulty != null ||
        _selectedGoal != null ||
        _featuredOnly != null ||
        _searchQuery.isNotEmpty;
  }

  String _getActiveFiltersText() {
    final filters = <String>[];
    
    if (_selectedCategoryId != null) {
      filters.add('Categoria');
    }
    if (_selectedDifficulty != null) {
      filters.add('Difficoltà');
    }
    if (_selectedGoal != null) {
      filters.add('Obiettivo');
    }
    if (_featuredOnly != null) {
      filters.add('In evidenza');
    }
    if (_searchQuery.isNotEmpty) {
      filters.add('Ricerca');
    }
    
    return 'Filtri attivi: ${filters.join(', ')}';
  }

  void _showFiltersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TemplateFilters(
        selectedCategoryId: _selectedCategoryId,
        selectedDifficulty: _selectedDifficulty,
        selectedGoal: _selectedGoal,
        featuredOnly: _featuredOnly,
        onApplyFilters: _applyFilters,
        onClearFilters: _clearFilters,
      ),
    );
  }
}
