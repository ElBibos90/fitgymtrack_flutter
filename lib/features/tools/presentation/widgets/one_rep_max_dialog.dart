// lib/features/tools/presentation/widgets/one_rep_max_dialog.dart
// 🛡️ OVERFLOW-PROOF VERSION - Sostituisci TUTTO il file

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../models/one_rep_max_models.dart';

/// 🛡️ OVERFLOW-PROOF Dialog per calcolare il 1RM (One Rep Max)
class OneRepMaxDialog extends StatefulWidget {
  const OneRepMaxDialog({super.key});

  @override
  State<OneRepMaxDialog> createState() => _OneRepMaxDialogState();
}

class _OneRepMaxDialogState extends State<OneRepMaxDialog> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController(); // 🆕 ScrollController

  OneRepMaxResult? _result;
  OneRepMaxFormula _selectedFormula = OneRepMaxFormula.epley;
  bool _showAllFormulas = false;

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _scrollController.dispose(); // 🆕 Dispose ScrollController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    // 🛡️ FIX: Calcola spazio disponibile considerando tastiera
    final availableHeight = mediaQuery.size.height -
        mediaQuery.viewInsets.bottom -
        mediaQuery.viewPadding.top -
        mediaQuery.viewPadding.bottom;

    return Dialog(
      // 🛡️ FIX: Remove fixed constraints - let it be flexible
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: 20.h,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // 🛡️ FIX: Dynamic max height based on available space
          maxHeight: (availableHeight * 0.85).clamp(300.h, 700.h),
          minHeight: 200.h,
          maxWidth: 500.w,
        ),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 🛡️ FIX: Minimum size
            children: [
              // Header - Fixed at top
              _buildHeader(isDarkMode),

              SizedBox(height: 16.h), // 🛡️ FIX: Reduced spacing

              // 🛡️ FIX: Scrollable content area
              Flexible(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildInputSection(isDarkMode),

                        if (_result != null) ...[
                          SizedBox(height: 16.h), // 🛡️ FIX: Reduced spacing
                          _buildResultSection(isDarkMode),
                        ],

                        // 🛡️ FIX: Extra padding for keyboard
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ),

              // 🛡️ FIX: Fixed actions at bottom
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      children: [
        Container(
          width: 36.w, // 🛡️ FIX: Slightly smaller
          height: 36.w,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r), // 🛡️ FIX: Smaller radius
          ),
          child: Icon(
            Icons.calculate_rounded,
            color: Colors.blue,
            size: 18.sp, // 🛡️ FIX: Smaller icon
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 🛡️ FIX: Minimum size
            children: [
              Text(
                'Calcola 1RM',
                style: TextStyle(
                  fontSize: 16.sp, // 🛡️ FIX: Smaller text
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              Text(
                'One Rep Maximum Calculator',
                style: TextStyle(
                  fontSize: 11.sp, // 🛡️ FIX: Smaller text
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
            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
          ),
          padding: EdgeInsets.zero, // 🛡️ FIX: Remove padding
          constraints: const BoxConstraints(), // 🛡️ FIX: Remove constraints
        ),
      ],
    );
  }

  Widget _buildInputSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // 🛡️ FIX: Minimum size
      children: [
        _buildWeightInput(isDarkMode),
        SizedBox(height: 12.h), // 🛡️ FIX: Reduced spacing
        _buildRepsInput(isDarkMode),
        SizedBox(height: 12.h), // 🛡️ FIX: Reduced spacing
        _buildFormulaSelector(isDarkMode),
        SizedBox(height: 16.h), // 🛡️ FIX: Reduced spacing
        _buildCalculateButton(),
      ],
    );
  }

  Widget _buildWeightInput(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // 🛡️ FIX: Minimum size
      children: [
        Text(
          'Peso sollevato (kg)',
          style: TextStyle(
            fontSize: 13.sp, // 🛡️ FIX: Smaller text
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 6.h), // 🛡️ FIX: Reduced spacing
        TextFormField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            hintText: 'es. 100.5',
            suffixText: 'kg',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
            contentPadding: EdgeInsets.symmetric( // 🛡️ FIX: Reduced padding
              horizontal: 12.w,
              vertical: 10.h,
            ),
          ),
          style: TextStyle(fontSize: 14.sp), // 🛡️ FIX: Smaller text
          validator: (value) {
            if (value == null || value.isEmpty) return 'Inserisci il peso';
            final weight = double.tryParse(value);
            if (weight == null) return 'Numero non valido';
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
      mainAxisSize: MainAxisSize.min, // 🛡️ FIX: Minimum size
      children: [
        Text(
          'Ripetizioni eseguite',
          style: TextStyle(
            fontSize: 13.sp, // 🛡️ FIX: Smaller text
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 6.h), // 🛡️ FIX: Reduced spacing
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
            contentPadding: EdgeInsets.symmetric( // 🛡️ FIX: Reduced padding
              horizontal: 12.w,
              vertical: 10.h,
            ),
          ),
          style: TextStyle(fontSize: 14.sp), // 🛡️ FIX: Smaller text
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
      mainAxisSize: MainAxisSize.min, // 🛡️ FIX: Minimum size
      children: [
        Text(
          'Formula di calcolo',
          style: TextStyle(
            fontSize: 13.sp, // 🛡️ FIX: Smaller text
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 6.h), // 🛡️ FIX: Reduced spacing
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h), // 🛡️ FIX: Reduced padding
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
              style: TextStyle(fontSize: 14.sp), // 🛡️ FIX: Smaller text
              items: OneRepMaxFormula.values.map((formula) {
                return DropdownMenuItem(
                  value: formula,
                  child: Text(
                    formula.name,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 14.sp, // 🛡️ FIX: Smaller text
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
      height: 44.h, // 🛡️ FIX: Smaller button
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
          mainAxisSize: MainAxisSize.min, // 🛡️ FIX: Minimum size
          children: [
            Icon(Icons.calculate, size: 18.sp), // 🛡️ FIX: Smaller icon
            SizedBox(width: 8.w),
            Text(
              'Calcola 1RM',
              style: TextStyle(
                fontSize: 14.sp, // 🛡️ FIX: Smaller text
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
      padding: EdgeInsets.all(14.w), // 🛡️ FIX: Reduced padding
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🛡️ FIX: Minimum size
        children: [
          // Risultato principale
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                color: Colors.green,
                size: 20.sp, // 🛡️ FIX: Smaller icon
              ),
              SizedBox(width: 8.w),
              Text(
                _result!.formattedOneRM,
                style: TextStyle(
                  fontSize: 20.sp, // 🛡️ FIX: Smaller text
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          SizedBox(height: 6.h), // 🛡️ FIX: Reduced spacing

          Text(
            'Formula: ${_result!.formula}',
            style: TextStyle(
              fontSize: 11.sp, // 🛡️ FIX: Smaller text
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),

          Text(
            'Input: ${_result!.formattedInput}',
            style: TextStyle(
              fontSize: 11.sp, // 🛡️ FIX: Smaller text
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Chiudi',
              style: TextStyle(fontSize: 14.sp), // 🛡️ FIX: Smaller text
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: TextButton(
            onPressed: (_weightController.text.isNotEmpty &&
                _repsController.text.isNotEmpty &&
                _result != null) ? _compareFormulas : null,
            child: Text(
              'Confronta',
              style: TextStyle(fontSize: 14.sp), // 🛡️ FIX: Smaller text
            ),
          ),
        ),
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

    // 🛡️ FIX: Scroll to result after calculation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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

/// 🛡️ OVERFLOW-PROOF Dialog per confrontare tutte le formule
class _CompareFormulasDialog extends StatelessWidget {
  final List<OneRepMaxResult> results;

  const _CompareFormulasDialog({required this.results});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6, // 🛡️ FIX: Dynamic height
          maxWidth: 400.w,
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 🛡️ FIX: Minimum size
            children: [
              Text(
                'Confronto Formule',
                style: TextStyle(
                  fontSize: 16.sp, // 🛡️ FIX: Smaller text
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: results.map((result) {
                      return ListTile(
                        dense: true, // 🛡️ FIX: Compact list items
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w), // 🛡️ FIX: Reduced padding
                        title: Text(
                          result.formula,
                          style: TextStyle(fontSize: 14.sp), // 🛡️ FIX: Smaller text
                        ),
                        trailing: Text(
                          result.formattedOneRM,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp, // 🛡️ FIX: Smaller text
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              SizedBox(height: 12.h),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: 14.sp), // 🛡️ FIX: Smaller text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}