// lib/features/tools/presentation/widgets/one_rep_max_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../models/one_rep_max_models.dart';

/// Dialog per calcolare il 1RM (One Rep Max)
class OneRepMaxDialog extends StatefulWidget {
  const OneRepMaxDialog({super.key});

  @override
  State<OneRepMaxDialog> createState() => _OneRepMaxDialogState();
}

class _OneRepMaxDialogState extends State<OneRepMaxDialog> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  OneRepMaxResult? _result;
  OneRepMaxFormula _selectedFormula = OneRepMaxFormula.epley;
  bool _showAllFormulas = false;

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxHeight: 600.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(isDarkMode),

            SizedBox(height: 20.h),

            // Input Form
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildInputSection(isDarkMode),

                      if (_result != null) ...[
                        SizedBox(height: 20.h),
                        _buildResultSection(isDarkMode),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            Icons.calculate_rounded,
            color: Colors.blue,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calcola 1RM',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              Text(
                'One Rep Maximum Calculator',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.close,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weight Input
        _buildWeightInput(isDarkMode),

        SizedBox(height: 16.h),

        // Reps Input
        _buildRepsInput(isDarkMode),

        SizedBox(height: 16.h),

        // Formula Selector
        _buildFormulaSelector(isDarkMode),

        SizedBox(height: 20.h),

        // Calculate Button
        _buildCalculateButton(),
      ],
    );
  }

  Widget _buildWeightInput(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peso utilizzato (kg)',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            hintText: 'es. 100.0',
            suffixText: 'kg',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Inserisci il peso';
            final weight = double.tryParse(value);
            if (weight == null) return 'Peso non valido';
            if (weight <= 0) return 'Il peso deve essere maggiore di 0';
            if (weight > 1000) return 'Peso troppo elevato';
            return null;
          },
          onChanged: (_) => _clearResult(),
        ),
      ],
    );
  }

  Widget _buildRepsInput(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ripetizioni eseguite',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _repsController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: 'es. 8',
            suffixText: 'reps',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Inserisci le ripetizioni';
            final reps = int.tryParse(value);
            if (reps == null) return 'Numero non valido';
            if (reps < 1) return 'Almeno 1 ripetizione';
            if (reps > 50) return 'Massimo 50 ripetizioni';
            return null;
          },
          onChanged: (_) => _clearResult(),
        ),
      ],
    );
  }

  Widget _buildFormulaSelector(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Formula di calcolo',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<OneRepMaxFormula>(
              value: _selectedFormula,
              isDense: true,
              onChanged: (formula) {
                setState(() {
                  _selectedFormula = formula!;
                  _clearResult();
                });
              },
              items: OneRepMaxFormula.values.map((formula) {
                return DropdownMenuItem(
                  value: formula,
                  child: Text(
                    formula.name,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          _selectedFormula.description,
          style: TextStyle(
            fontSize: 10.sp,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: _calculate,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'Calcola 1RM',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(bool isDarkMode) {
    if (_result == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Risultato principale
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                color: Colors.green,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                _result!.formattedOneRM,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          Text(
            'Formula: ${_result!.formula}',
            style: TextStyle(
              fontSize: 12.sp,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),

          Text(
            'Input: ${_result!.formattedInput}',
            style: TextStyle(
              fontSize: 12.sp,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),

          SizedBox(height: 16.h),

          // Percentuali di allenamento
          Text(
            'Percentuali di allenamento',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),

          SizedBox(height: 8.h),

          _buildPercentagesGrid(),
        ],
      ),
    );
  }

  Widget _buildPercentagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
      ),
      itemCount: _result!.percentages.length,
      itemBuilder: (context, index) {
        final entry = _result!.percentages.entries.elementAt(index);
        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.key,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
              Text(
                '${entry.value.toStringAsFixed(1)}kg',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ),
        if (_result != null) ...[
          SizedBox(width: 8.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _showAllFormulas ? null : _compareFormulas,
              child: const Text('Confronta'),
            ),
          ),
        ],
      ],
    );
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.parse(_weightController.text);
    final reps = int.parse(_repsController.text);

    setState(() {
      _result = OneRepMaxResult(
        oneRM: OneRepMaxCalculator.calculate(weight, reps, _selectedFormula),
        weight: weight,
        reps: reps,
        formula: _selectedFormula.name,
        percentages: OneRepMaxCalculator.getPercentages(
          OneRepMaxCalculator.calculate(weight, reps, _selectedFormula),
        ),
      );
    });
  }

  void _clearResult() {
    if (_result != null) {
      setState(() {
        _result = null;
        _showAllFormulas = false;
      });
    }
  }

  void _compareFormulas() {
    final weight = double.parse(_weightController.text);
    final reps = int.parse(_repsController.text);

    final results = OneRepMaxFormula.values.map((formula) {
      return OneRepMaxResult(
        oneRM: OneRepMaxCalculator.calculate(weight, reps, formula),
        weight: weight,
        reps: reps,
        formula: formula.name,
        percentages: {},
      );
    }).toList();

    showDialog(
      context: context,
      builder: (context) => _CompareFormulasDialog(results: results),
    );
  }
}

/// Dialog per confrontare tutte le formule
class _CompareFormulasDialog extends StatelessWidget {
  final List<OneRepMaxResult> results;

  const _CompareFormulasDialog({required this.results});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Confronto Formule'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: results.map((result) {
          return ListTile(
            title: Text(result.formula),
            trailing: Text(
              result.formattedOneRM,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}