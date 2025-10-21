import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../notifications/presentation/widgets/modern_notification_menu.dart';
import '../../bloc/courses_bloc.dart';
import '../../bloc/courses_event.dart';
import 'my_courses_tab.dart';
import 'available_courses_tab.dart';

/// 🎓 Schermata principale corsi con TabBar
/// 
/// Contiene 2 tab:
/// 1. I Miei Corsi - Corsi a cui l'utente è iscritto
/// 2. Disponibili - Tutti i corsi disponibili con ricerca/filtri
class CoursesMainScreen extends StatefulWidget {
  const CoursesMainScreen({super.key});

  @override
  State<CoursesMainScreen> createState() => _CoursesMainScreenState();
}

class _CoursesMainScreenState extends State<CoursesMainScreen> 
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Listener per caricare i dati quando si cambia tab
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadDataForTab(_tabController.index);
      }
    });
    
    // Carica dati iniziali per il primo tab
    _loadDataForTab(0);
  }
  
  /// Carica i dati appropriati per il tab selezionato
  void _loadDataForTab(int index) {
    final bloc = context.read<CoursesBloc>();
    
    if (index == 0) {
      // Tab "I Miei Corsi" - Carica iscrizioni
      bloc.add(const LoadMyEnrollmentsEvent());
    } else {
      // Tab "Disponibili" - Carica corsi disponibili
      bloc.add(const LoadCoursesEvent());
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Corsi',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          // Pulsante refresh
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
            onPressed: () {
              // Refresh del tab corrente
              _loadDataForTab(_tabController.index);
            },
          ),
          
          // Menu notifiche
          ModernNotificationMenu(
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            size: 24.0,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode 
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
              indicatorWeight: 3.0,
              labelColor: isDarkMode ? const Color(0xFF90CAF9) : AppColors.indigo600,
              unselectedLabelColor: isDarkMode 
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.6),
              labelStyle: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, size: 18.sp),
                      SizedBox(width: 6.w),
                      const Text('I Miei Corsi'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.explore_outlined, size: 18.sp),
                      SizedBox(width: 6.w),
                      const Text('Disponibili'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Tab 1: I Miei Corsi
          MyCoursesTab(),
          
          // Tab 2: Corsi Disponibili
          AvailableCoursesTab(),
        ],
      ),
    );
  }
}

