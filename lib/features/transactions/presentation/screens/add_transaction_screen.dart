import 'package:chanchi_app/core/widgets/calculator_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/core/utils/currency_util.dart';
import 'package:chanchi_app/core/widgets/category_selector.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/data/models/category.dart';
import 'package:chanchi_app/features/home/domain/models/transaction.dart';
import 'package:chanchi_app/features/home/presentation/screens/home_screen.dart';
import 'package:chanchi_app/features/transactions/domain/services/transaction_service.dart';
import 'package:chanchi_app/features/transactions/presentation/widgets/account_chip_selector.dart';
import 'package:chanchi_app/features/transactions/presentation/widgets/date_time_picker.dart';
import 'package:chanchi_app/features/transactions/presentation/widgets/transaction_type_selector.dart';

class AddTransactionScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? transaction;
  final String? docId;
  final bool isEditing;
  final bool isDuplicating;
  final String? preselectedAccountId;
  final bool hideAppBar;

  const AddTransactionScreen({
    super.key,
    required this.userId,
    this.transaction,
    this.docId,
    this.isEditing = false,
    this.isDuplicating = false,
    this.preselectedAccountId,
    this.hideAppBar = false,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TransactionService _transactionService = TransactionService();

  // Controladores para los campos de texto
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Estado de la transacción
  String _transactionType = 'expense';
  String? _selectedAccountId;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedCurrency = 'PEN';

  // Datos originales para edición
  String? _originalAccountId;
  double? _originalAmount;
  String? _originalTransactionType;

  // Estado de la pantalla
  bool _isLoading = false;
  bool _loadingData = true;
  List<Account> _accounts = [];
  List<Category> _categories = [];
  final List<String> _currencyOptions = ['PEN', 'USD', 'EUR'];

  @override
  void initState() {
    super.initState();
    _loadData();

    if (widget.isEditing && widget.transaction != null) {
      _populateForm();

      // Si estamos duplicando, no guardamos los valores originales
      if (!widget.isDuplicating) {
        _originalAccountId = widget.transaction!['accountId'];
        _originalAmount = widget.transaction!['amount']?.toDouble();
        _originalTransactionType = widget.transaction!['type'];
      }
    } else if (widget.preselectedAccountId != null) {
      _selectedAccountId = widget.preselectedAccountId;
    }
  }

  void _populateForm() {
    final transaction = widget.transaction!;

    setState(() {
      _transactionType = transaction['type'] ?? 'expense';
      _selectedAccountId = transaction['accountId'];
      _selectedCategoryId = transaction['categoryId'];

      if (transaction['dateTime'] != null) {
        final datetime = (transaction['dateTime'] as Timestamp).toDate();
        _selectedDate = datetime;
        _selectedTime = TimeOfDay.fromDateTime(datetime);
      }

      _descriptionController.text = transaction['description'] ?? '';
      _amountController.text = transaction['amount']?.toString() ?? '';
      _notesController.text = transaction['notes'] ?? '';

      _selectedCurrency = transaction['currencyCode'] ?? 'PEN';
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingData = true;
    });

    try {
      // Cargar cuentas
      final accounts = await _transactionService.loadAccounts(widget.userId);

      // Cargar categorías filtradas por tipo
      final categories = await _transactionService.getCategoriesByType(
        _transactionType,
      );

      if (mounted) {
        setState(() {
          _accounts = accounts;
          _categories = categories;

          // Si no hay cuenta seleccionada, seleccionar la primera
          if (_selectedAccountId == null && accounts.isNotEmpty) {
            _selectedAccountId = accounts.first.id;
          }

          // Establecer categoría predeterminada si no está seleccionada
          if (_selectedCategoryId == null) {
            final defaultCategory = _getDefaultCategory(categories);
            if (defaultCategory != null) {
              _selectedCategoryId = defaultCategory.id;
            }
          }

          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingData = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al cargar datos: $e")));
      }
    }
  }

  // Obtener categoría predeterminada
  Category? _getDefaultCategory(List<Category> categories) {
    if (categories.isEmpty) return null;

    // Buscar categoría "general" primero
    for (var category in categories) {
      if (category.id == 'general') {
        return category;
      }
    }

    // Si no hay "general", usar la primera
    return categories.first;
  }

  Future<void> _updateCategoriesByType() async {
    setState(() {
      _loadingData = true;
    });

    try {
      // Cargar categorías filtradas por tipo
      final categories = await _transactionService.getCategoriesByType(
        _transactionType,
      );

      if (mounted) {
        setState(() {
          _categories = categories;

          // Establecer categoría predeterminada
          final defaultCategory = _getDefaultCategory(categories);
          if (defaultCategory != null) {
            _selectedCategoryId = defaultCategory.id;
          } else {
            _selectedCategoryId = null;
          }

          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingData = false;
        });
      }
    }
  }

  void _showCalculator() {
    // Obtener valor actual si existe
    double? currentValue;
    if (_amountController.text.isNotEmpty) {
      currentValue = double.tryParse(_amountController.text);
    }

    showDialog(
      context: context,
      builder:
          (context) => CalculatorDialog(
            initialValue: currentValue,
            onResult: (result) {
              setState(() {
                // Si el resultado termina en .0, mostrar solo el entero
                if (result == result.toInt().toDouble()) {
                  _amountController.text = result.toInt().toString();
                } else {
                  _amountController.text = result.toString();
                }
              });
            },
          ),
    );
  }

  void _confirmDelete() async {
    if (_isLoading) return;

    final choice = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Eliminar Transacción"),
            content: const Text("¿Qué deseas hacer con esta transacción?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop("cancel"),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop("trash"),
                child: Text(
                  "Mover a papelera",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop("delete"),
                child: Text(
                  "Eliminar permanentemente",
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ],
          ),
    );

    if (choice == "trash" && mounted) {
      _moveToTrash();
    } else if (choice == "delete" && mounted) {
      _deletePermanently();
    }
  }

  void _moveToTrash() async {
    setState(() => _isLoading = true);

    try {
      await _transactionService.moveToTrash(widget.userId, widget.docId!);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transacción movida a papelera")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  void _deletePermanently() async {
    setState(() => _isLoading = true);

    try {
      await _transactionService.deletePermanently(widget.userId, widget.docId!);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Transacción eliminada permanentemente"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al eliminar: ${e.toString()}")),
        );
      }
    }
  }

  void _duplicateTransaction() async {
    if (widget.transaction == null) return;

    // Navegar a la pantalla de nueva transacción con los datos precargados
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => AddTransactionScreen(
              userId: widget.userId,
              transaction: {
                ...widget.transaction!,
                // Cambiar la fecha a la actual
                'dateTime': Timestamp.fromDate(DateTime.now()),
                // Eliminar campos que no deben copiarse
                'createdAt': null,
                'updatedAt': null,
              },
              // Es importante NO pasar el docId para que se cree como nueva
              isEditing: false,
              isDuplicating: true,
            ),
      ),
    );
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor selecciona una cuenta")),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Obtener la fecha-hora combinada
        final DateTime dateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        // Verificar si la cuenta seleccionada es una tarjeta de crédito y si hay suficiente límite disponible
        if (_transactionType == 'expense') {
          final accountDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('accounts')
                  .doc(_selectedAccountId)
                  .get();

          if (accountDoc.exists) {
            final accountData = accountDoc.data()!;
            final bool isCreditCard = accountData['isCreditCard'] ?? false;

            if (isCreditCard) {
              final double creditLimit =
                  (accountData['creditLimit'] ?? 0.0).toDouble();
              final double currentBalance =
                  (accountData['balance'] ?? 0.0).toDouble();
              final double amount = double.parse(_amountController.text);
              final double availableCredit = creditLimit - currentBalance;

              if (amount > availableCredit) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "El monto excede el límite disponible de la tarjeta (${CurrencyUtil.format(amount: availableCredit, currencyCode: _selectedCurrency ?? 'PEN')})",
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
            }
          }
        }

        // Crear un objeto de transacción
        final transaction = FinancialTransaction(
          id: widget.docId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
          userId: widget.userId,
          accountId: _selectedAccountId!,
          categoryId: _selectedCategoryId ?? 'general',
          description: _descriptionController.text,
          amount: double.parse(_amountController.text),
          dateTime: dateTime,
          type: _transactionType,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          currencyCode: _selectedCurrency ?? 'PEN',
          isInTrash: false,
        );

        if (widget.isEditing && !widget.isDuplicating) {
          // Actualizar transacción existente
          await _transactionService.updateTransaction(
            transaction,
            originalAccountId: _originalAccountId,
            originalAmount: _originalAmount,
            originalType: _originalTransactionType,
          );

          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Transacción actualizada con éxito"),
              ),
            );
          }
        } else {
          // Nueva transacción
          await _transactionService.addTransaction(transaction);

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Transacción agregada con éxito")),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
        }
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          widget.hideAppBar
              ? null
              : AppBar(
                title: Text(
                  widget.isDuplicating
                      ? "Duplicar Transacción"
                      : widget.isEditing
                      ? "Editar Transacción"
                      : "Agregar Transacción",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.lightBackgroundColor,
                  ),
                ),
                backgroundColor: AppTheme.primaryColor,
                actions:
                    widget.isEditing && !widget.isDuplicating
                        ? [
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed:
                                _isLoading ? null : _duplicateTransaction,
                            tooltip: 'Duplicar transacción',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: _isLoading ? null : _confirmDelete,
                            tooltip: 'Eliminar transacción',
                          ),
                        ]
                        : null,
              ),
      body:
          _loadingData
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tipo de transacción
                      TransactionTypeSelector(
                        selectedType: _transactionType,
                        onTypeChanged: (type) {
                          setState(() {
                            _transactionType = type;
                          });
                          _updateCategoriesByType();
                        },
                      ),

                      const SizedBox(height: AppTheme.spacingL),

                      // Selector de cuenta
                      AccountChipSelector(
                        accounts: _accounts,
                        selectedAccountId: _selectedAccountId,
                        onAccountSelected: (accountId) {
                          setState(() {
                            _selectedAccountId = accountId;
                          });
                        },
                      ),

                      const SizedBox(height: AppTheme.spacingM),

                      // Selector de moneda
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Moneda',
                          prefixText:
                              CurrencyUtil
                                  .currencies[_selectedCurrency ?? 'PEN']!
                                  .symbol,
                        ),
                        value: _selectedCurrency ?? 'PEN',
                        items:
                            _currencyOptions.map((String currency) {
                              return DropdownMenuItem<String>(
                                value: currency,
                                child: Text(
                                  CurrencyUtil.currencies[currency]!.name,
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCurrency = newValue;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: AppTheme.spacingM),

                      // Monto y descripción
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _amountController,
                              decoration: InputDecoration(
                                labelText: 'Monto',
                                prefixText:
                                    CurrencyUtil
                                        .currencies[_selectedCurrency ?? 'PEN']!
                                        .symbol,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calculate_outlined),
                                  tooltip: 'Calculadora',
                                  onPressed: () => _showCalculator(),
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa un monto';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Monto inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Descripción',
                                prefixIcon: Icon(Icons.description),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa una descripción';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.spacingM),

                      // Fecha y hora
                      DateTimePicker(
                        selectedDate: _selectedDate,
                        selectedTime: _selectedTime,
                        onDateChanged: (date) {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        onTimeChanged: (time) {
                          setState(() {
                            _selectedTime = time;
                          });
                        },
                      ),

                      const SizedBox(height: AppTheme.spacingM),

                      // Categoría usando CategorySelectorWidget
                      CategorySelectorWidget(
                        selectedCategoryId: _selectedCategoryId,
                        transactionType: _transactionType,
                        onCategorySelected: (categoryId) {
                          if (categoryId != null) {
                            setState(() {
                              _selectedCategoryId = categoryId;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: AppTheme.spacingM),

                      // Notas (opcional)
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notas (opcional)',
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: AppTheme.spacingXL),

                      // Botón de guardar
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveTransaction,
                        icon:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Icon(
                                  widget.isDuplicating || !widget.isEditing
                                      ? Icons.add
                                      : Icons.save,
                                ),
                        label: Text(
                          widget.isDuplicating
                              ? 'Guardar Duplicado'
                              : widget.isEditing
                              ? 'Actualizar'
                              : 'Añadir Transacción',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingM,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
