import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/core/utils/currency_util.dart';

class GoalScreen extends StatefulWidget {
  final String userId;
  final String? goalId;

  const GoalScreen({Key? key, required this.userId, this.goalId}) : super(key: key);

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _savedCtrl = TextEditingController();
  DateTime? _targetDate;
  bool _loading = false;

  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    if (widget.goalId != null) {
      _loadGoal();
    }
  }

  Future<void> _loadGoal() async {
    setState(() => _loading = true);
    try {
      final doc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('goals')
          .doc(widget.goalId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _titleCtrl.text = data['title'] ?? '';
        _amountCtrl.text = (data['targetAmount'] ?? 0).toString();
        _savedCtrl.text = (data['savedAmount'] ?? 0).toString();
        if (data['targetDate'] != null && data['targetDate'] is Timestamp) {
          _targetDate = (data['targetDate'] as Timestamp).toDate();
        }
      }
    } catch (e) {
      print('Error loading goal: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final title = _titleCtrl.text.trim();
      final target = double.parse(_amountCtrl.text);
      final saved = double.tryParse(_savedCtrl.text) ?? 0.0;

      final data = {
        'title': title,
        'targetAmount': target,
        'savedAmount': saved,
        'targetDate': _targetDate != null ? Timestamp.fromDate(_targetDate!) : null,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final goalsColl = _firestore.collection('users').doc(widget.userId).collection('goals');

      if (widget.goalId != null) {
        await goalsColl.doc(widget.goalId).update(data);
      } else {
        await goalsColl.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      print('Error saving goal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar la meta: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _savedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goalId != null ? 'Meta' : 'Crear Meta'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'Título'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese un título' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Meta (S/)'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Ingrese un monto';
                        if (double.tryParse(v) == null) return 'Monto inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _savedCtrl,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Guardado actual (opcional)'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _targetDate == null ? 'Fecha objetivo: No definida' : 'Fecha objetivo: ${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _targetDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (picked != null && mounted) setState(() => _targetDate = picked);
                          },
                          child: const Text('Seleccionar fecha'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _saveGoal,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      child: Text(widget.goalId != null ? 'Guardar' : 'Crear meta'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
