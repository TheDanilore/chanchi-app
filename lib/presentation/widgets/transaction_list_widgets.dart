import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/models/category.dart';
import 'package:chanchi_app/models/account.dart';
import 'package:chanchi_app/services/connectivity_service.dart';
import 'package:chanchi_app/services/transaction_list_service.dart';
import 'package:chanchi_app/presentation/widgets/transaction_list/empty_state_widget.dart';
import 'package:chanchi_app/presentation/widgets/transaction_list/transaction_date_group.dart';
import 'package:chanchi_app/presentation/pages/add_transaction_screen.dart';
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
  _TransactionListState createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  late TransactionListService _service;
  Map<String, Category> _categoriesCache = {};
  Map<String, Account> _accountsCache = {};
  bool _processingAction = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _service = TransactionListService(userId: widget.userId);
    _loadData();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      _loadTransactions();
    });
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
        'TRANSACTION LIST: Filtros - Cuenta: ${widget.selectedAccountId}, Categoría: ${widget.selectedCategoryId}',
      );
      print(
        'TRANSACTION LIST: Rango de fechas: ${widget.startDate} - ${widget.endDate}',
      );

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
      }

      widget.onRefresh?.call();
    } catch (e) {
      print('TRANSACTION LIST: Error al cargar transacciones: $e');
      widget.onError?.call('Error al cargar transacciones: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return EmptyStateWidget(
        isFiltered:
            widget.startDate != null ||
            widget.endDate != null ||
            widget.selectedCategoryId != null ||
            widget.selectedAccountId != null,
        onClearFilters: widget.onClearFilters,
      );
    }

    final groupedTransactions = _groupTransactionsByDay(_transactions);

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

  Future<void> _moveToTrash(String docId) async {
    if (_processingAction) return;

    setState(() {
      _processingAction = true;
    });

    try {
      print('TransactionList: Moviendo a papelera: $docId');
      print('Transacciones antes de eliminar: ${_transactions.length}');

      setState(() {
        _transactions.removeWhere((t) => t['id'] == docId);
      });

      print('Transacciones después de eliminar: ${_transactions.length}');

      await _service.moveToTrash(docId, context, refreshUI: false);
      await _loadTransactions();
    } catch (e) {
      print('Error en TransactionList al mover a papelera: $e');
      await _loadTransactions();
      widget.onError?.call('Error al mover a papelera: $e');
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
      final newTransactionId = await _service.duplicateTransaction(
        transaction,
        context,
      );

      if (newTransactionId != null) {
        final docSnapshot =
            await FirebaseFirestore.instance
                .collection('transactions')
                .doc(newTransactionId)
                .get();
        final duplicatedTransaction = docSnapshot.data();

        if (duplicatedTransaction != null && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (_) => AddTransactionScreen(
                    userId: widget.userId,
                    transaction: duplicatedTransaction,
                    docId: newTransactionId,
                    isEditing: true,
                    isDuplicating: true,
                  ),
            ),
          );
        }
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
