import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/theme_service.dart';

/// Widget per la selezione dei colori personalizzati
class ColorPicker extends StatefulWidget {
  final Function(Color) onColorChanged;

  const ColorPicker({
    super.key,
    required this.onColorChanged,
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  Color? _selectedColor;
  final List<Color> _predefinedColors = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.lime,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentColor();
  }

  Future<void> _loadCurrentColor() async {
    final color = await ThemeService.getAccentColor();
    setState(() {
      _selectedColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Colore Accent',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Scegli il colore principale dell\'app',
          style: TextStyle(
            fontSize: 14.sp,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 16.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: [
            ..._predefinedColors.map((color) => _buildColorOption(color)),
            _buildCustomColorOption(),
          ],
        ),
      ],
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = _selectedColor == color;

    return GestureDetector(
      onTap: () => _selectColor(color),
      child: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: Colors.white,
                size: 24.sp,
              )
            : null,
      ),
    );
  }

  Widget _buildCustomColorOption() {
    final isSelected = _selectedColor != null && 
        !_predefinedColors.contains(_selectedColor);

    return GestureDetector(
      onTap: _showColorPicker,
      child: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          color: _selectedColor ?? Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: (_selectedColor ?? Colors.grey).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.colorize,
          color: Colors.white,
          size: 24.sp,
        ),
      ),
    );
  }

  void _selectColor(Color color) async {
    await ThemeService.setAccentColor(color);
    setState(() {
      _selectedColor = color;
    });
    widget.onColorChanged(color);
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scegli Colore'),
        content: SingleChildScrollView(
          child: ColorPickerGrid(
            pickerColor: _selectedColor ?? Colors.blue,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              if (_selectedColor != null) {
                _selectColor(_selectedColor!);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
  }
}

/// Widget semplificato per la selezione del colore
class ColorPickerGrid extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerGrid({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300.w,
      height: 200.h,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          crossAxisSpacing: 8.w,
          mainAxisSpacing: 8.h,
        ),
        itemCount: 64,
        itemBuilder: (context, index) {
          final hue = (index * 5.625) % 360;
          final color = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
          
          return GestureDetector(
            onTap: () => onColorChanged(color),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: pickerColor == color ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 