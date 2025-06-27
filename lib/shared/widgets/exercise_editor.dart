import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExerciseEditor extends StatefulWidget {
  final int? initialIndex;
  final Map<String, dynamic>? initialData;
  final bool isFirst;
  final void Function(Map<String, dynamic> data) onSave;
  final VoidCallback onCancel;

  const ExerciseEditor({
    super.key,
    this.initialIndex,
    this.initialData,
    required this.isFirst,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends State<ExerciseEditor> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _groupController;
  late TextEditingController _equipmentController;
  late TextEditingController _seriesController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _restController;
  late TextEditingController _noteController;
  String _setType = 'normale';
  bool _linkedToPrevious = false;

  final List<String> _setTypes = [
    'normale',
    'superset',
    'circuit',
    'giant_set',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?['nome'] ?? '');
    _groupController = TextEditingController(text: widget.initialData?['gruppoMuscolare'] ?? '');
    _equipmentController = TextEditingController(text: widget.initialData?['attrezzatura'] ?? '');
    _seriesController = TextEditingController(text: (widget.initialData?['serie'] ?? 3).toString());
    _repsController = TextEditingController(text: (widget.initialData?['ripetizioni'] ?? 10).toString());
    _weightController = TextEditingController(text: (widget.initialData?['peso'] ?? 20.0).toString());
    _restController = TextEditingController(text: (widget.initialData?['tempoRecupero'] ?? 90).toString());
    _noteController = TextEditingController(text: widget.initialData?['note'] ?? '');
    _setType = widget.initialData?['setType'] ?? 'normale';
    _linkedToPrevious = widget.initialData?['linkedToPrevious'] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    _equipmentController.dispose();
    _seriesController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.initialIndex == null ? 'Nuovo Esercizio' : 'Modifica Esercizio',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Inserisci il nome' : null,
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _groupController,
                  decoration: const InputDecoration(labelText: 'Gruppo muscolare'),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _equipmentController,
                  decoration: const InputDecoration(labelText: 'Attrezzatura'),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _seriesController,
                        decoration: const InputDecoration(labelText: 'Serie'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || int.tryParse(v) == null ? 'N°' : null,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextFormField(
                        controller: _repsController,
                        decoration: const InputDecoration(labelText: 'Ripetizioni'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || int.tryParse(v) == null ? 'N°' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(labelText: 'Peso (kg)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || double.tryParse(v) == null ? 'kg' : null,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextFormField(
                        controller: _restController,
                        decoration: const InputDecoration(labelText: 'Recupero (s)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || int.tryParse(v) == null ? 'sec' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                DropdownButtonFormField<String>(
                  value: _setType,
                  items: _setTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type[0].toUpperCase() + type.substring(1)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _setType = v ?? 'normale'),
                  decoration: const InputDecoration(labelText: 'Tipo (set_type)'),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Checkbox(
                      value: _linkedToPrevious,
                      onChanged: widget.isFirst
                          ? null
                          : (v) => setState(() => _linkedToPrevious = v ?? false),
                    ),
                    const Text('Legato al precedente (gruppo)'),
                    if (widget.isFirst)
                      const Tooltip(message: 'Il primo esercizio non può essere legato'),
                  ],
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Note'),
                  maxLines: 2,
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.onCancel,
                      child: const Text('Annulla'),
                    ),
                    SizedBox(width: 12.w),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          widget.onSave({
                            'nome': _nameController.text.trim(),
                            'gruppoMuscolare': _groupController.text.trim(),
                            'attrezzatura': _equipmentController.text.trim(),
                            'serie': int.tryParse(_seriesController.text) ?? 3,
                            'ripetizioni': int.tryParse(_repsController.text) ?? 10,
                            'peso': double.tryParse(_weightController.text) ?? 20.0,
                            'tempoRecupero': int.tryParse(_restController.text) ?? 90,
                            'note': _noteController.text.trim(),
                            'setType': _setType,
                            'linkedToPrevious': _linkedToPrevious,
                          });
                        }
                      },
                      child: const Text('Salva'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 