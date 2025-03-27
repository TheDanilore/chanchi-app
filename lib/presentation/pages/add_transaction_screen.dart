import 'package:chanchi_app/presentation/pages/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:chanchi_app/config/theme.dart';

class AddTransactionScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? transaction;
  final String? docId;
  final bool isEditing;

  const AddTransactionScreen({
    super.key,
    required this.userId,
    this.transaction,
    this.docId,
    this.isEditing = false,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isExpense = false;
  String _selectedCategory = 'General';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!['title'];
      _descriptionController.text = widget.transaction!['description'] ?? '';
      _amountController.text =
          (widget.transaction!['amount'] as num).abs().toDouble().toString();
      _isExpense = (widget.transaction!['amount'] as num) < 0;
      _selectedDate = (widget.transaction!['date'] as Timestamp).toDate();
      _selectedCategory = widget.transaction!['category'] ?? 'General';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final double amount =
            double.parse(_amountController.text) * (_isExpense ? -1 : 1);
        final title = _titleController.text;
        final description = _descriptionController.text;

        Map<String, dynamic> transactionData = {
          'title': title,
          'description': description,
          'amount': amount,
          'date': Timestamp.fromDate(_selectedDate),
          'category': _selectedCategory,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (!widget.isEditing) {
          transactionData['createdAt'] = FieldValue.serverTimestamp();
        }

        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId);

        if (widget.isEditing && widget.docId != null) {
          final double originalAmount =
              (widget.transaction?['amount'] as num?)?.toDouble() ?? 0.0;

          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final userDoc = await transaction.get(userRef);
            await transaction.get(
              userRef.collection('transactions').doc(widget.docId),
            );

            if (!userDoc.exists) {
              throw Exception("El documento del usuario no existe");
            }

            final userData = userDoc.data() as Map<String, dynamic>;
            final double currentBalance =
                (userData['balance'] as num?)?.toDouble() ?? 0.0;

            final double newBalance = currentBalance - originalAmount + amount;

            transaction.update(
              userRef.collection('transactions').doc(widget.docId),
              transactionData,
            );
            transaction.update(userRef, {'balance': newBalance});
          });

          Navigator.of(context).pop({
            'updated': true,
            'newAmount': amount,
            'originalAmount': originalAmount,
          });
        } else {
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final userDoc = await transaction.get(userRef);

            if (!userDoc.exists) {
              throw Exception("El documento del usuario no existe");
            }

            final userData = userDoc.data() as Map<String, dynamic>;
            final double currentBalance =
                (userData['balance'] as num?)?.toDouble() ?? 0.0;

            final double newBalance = currentBalance + amount;

            transaction.update(userRef, {'balance': newBalance});
            transaction.set(
              userRef.collection('transactions').doc(),
              transactionData,
            );
          });

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isEditing
                    ? "Transacción actualizada con éxito"
                    : "Transacción agregada con éxito",
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && mounted) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? "Editar Transacción" : "Agregar Transacción",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.lightBackgroundColor,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Título"),
                  validator:
                      (value) =>
                          value!.isEmpty ? "Ingrese un título válido" : null,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.darkSurfaceColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: "Descripción"),
                  maxLines: 2,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.darkSurfaceColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: "Monto"),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return "Ingrese un monto válido";
                    if (double.tryParse(value) == null)
                      return "Ingrese un número válido";
                    return null;
                  },
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.darkSurfaceColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Fecha: ${DateFormat('d MMM, yyyy').format(_selectedDate)}",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkSurfaceColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _pickDate(context),
                      child: const Text("Seleccionar Fecha"),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    const Text("Tipo:"),
                    const SizedBox(width: AppTheme.spacingS),
                    ChoiceChip(
                      label: const Text("Ingreso"),
                      selected: !_isExpense,
                      selectedColor: AppTheme.successColor,
                      onSelected: (selected) {
                        if (selected) setState(() => _isExpense = false);
                      },
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    ChoiceChip(
                      label: const Text("Gasto"),
                      selected: _isExpense,
                      selectedColor: AppTheme.errorColor,
                      onSelected: (selected) {
                        if (selected) setState(() => _isExpense = true);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: "Categoría"),
                  items:
                      [
                            "General",
                            "Comida",
                            "Transporte",
                            "Entretenimiento",
                            "Servicios",
                            "Trabajo",
                            "Propina",
                            "Otros",
                          ]
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.darkSurfaceColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTransaction,
                    style: AppTheme.buildElevatedButtonStyle(
                      AppTheme.primaryColor,
                      AppTheme.cardColor,
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Text(
                              widget.isEditing
                                  ? "Actualizar"
                                  : "Guardar Transacción",
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
