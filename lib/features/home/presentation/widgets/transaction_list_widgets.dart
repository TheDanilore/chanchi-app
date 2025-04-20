import 'dart:async';
import 'package:chanchi_app/features/home/presentation/widgets/transaction_filter_widget.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/data/models/category.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/services/connectivity_service.dart';
import 'package:chanchi_app/features/home/domain/services/transaction_list_service.dart';
import 'package:chanchi_app/core/widgets/transaction_list/empty_state_widget.dart';
import 'package:chanchi_app/core/widgets/transaction_list/transaction_date_group.dart';
import 'package:chanchi_app/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

class TransactionList extends StatefulWidget {
  final String userId;
  final Function(Map<String, dynamic>, String) onEditTransaction;
  final String? selectedCategoryId;
  final String? selectedAccountId;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime selectedMonth;
  final Function(String)? onError;
  final VoidCallback? onClearFilters;
  final VoidCallback? onRefresh;

  const TransactionList({
    Key? key,
    required this.userId,
    required this.onEditTransaction,
    this.selectedCategoryId,
    this.selectedAccountId,
    this.startDate,
    this.endDate,
    required this.selectedMonth,
    this.onError,
    this.onClearFilters,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<TransactionList> createState() => TransactionListState();
}

class TransactionListState extends State<TransactionList> {
  late TransactionListService _service;
  Map<String, Category> _categoriesCache = {};
  Map<String, Account> _accountsCache = {};
  bool _processingAction = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];

  // Filtros actuales
  String? _selectedCategoryId;
  String? _selectedAccountId;
  DateTime? _startDate;
  DateTime? _endDate;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _service = TransactionListService(userId: widget.userId);

    // Inicializar filtros desde los props del widget
    _selectedCategoryId = widget.selectedCategoryId;
    _selectedAccountId = widget.selectedAccountId;
    _startDate = widget.startDate;
    _endDate = widget.endDate;

    _loadData();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      _loadTransactions();
    });
  }

  // Método para exponer la función de carga de datos a otros widgets
  Future<void> loadData() async {
    await _loadTransactions();
  }

  @override
  void didUpdateWidget(TransactionList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si cambia el mes seleccionado, volver a cargar los datos
    if (oldWidget.selectedMonth.month != widget.selectedMonth.month ||
        oldWidget.selectedMonth.year != widget.selectedMonth.year) {
      _loadTransactions();
    }

    // Actualizar filtros si vienen nuevos desde widget
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId ||
        oldWidget.selectedAccountId != widget.selectedAccountId ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      setState(() {
        _selectedCategoryId = widget.selectedCategoryId;
        _selectedAccountId = widget.selectedAccountId;
        _startDate = widget.startDate;
        _endDate = widget.endDate;
      });
      _applyFilters();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _service.loadCategories();
      final accounts = await _service.loadAccounts();
      await _loadTransactions();

      if (mounted) {
        setState(() {
          _categoriesCache = categories;
          _accountsCache = accounts;
          _isLoading = false;
        });

        // Aplicar filtros iniciales
        _applyFilters();
      }
    } catch (e) {
      print('Error al cargar datos: $e');
      widget.onError?.call('Error al cargar datos: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTransactions() async {
    try {
      print(
        'TRANSACTION LIST: Cargando transacciones - Mes: ${widget.selectedMonth}',
      );
      print(
        'TRANSACTION LIST: Filtros - Cuenta: $_selectedAccountId, Categoría: $_selectedCategoryId',
      );
      print('TRANSACTION LIST: Rango de fechas: $_startDate - $_endDate');

      final transactions = await _service.getTransactions(
        selectedMonth: DateTime(
          widget.selectedMonth.year,
          widget.selectedMonth.month,
          1,
        ),
      );

      print('TRANSACTION LIST: Transacciones cargadas: ${transactions.length}');

      if (mounted) {
        setState(() {
          _transactions = transactions;
        });

        // Aplicar filtros a las nuevas transacciones
        _applyFilters();
      }

      widget.onRefresh?.call();
    } catch (e) {
      print('TRANSACTION LIST: Error al cargar transacciones: $e');
      widget.onError?.call('Error al cargar transacciones: $e');
    }
  }

  void _applyFilters() {
    if (!mounted) return;

    setState(() {
      _filteredTransactions =
          _transactions.where((transaction) {
            // Filtro por categoría
            if (_selectedCategoryId != null &&
                transaction['categoryId'] != _selectedCategoryId) {
              return false;
            }

            // Filtro por cuenta
            if (_selectedAccountId != null &&
                transaction['accountId'] != _selectedAccountId) {
              return false;
            }

            // Filtro por rango de fechas
            if (_startDate != null && _endDate != null) {
              final transactionDate =
                  (transaction['dateTime'] as Timestamp).toDate();
              if (transactionDate.isBefore(_startDate!) ||
                  transactionDate.isAfter(_endDate!)) {
                return false;
              }
            }

            return true;
          }).toList();
    });
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _applyFilters();
  }

  void _onAccountSelected(String? accountId) {
    setState(() {
      _selectedAccountId = accountId;
    });
    _applyFilters();
  }

  void _onDateRangeSelected(DateTime? startDate, DateTime? endDate) {
    setState(() {
      _startDate = startDate;
      _endDate = endDate;
    });
    _applyFilters();
  }

  void _onClearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedAccountId = null;
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();

    widget.onClearFilters?.call();
  }

  void _confirmAndMoveToTrash(String docId) async {
    if (await _confirmMoveToTrash(docId)) {
      await _moveToTrash(docId);
    }
  }

  Future<bool> _confirmMoveToTrash(String docId) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Mover a papelera"),
                content: const Text(
                  "¿Estás seguro de que deseas mover esta transacción a la papelera?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Cancelar"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      "Mover a papelera",
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Componente de filtros
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            0,
            AppTheme.spacingL,
            AppTheme.spacingM,
          ),
          child: TransactionFilterWidget(
            userId: widget.userId,
            onCategorySelected: _onCategorySelected,
            onAccountSelected: _onAccountSelected,
            onDateRangeSelected: _onDateRangeSelected,
            onClearFilters: _onClearFilters,
            selectedCategoryId: _selectedCategoryId,
            selectedAccountId: _selectedAccountId,
            startDate: _startDate,
            endDate: _endDate,
            selectedMonth: widget.selectedMonth,
            categoriesCache: _categoriesCache,
            accountsCache: _accountsCache,
          ),
        ),

        // Lista de transacciones
        Expanded(
          child:
              _filteredTransactions.isEmpty
                  ? EmptyStateWidget(
                    isFiltered:
                        _selectedCategoryId != null ||
                        _selectedAccountId != null ||
                        _startDate != null,
                    onClearFilters: _onClearFilters,
                  )
                  : _buildTransactionList(),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    final groupedTransactions = _groupTransactionsByDay(_filteredTransactions);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: ListView.builder(
        itemCount: groupedTransactions.length,
        itemBuilder: (context, index) {
          final dateGroup = groupedTransactions.keys.elementAt(index);
          final transactionsForDay = groupedTransactions[dateGroup]!;

          return TransactionDateGroup(
            dateTitle: dateGroup,
            transactions: transactionsForDay,
            onEditTransaction: widget.onEditTransaction,
            categoriesCache: _categoriesCache,
            accountsCache: _accountsCache,
            onDuplicate: _duplicateTransaction,
            onMoveToTrash: _confirmAndMoveToTrash,
          );
        },
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDay(
    List<Map<String, dynamic>> transactions,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var transaction in transactions) {
      final dateTime = (transaction['dateTime'] as Timestamp).toDate();
      final dateKey = DateFormat('dd MMM yyyy').format(dateTime);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }

      grouped[dateKey]!.add(transaction);
    }

    return grouped;
  }

  Future<void> _moveToTrash(String docId) async {
    if (_processingAction) return;

    setState(() {
      _processingAction = true;
    });

    try {
      // 1. Guardar una copia de la transacción original para restaurar en caso de error
      final originalTransaction = _filteredTransactions.firstWhere(
        (t) => t['id'] == docId,
        orElse: () => {},
      );

      // 2. INMEDIATAMENTE actualizar la UI para efecto visual instantáneo
      setState(() {
        _filteredTransactions.removeWhere((t) => t['id'] == docId);
        _transactions.removeWhere((t) => t['id'] == docId);
      });

      // 3. Intentar la operación real en segundo plano - CORRECCIÓN AQUÍ
      try {
        // Pasar context como segundo parámetro, no un Map
        await _service.moveToTrash(docId, context, refreshUI: false);

        // 4. Recargar datos en segundo plano para mantener sincronía
        try {
          await _loadTransactions();
        } catch (loadError) {
          print(
            'Error al recargar transacciones después de mover a papelera: $loadError',
          );
        }
      } catch (serviceError) {
        print('Error al mover a papelera: $serviceError');

        // 5. En caso de error severo, intentar restaurar la UI
        if (originalTransaction.isNotEmpty && mounted) {
          setState(() {
            _transactions.add(originalTransaction);
            _applyFilters();
          });

          // Solo mostrar error si no es un problema de permisos
          if (!serviceError.toString().contains('permission-denied') &&
              mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: No se pudo mover a papelera. Intente de nuevo.',
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error crítico al mover a papelera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ocurrió un error inesperado. Por favor, intente de nuevo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingAction = false;
        });
      }
    }
  }

  void _duplicateTransaction(Map<String, dynamic> transaction) async {
    if (_processingAction) return;

    setState(() {
      _processingAction = true;
    });

    try {
      // Crear una copia de la transacción para modificarla
      final Map<String, dynamic> duplicatedTransaction = {
        ...Map<String, dynamic>.from(transaction),
        // Cambiar la fecha a la actual
        'dateTime': Timestamp.fromDate(DateTime.now()),
        // Eliminar campos que no deben copiarse
        'createdAt': null,
        'updatedAt': null,
        'trashedAt': null,
      };

      // NO generar ID ahora - la transacción se guardará solo si el usuario confirma

      // Navegar a la pantalla de edición con los datos duplicados
      await Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder:
                  (_) => AddTransactionScreen(
                    userId: widget.userId,
                    transaction: duplicatedTransaction,
                    // No pasar docId para que se cree como nueva transacción
                    isEditing: false,
                    isDuplicating: true,
                  ),
            ),
          )
          .then((_) {
            // Recargar datos al volver
            _loadTransactions();
          });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al preparar duplicación: ${e.toString()}"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingAction = false;
        });
      }
    }
  }
}
