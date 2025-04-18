import 'dart:io';
import 'package:chanchi_app/models/category.dart';
import 'package:chanchi_app/models/currency_util.dart';
import 'package:chanchi_app/models/transaction.dart';
import 'package:chanchi_app/presentation/pages/home/home_screen.dart';
import 'package:chanchi_app/presentation/widgets/category_selector.dart';
import 'package:chanchi_app/services/category_service.dart';
import 'package:chanchi_app/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/models/account.dart';

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
  final _firestore = FirebaseFirestore.instance;
  final TransactionService _transactionService = TransactionService();
  final CategoryService _categoryService = CategoryService();
  String? _selectedCurrency;

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
  final List<String> _currencyOptions = ['PEN', 'USD', 'EUR'];

  // Estado de la pantalla
  bool _isLoading = false;
  List<Account> _accounts = [];
  List<Category> _categories = [];
  bool _loadingData = true;

  String? _originalAccountId; // Para guardar la cuenta original al editar
  double? _originalAmount; // Para guardar el monto original al editar
  String? _originalTransactionType; // Para guardar el tipo original al editar

  @override
  void initState() {
    super.initState();
    _loadData();

    if (widget.isEditing && widget.transaction != null) {
      _populateForm();

      // Si estamos duplicando, no guardamos los valores originales para
      // poder crear una nueva transacción correctamente
      if (!widget.isDuplicating) {
        // Guardar valores originales para manejo adecuado al cambiar de cuenta
        _originalAccountId = widget.transaction!['accountId'];
        _originalAmount = widget.transaction!['amount']?.toDouble();
        _originalTransactionType = widget.transaction!['type'];
      }
    } else if (widget.preselectedAccountId != null) {
      _selectedAccountId = widget.preselectedAccountId;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingData = true;
    });

    try {
      // Cargar cuentas
      final accountsSnapshot =
          await _firestore
              .collection('users')
              .doc(widget.userId)
              .collection('accounts')
              .get();

      final List<Account> accounts =
          accountsSnapshot.docs.map((doc) {
            final data = doc.data();
            return Account(
              id: doc.id,
              name: data['name'] ?? '',
              type: data['type'] ?? '',
              institution: data['institution'] ?? '',
              balance: (data['balance'] ?? 0.0).toDouble(),
              iconName: data['iconName'],
              color: data['color'],
            );
          }).toList();

      // Cargar categorías filtradas por tipo
      List<Category> categoryList = await _categoryService.getCategoriesByType(
        _transactionType,
      );

      if (mounted) {
        setState(() {
          _accounts = accounts;
          _categories = categoryList;

          // Si no hay cuenta seleccionada, seleccionar la primera
          if (_selectedAccountId == null && accounts.isNotEmpty) {
            _selectedAccountId = accounts.first.id;
          }

          _loadingData = false;
        });
      }
    } catch (e) {
      print('Error al cargar datos: $e');
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

  // Método modificado para priorizar 'general' como categoría por defecto
  Future<void> _updateCategoriesByType() async {
    setState(() {
      _loadingData = true;
    });

    try {
      // Cargar categorías filtradas por tipo
      List<Category> categoryList = await _categoryService.getCategoriesByType(
        _transactionType,
      );

      if (mounted) {
        setState(() {
          _categories = categoryList;
          _loadingData = false;

          // MODIFICACIÓN: Buscar la categoría "general" primero
          Category? generalCategory;

          // Intentar encontrar la categoría "general"
          for (var category in categoryList) {
            if (category.id == 'general') {
              generalCategory = category;
              break;
            }
          }

          // Si encontramos "general", seleccionarla; de lo contrario, usar la primera
          if (generalCategory != null) {
            _selectedCategoryId = generalCategory.id;
          } else if (categoryList.isNotEmpty) {
            _selectedCategoryId = categoryList.first.id;
          } else {
            _selectedCategoryId = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingData = false;
        });
        print('Error al cargar categorías: $e');
      }
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

  // Modificar la función para mover a papelera en lugar de eliminar
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

  // Nueva función para mover a papelera
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

  // Función para eliminar permanentemente
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

  // Nueva función para duplicar transacción
  void _duplicateTransaction() async {
    final transaction = widget.transaction!;

    // Navegar a la pantalla de nueva transacción con los datos precargados
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => AddTransactionScreen(
              userId: widget.userId,
              transaction: {
                ...transaction,
                // Cambiar la fecha a la actual
                'dateTime': Timestamp.fromDate(DateTime.now()),
                // Eliminar campos que no deben copiarse
                'createdAt': null,
                'updatedAt': null,
              },
              // Es importante NO pasar el docId para que se cree como nueva
              isEditing: false,
            ),
      ),
    );
  }

  //método nuevo para verificar la conectividad
  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
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
        final double amount = double.parse(_amountController.text);
        final description = _descriptionController.text;
        final notes = _notesController.text;
        final DateTime dateTime = _getDateTime();

        // Datos de la transacción para la colección principal
        Map<String, dynamic> transactionData = {
          'userId': widget.userId,
          'accountId': _selectedAccountId,
          'categoryId':
              _selectedCategoryId ??
              'general', // ID de categoría por defecto si no se ha seleccionado
          'description': description,
          'amount': amount,
          'dateTime': Timestamp.fromDate(dateTime),
          'type': _transactionType,
          'notes': notes.isEmpty ? null : notes,
          'currencyCode': _selectedCurrency ?? 'PEN',
          'updatedAt': FieldValue.serverTimestamp(),
          'isInTrash': false,
        };

        // Si estamos duplicando, tratarlo como una nueva transacción
        if (widget.isDuplicating || !widget.isEditing) {
          transactionData['createdAt'] = FieldValue.serverTimestamp();

          // Verificar si estamos en modo offline
          final isConnected = await _checkConnectivity();

          if (isConnected) {
            // Modo online: Crear nueva transacción usando FirebaseFirestore
            await _firestore.runTransaction((transaction) async {
              // Obtener la cuenta
              final accountRef = _firestore
                  .collection('users')
                  .doc(widget.userId)
                  .collection('accounts')
                  .doc(_selectedAccountId);
              final accountDoc = await transaction.get(accountRef);

              if (!accountDoc.exists) {
                throw Exception("La cuenta no existe");
              }

              final accountData = accountDoc.data() as Map<String, dynamic>;
              double currentBalance =
                  (accountData['balance'] ?? 0.0).toDouble();

              // Ajustar balance según tipo de transacción
              if (_transactionType == 'expense') {
                currentBalance -= amount; // Restar un gasto
              } else {
                currentBalance += amount; // Sumar un ingreso
              }

              // Si estamos duplicando y tenemos un ID de documento, actualizar ese documento
              // en lugar de crear uno nuevo
              DocumentReference docRef;
              if (widget.isDuplicating && widget.docId != null) {
                docRef = _firestore
                    .collection('transactions')
                    .doc(widget.docId);
                transaction.update(docRef, transactionData);
              } else {
                // Crear una nueva transacción
                docRef = _firestore.collection('transactions').doc();
                transaction.set(docRef, transactionData);
              }

              // Actualizar el balance de la cuenta
              transaction.update(accountRef, {'balance': currentBalance});
            });
          } else {
            // Modo offline: Usar TransactionService para guardar pendiente
            // Crear un objeto de transacción financiera para usar con el servicio
            final transaction = FinancialTransaction(
              id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
              userId: widget.userId,
              accountId: _selectedAccountId!,
              categoryId: _selectedCategoryId ?? 'general',
              description: description,
              amount: amount,
              dateTime: dateTime,
              type: _transactionType,
              notes: notes.isEmpty ? null : notes,
              currencyCode: _selectedCurrency ?? 'PEN',
              isInTrash: false,
            );

            await _transactionService.addTransaction(transaction);

            // Mostrar mensaje de operación pendiente
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Transacción guardada localmente. Se sincronizará cuando haya conexión.",
                  ),
                  backgroundColor: Colors.amber,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }

          // Actualizar presupuestos para la nueva transacción (solo si es un gasto)
          if (_transactionType == 'expense') {
            await _transactionService.updateBudgetsForNewTransaction(
              context,
              widget.userId,
              transactionData,
            );
          }

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Transacción agregada con éxito")),
            );
          }
        } else {
          if (!widget.isEditing) {
            transactionData['createdAt'] = FieldValue.serverTimestamp();
          }

          // Verificar si estamos en modo offline
          final isConnected = await _checkConnectivity();

          if (isConnected) {
            // Modo online: Actualizar normalmente
            // ...resto del código existente para actualizar transacciones...

            // Referencia a la cuenta seleccionada
            final accountRef = _firestore
                .collection('users')
                .doc(widget.userId)
                .collection('accounts')
                .doc(_selectedAccountId);

            if (widget.isEditing && widget.docId != null) {
              // Editar transacción existente
              final transactionRef = _firestore
                  .collection('transactions')
                  .doc(widget.docId);

              await _firestore.runTransaction((transaction) async {
                // Obtener la transacción original y la cuenta actual
                final transactionDoc = await transaction.get(transactionRef);
                final accountDoc = await transaction.get(accountRef);

                if (!transactionDoc.exists || !accountDoc.exists) {
                  throw Exception("Documento no encontrado");
                }

                final oldData = transactionDoc.data() as Map<String, dynamic>;
                final accountData = accountDoc.data() as Map<String, dynamic>;
                double currentBalance =
                    (accountData['balance'] ?? 0.0).toDouble();

                // Si es la misma cuenta, hacemos el ajuste normal
                if (_originalAccountId == _selectedAccountId) {
                  // Ajustar balance según tipo
                  double oldAmount = (oldData['amount'] ?? 0.0).toDouble();

                  // Deshacer la transacción original
                  if (oldData['type'] == 'expense') {
                    currentBalance +=
                        oldAmount; // Sumamos el valor original (revertimos el gasto)
                  } else {
                    currentBalance -=
                        oldAmount; // Restamos el valor original (revertimos el ingreso)
                  }

                  // Aplicar la nueva transacción
                  if (_transactionType == 'expense') {
                    currentBalance -= amount; // Restamos el nuevo gasto
                  } else {
                    currentBalance += amount; // Sumamos el nuevo ingreso
                  }

                  // Actualizar la transacción y el balance de la cuenta
                  transaction.update(transactionRef, transactionData);
                  transaction.update(accountRef, {'balance': currentBalance});
                } else {
                  // Si cambió la cuenta, necesitamos ajustar ambas cuentas
                  // ... resto del código existente para cambio de cuenta ...

                  // 1. Obtener la cuenta original
                  final originalAccountRef = _firestore
                      .collection('users')
                      .doc(widget.userId)
                      .collection('accounts')
                      .doc(_originalAccountId);

                  final originalAccountDoc = await transaction.get(
                    originalAccountRef,
                  );

                  if (!originalAccountDoc.exists) {
                    throw Exception("La cuenta original no existe");
                  }

                  final originalAccountData =
                      originalAccountDoc.data() as Map<String, dynamic>;
                  double originalBalance =
                      (originalAccountData['balance'] ?? 0.0).toDouble();

                  // 2. Ajustar el balance de la cuenta original (revertir la transacción)
                  if (_originalTransactionType == 'expense') {
                    originalBalance += _originalAmount!; // Revertir un gasto
                  } else {
                    originalBalance -= _originalAmount!; // Revertir un ingreso
                  }

                  // 3. Actualizar la cuenta original
                  transaction.update(originalAccountRef, {
                    'balance': originalBalance,
                  });

                  // 4. Ajustar el balance de la nueva cuenta (aplicar la nueva transacción)
                  if (_transactionType == 'expense') {
                    currentBalance -= amount; // Aplicar un nuevo gasto
                  } else {
                    currentBalance += amount; // Aplicar un nuevo ingreso
                  }

                  // 5. Actualizar la nueva cuenta
                  transaction.update(accountRef, {'balance': currentBalance});

                  // 6. Actualizar la transacción
                  transaction.update(transactionRef, transactionData);
                }
              });
            } else {
              // Crear nueva transacción
              await _firestore.runTransaction((transaction) async {
                // Obtener la cuenta
                final accountDoc = await transaction.get(accountRef);

                if (!accountDoc.exists) {
                  throw Exception("La cuenta no existe");
                }

                final accountData = accountDoc.data() as Map<String, dynamic>;
                double currentBalance =
                    (accountData['balance'] ?? 0.0).toDouble();

                // Ajustar balance según tipo de transacción
                if (_transactionType == 'expense') {
                  currentBalance -= amount; // Restar un gasto
                } else {
                  currentBalance += amount; // Sumar un ingreso
                }

                // Crear nueva transacción
                final docRef = _firestore.collection('transactions').doc();

                // Actualizar el balance de la cuenta y crear la transacción
                transaction.update(accountRef, {'balance': currentBalance});
                transaction.set(docRef, transactionData);
              });
            }
          } else {
            // Modo offline: Usar TransactionService
            if (widget.isEditing && widget.docId != null) {
              // Actualizar transacción existente
              final transaction = FinancialTransaction(
                id: widget.docId!,
                userId: widget.userId,
                accountId: _selectedAccountId!,
                categoryId: _selectedCategoryId ?? 'general',
                description: description,
                amount: amount,
                dateTime: dateTime,
                type: _transactionType,
                notes: notes.isEmpty ? null : notes,
                currencyCode: _selectedCurrency ?? 'PEN',
                isInTrash: false,
              );

              await _transactionService.updateTransaction(transaction);

              // Mostrar mensaje de operación pendiente
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Transacción actualizada localmente. Se sincronizará cuando haya conexión.",
                    ),
                    backgroundColor: Colors.amber,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            } else {
              // Crear nueva transacción
              final transaction = FinancialTransaction(
                id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                userId: widget.userId,
                accountId: _selectedAccountId!,
                categoryId: _selectedCategoryId ?? 'general',
                description: description,
                amount: amount,
                dateTime: dateTime,
                type: _transactionType,
                notes: notes.isEmpty ? null : notes,
                currencyCode: _selectedCurrency ?? 'PEN',
                isInTrash: false,
              );

              await _transactionService.addTransaction(transaction);

              // Mostrar mensaje de operación pendiente
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Transacción guardada localmente. Se sincronizará cuando haya conexión.",
                    ),
                    backgroundColor: Colors.amber,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            }
          }

          // Actualizar presupuestos si es necesario
          if (_transactionType == 'expense' ||
              _originalTransactionType == 'expense') {
            // Si la categoría o el monto cambió, actualizar los presupuestos
            if (_originalTransactionType == 'expense') {
              // Quitar el gasto anterior
              await _transactionService.updateBudgetsForTransaction(
                widget.userId,
                _originalAmount!,
                widget.transaction!['categoryId'],
                (widget.transaction!['dateTime'] as Timestamp).toDate(),
                false, // quitar
              );
            }

            if (_transactionType == 'expense') {
              // Añadir el nuevo gasto
              await _transactionService.updateBudgetsForTransaction(
                widget.userId,
                amount,
                _selectedCategoryId,
                dateTime,
                true, // añadir
              );
            }
          }

          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Transacción actualizada con éxito"),
              ),
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

  // Obtener un objeto DateTime completo con fecha y hora
  DateTime _getDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
    }
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
                    widget.isEditing &&
                            !widget
                                .isDuplicating // No mostrar estos botones en duplicación
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
                      Row(
                        children: [
                          Expanded(
                            child: _buildTransactionTypeButton(
                              type: 'expense',
                              icon: Icons.arrow_upward,
                              label: 'Gasto',
                              color: AppTheme.errorColor,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: _buildTransactionTypeButton(
                              type: 'income',
                              icon: Icons.arrow_downward,
                              label: 'Ingreso',
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.spacingL),

                      // Selector de cuenta
                      _buildAccountSelector(),

                      const SizedBox(height: AppTheme.spacingM),
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
                              ),
                              keyboardType: TextInputType.numberWithOptions(
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
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Fecha',
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_selectedDate),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickTime(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Hora',
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(_selectedTime.format(context)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.spacingM),

                      // Categoría usando CategorySelectorWidget
                      _buildCategorySelector(),

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

  Widget _buildTransactionTypeButton({
    required String type,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _transactionType == type;

    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _transactionType = type;
        });
        // Importante: actualizar categorías cuando cambia el tipo de transacción
        _updateCategoriesByType();
      },
      icon: Icon(icon, color: isSelected ? Colors.white : color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : color,
        backgroundColor: isSelected ? color : Colors.transparent,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
      ),
    );
  }

  Widget _buildAccountSelector() {
    if (_accounts.isEmpty) {
      return ListTile(
        title: const Text("No tienes cuentas configuradas"),
        subtitle: const Text("Debes crear al menos una cuenta"),
        trailing: const Icon(Icons.warning, color: AppTheme.warningColor),
        tileColor: AppTheme.warningColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cuenta', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppTheme.spacingS),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                _accounts.map((account) {
                  final isSelected = account.id == _selectedAccountId;
                  final color =
                      account.color != null
                          ? Color(
                            int.parse(
                                  account.color!.substring(1, 7),
                                  radix: 16,
                                ) +
                                0xFF000000,
                          )
                          : AppTheme.primaryColor;

                  return Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacingS),
                    child: ChoiceChip(
                      label: Text(account.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedAccountId = account.id;
                          });
                        }
                      },
                      avatar: Icon(
                        _getAccountIcon(account.iconName),
                        size: 18,
                        color: isSelected ? Colors.white : color,
                      ),
                      labelStyle: TextStyle(
                        color:
                            isSelected
                                ? Colors.white
                                : AppTheme.textPrimaryColor,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Colors.transparent,
                      selectedColor: color,
                      side: BorderSide(color: color),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  // Usar el componente CategorySelectorWidget para seleccionar categorías
  Widget _buildCategorySelector() {
    return CategorySelectorWidget(
      selectedCategoryId: _selectedCategoryId,
      transactionType: _transactionType,
      onCategorySelected: (categoryId) {
        print('Categoría seleccionada desde widget: $categoryId');
        if (categoryId != null) {
          setState(() {
            _selectedCategoryId = categoryId;
          });
        }
      },
    );
  }

  IconData _getAccountIcon(String? iconName) {
    switch (iconName) {
      case 'credit_card':
        return Icons.credit_card;
      case 'savings':
        return Icons.savings;
      case 'account_balance':
        return Icons.account_balance;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
