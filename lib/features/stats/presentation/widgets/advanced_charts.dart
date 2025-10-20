// lib/features/stats/presentation/widgets/advanced_charts.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../shared/theme/stats_theme.dart';
import '../../models/stats_models.dart';

/// 📊 Advanced Charts - Grafici Avanzati per Premium
class AdvancedCharts extends StatelessWidget {
  final UserStatsResponse userStats;
  final PeriodStatsResponse? periodStats;

  const AdvancedCharts({
    super.key,
    required this.userStats,
    this.periodStats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: StatsTheme.space4.w),
          child: Row(
            children: [
              Icon(
                Icons.analytics,
                color: StatsTheme.primaryBlue,
                size: 20.sp,
              ),
              SizedBox(width: StatsTheme.space2.w),
              Text(
                'Analisi Avanzate',
                style: StatsTheme.h4.copyWith(
                  color: StatsTheme.getTextPrimary(context),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: StatsTheme.space4.h),
        
        // Grafici
        if (periodStats != null) ...[
          _buildWorkoutFrequencyChart(context),
          SizedBox(height: StatsTheme.space4.h),
          _buildWeightLiftedChart(context),
          SizedBox(height: StatsTheme.space4.h),
          _buildMuscleGroupChart(context),
        ] else
          _buildNoDataState(context),
      ],
    );
  }

  /// 📈 Workout Frequency Chart - Grafico Frequenza Allenamenti
  Widget _buildWorkoutFrequencyChart(BuildContext context) {
    final data = _generateWorkoutDataFromPeriod();
    
    if (data == null) {
      return _buildNoDataChart(context, 'Allenamenti per Giorno');
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: StatsTheme.space4.w),
      padding: EdgeInsets.all(StatsTheme.space4.w),
      decoration: BoxDecoration(
        color: StatsTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
        border: Border.all(
          color: StatsTheme.getBorderColor(context),
          width: 1,
        ),
        boxShadow: StatsTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              'Allenamenti per Giorno',
              style: StatsTheme.h5.copyWith(
                color: StatsTheme.getTextPrimary(context),
              ),
            ),
          SizedBox(height: StatsTheme.space3.h),
          SizedBox(
            height: 200.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: StatsTheme.getBorderColor(context),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: StatsTheme.getBorderColor(context),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        return Text('${value.toInt()}', style: style);
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        Widget text;
                        switch (value.toInt()) {
                          case 0:
                            text = const Text('Lun', style: style);
                            break;
                          case 1:
                            text = const Text('Mar', style: style);
                            break;
                          case 2:
                            text = const Text('Mer', style: style);
                            break;
                          case 3:
                            text = const Text('Gio', style: style);
                            break;
                          case 4:
                            text = const Text('Ven', style: style);
                            break;
                          case 5:
                            text = const Text('Sab', style: style);
                            break;
                          case 6:
                            text = const Text('Dom', style: style);
                            break;
                          default:
                            text = const Text('', style: style);
                            break;
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: text,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: StatsTheme.getBorderColor(context),
                    width: 1,
                  ),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 2.5,
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        StatsTheme.primaryBlue,
                        StatsTheme.primaryBlue.withValues(alpha: 0.3),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: StatsTheme.primaryBlue,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          StatsTheme.primaryBlue.withValues(alpha: 0.3),
                          StatsTheme.primaryBlue.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Weight Lifted Chart - Grafico Peso Sollevato
  Widget _buildWeightLiftedChart(BuildContext context) {
    final data = _generateWeightDataFromPeriod();
    
    if (data == null) {
      return _buildNoDataChart(context, 'Durata Allenamenti (min)');
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: StatsTheme.space4.w),
      padding: EdgeInsets.all(StatsTheme.space4.w),
      decoration: BoxDecoration(
        color: StatsTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
        border: Border.all(
          color: StatsTheme.getBorderColor(context),
          width: 1,
        ),
        boxShadow: StatsTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              'Durata Allenamenti (min)',
              style: StatsTheme.h5.copyWith(
                color: StatsTheme.getTextPrimary(context),
              ),
            ),
          SizedBox(height: StatsTheme.space3.h),
          SizedBox(
            height: 200.h,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 120,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: StatsTheme.primaryBlue,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dayNames = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
                      final dayName = dayNames[group.x.toInt()];
                      final weight = rod.toY.toInt();
                      if (weight == 0) {
                        return BarTooltipItem(
                          '$dayName: Giorno di riposo',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      } else {
                        return BarTooltipItem(
                          '$dayName: ${weight}min di allenamento',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 30,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        return Text('${value.toInt()}min', style: style);
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        Widget text;
                        switch (value.toInt()) {
                          case 0:
                            text = const Text('Lun', style: style);
                            break;
                          case 1:
                            text = const Text('Mar', style: style);
                            break;
                          case 2:
                            text = const Text('Mer', style: style);
                            break;
                          case 3:
                            text = const Text('Gio', style: style);
                            break;
                          case 4:
                            text = const Text('Ven', style: style);
                            break;
                          case 5:
                            text = const Text('Sab', style: style);
                            break;
                          case 6:
                            text = const Text('Dom', style: style);
                            break;
                          default:
                            text = const Text('', style: style);
                            break;
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: text,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: data,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🏋️ Muscle Group Chart - Grafico Gruppi Muscolari
  Widget _buildMuscleGroupChart(BuildContext context) {
    final data = _generateMuscleGroupData();
    
    if (data == null) {
      return _buildNoDataChart(context, 'Distribuzione Gruppi Muscolari');
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: StatsTheme.space4.w),
      padding: EdgeInsets.all(StatsTheme.space4.w),
      decoration: BoxDecoration(
        color: StatsTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
        border: Border.all(
          color: StatsTheme.getBorderColor(context),
          width: 1,
        ),
        boxShadow: StatsTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribuzione Gruppi Muscolari',
            style: StatsTheme.h5.copyWith(
              color: StatsTheme.getTextPrimary(context),
            ),
          ),
          SizedBox(height: StatsTheme.space3.h),
          SizedBox(
            height: 200.h,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    // Handle touch events
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: data.map((e) => PieChartSectionData(
                  color: e.color,
                  value: e.value,
                  title: '${e.value.toInt()}%',
                  radius: 50,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )).toList(),
              ),
            ),
          ),
          SizedBox(height: StatsTheme.space3.h),
          // Legenda
          Wrap(
            spacing: StatsTheme.space2.w,
            runSpacing: StatsTheme.space1.h,
            children: data.map((e) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: e.color,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  e.label,
                  style: StatsTheme.caption.copyWith(
                    color: StatsTheme.getTextSecondary(context),
                  ),
                ),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  /// 📊 No Data State
  Widget _buildNoDataState(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: StatsTheme.space4.w),
      padding: EdgeInsets.all(StatsTheme.space8.w),
      decoration: BoxDecoration(
        color: StatsTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
        border: Border.all(
          color: StatsTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            color: StatsTheme.getTextSecondary(context),
            size: 48.sp,
          ),
          SizedBox(height: StatsTheme.space4.h),
          Text(
            'Nessun dato disponibile',
            style: StatsTheme.h5.copyWith(
              color: StatsTheme.getTextPrimary(context),
            ),
          ),
          SizedBox(height: StatsTheme.space2.h),
          Text(
            'Seleziona un periodo per vedere le analisi avanzate',
            style: StatsTheme.bodyMedium.copyWith(
              color: StatsTheme.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 📈 Generate Workout Data from Period Stats
  List<FlSpot>? _generateWorkoutDataFromPeriod() {
    if (periodStats?.periodStats.weeklyDistribution == null || 
        periodStats!.periodStats.weeklyDistribution!.isEmpty) {
      // Nessun dato reale disponibile
      return null;
    }

    final weeklyData = periodStats!.periodStats.weeklyDistribution!;
    final List<FlSpot> data = [];
    
    // Mappa i giorni della settimana (0=Lun, 1=Mar, ..., 6=Dom)
    final dayMap = {'Lun': 0, 'Mar': 1, 'Mer': 2, 'Gio': 3, 'Ven': 4, 'Sab': 5, 'Dom': 6};
    
    // Inizializza tutti i giorni a 0
    for (int i = 0; i < 7; i++) {
      data.add(FlSpot(i.toDouble(), 0));
    }
    
    // Popola con i dati reali
    for (final dayData in weeklyData) {
      final dayIndex = dayMap[dayData.dayName];
      if (dayIndex != null) {
        data[dayIndex] = FlSpot(dayIndex.toDouble(), dayData.workoutCount.toDouble());
      }
    }
    
    return data;
  }


  /// 📊 Generate Weight Data from Period Stats
  List<BarChartGroupData>? _generateWeightDataFromPeriod() {
    if (periodStats?.periodStats.weeklyDistribution == null || 
        periodStats!.periodStats.weeklyDistribution!.isEmpty) {
      // Nessun dato reale disponibile
      return null;
    }

    final weeklyData = periodStats!.periodStats.weeklyDistribution!;
    
    // Mappa i giorni della settimana (0=Lun, 1=Mar, ..., 6=Dom)
    final dayMap = {'Lun': 0, 'Mar': 1, 'Mer': 2, 'Gio': 3, 'Ven': 4, 'Sab': 5, 'Dom': 6};
    
    // Inizializza tutti i giorni a 0
    final weightData = List<double>.filled(7, 0.0);
    
    // Popola con i dati reali (usiamo totalDuration come proxy per il peso)
    for (final dayData in weeklyData) {
      final dayIndex = dayMap[dayData.dayName];
      if (dayIndex != null) {
        // Convertiamo la durata in un peso approssimativo (1 minuto = 1kg)
        weightData[dayIndex] = dayData.totalDuration.toDouble();
      }
    }
    
    return weightData.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            gradient: LinearGradient(
              colors: [
                StatsTheme.successGreen,
                StatsTheme.successGreen.withValues(alpha: 0.7),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }


  /// 📊 No Data Chart - Grafico senza dati
  Widget _buildNoDataChart(BuildContext context, String title) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: StatsTheme.space4.w),
      padding: EdgeInsets.all(StatsTheme.space4.w),
      decoration: BoxDecoration(
        color: StatsTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
        border: Border.all(
          color: StatsTheme.getBorderColor(context),
          width: 1,
        ),
        boxShadow: StatsTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: StatsTheme.h5.copyWith(
              color: StatsTheme.getTextPrimary(context),
            ),
          ),
          SizedBox(height: StatsTheme.space3.h),
          Container(
            height: 200.h,
            decoration: BoxDecoration(
              color: StatsTheme.getCardBackground(context),
              borderRadius: BorderRadius.circular(StatsTheme.radiusMedium.r),
              border: Border.all(
                color: StatsTheme.getBorderColor(context),
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    color: StatsTheme.getTextSecondary(context),
                    size: 48.sp,
                  ),
                  SizedBox(height: StatsTheme.space2.h),
                  Text(
                    'Nessun dato disponibile',
                    style: StatsTheme.h5.copyWith(
                      color: StatsTheme.getTextPrimary(context),
                    ),
                  ),
                  SizedBox(height: StatsTheme.space1.h),
                  Text(
                    'Inizia ad allenarti per vedere le tue statistiche',
                    style: StatsTheme.bodyMedium.copyWith(
                      color: StatsTheme.getTextSecondary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🏋️ Generate Muscle Group Data from Period Stats
  List<_MuscleGroupData>? _generateMuscleGroupData() {
    if (periodStats?.periodStats.muscleGroupsInPeriod == null || 
        periodStats!.periodStats.muscleGroupsInPeriod!.isEmpty) {
      // Nessun dato reale disponibile
      return null;
    }

    final muscleGroups = periodStats!.periodStats.muscleGroupsInPeriod!;
    final List<_MuscleGroupData> data = [];
    
    // Colori per i gruppi muscolari
    final colors = [
      StatsTheme.primaryBlue,
      StatsTheme.successGreen,
      StatsTheme.warningOrange,
      StatsTheme.warningRed,
      StatsTheme.infoCyan,
      StatsTheme.primaryBlue.withValues(alpha: 0.7),
    ];
    
    // Calcola il volume totale per le percentuali
    final totalVolume = muscleGroups.fold<double>(0, (sum, group) => sum + group.totalVolume);
    
    if (totalVolume == 0) {
      return null; // Nessun volume, nessun dato da mostrare
    }
    
    // Crea i dati per il grafico
    for (int i = 0; i < muscleGroups.length; i++) {
      final group = muscleGroups[i];
      final percentage = (group.totalVolume / totalVolume) * 100;
      
      data.add(_MuscleGroupData(
        label: group.muscleGroup,
        value: percentage,
        color: colors[i % colors.length],
      ));
    }
    
    return data;
  }
}

/// 🏋️ Muscle Group Data
class _MuscleGroupData {
  final String label;
  final double value;
  final Color color;

  _MuscleGroupData({
    required this.label,
    required this.value,
    required this.color,
  });
}
