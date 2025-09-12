// lib/features/stats/presentation/screens/stats_test_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/stats_theme.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../widgets/stats_demo_widget.dart';

/// 🧪 Stats Test Screen - Schermata di Test per le Nuove Statistiche
class StatsTestScreen extends StatefulWidget {
  const StatsTestScreen({super.key});

  @override
  State<StatsTestScreen> createState() => _StatsTestScreenState();
}

class _StatsTestScreenState extends State<StatsTestScreen> {
  bool _showNewStats = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StatsTheme.getPageBackground(context),
      appBar: CustomAppBar(
        title: 'Test Statistiche',
        actions: [
          IconButton(
            icon: Icon(
              _showNewStats ? Icons.arrow_back : Icons.new_releases,
              color: StatsTheme.primaryBlue,
              size: 24.sp,
            ),
            onPressed: () {
              setState(() {
                _showNewStats = !_showNewStats;
              });
            },
            tooltip: _showNewStats ? 'Torna alle vecchie statistiche' : 'Prova le nuove statistiche',
          ),
        ],
      ),
      body: _showNewStats 
          ? const StatsDemoWidget()
          : _buildOldStatsPlaceholder(),
    );
  }

  Widget _buildOldStatsPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80.sp,
            color: StatsTheme.getTextSecondary(context),
          ),
          SizedBox(height: StatsTheme.space4.h),
          Text(
            'Statistiche Attuali',
            style: StatsTheme.h3.copyWith(
              color: StatsTheme.getTextPrimary(context),
            ),
          ),
          SizedBox(height: StatsTheme.space2.h),
          Text(
            'Qui verrebbero mostrate le statistiche attuali',
            style: StatsTheme.bodyMedium.copyWith(
              color: StatsTheme.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: StatsTheme.space6.h),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showNewStats = true;
              });
            },
            icon: Icon(
              Icons.new_releases,
              color: Colors.white,
              size: 20.sp,
            ),
            label: Text(
              'Prova le Nuove Statistiche',
              style: StatsTheme.labelLarge.copyWith(
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: StatsTheme.primaryBlue,
              padding: EdgeInsets.symmetric(
                horizontal: StatsTheme.space6.w,
                vertical: StatsTheme.space4.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
