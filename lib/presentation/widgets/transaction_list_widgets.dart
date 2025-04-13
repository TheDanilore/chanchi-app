import 'package:chanchi_app/presentation/pages/add_transaction_screen.dart';
import 'package:chanchi_app/presentation/widgets/transaction_card.dart';
import 'package:chanchi_app/services/transaction_list_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/models/category.dart';
import 'package:chanchi_app/models/account.dart';

class TransactionList extends StatefulWidget {
  final String userId;
  final Function(Map<String, dynamic>, String) onEditTransaction;
  final String? selectedCategoryId;
  final String? selectedAccountId;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(String)? onError;

  const TransactionList({
    Key? key,
    required this.userId,
    required this.onEditTransaction,
    this.selectedCategoryId,
    this.selectedAccountId,
    this.startDate,
    this.endDate,
    this.onError,
  }) : super(key: key);

  @override
  _TransactionListState createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  late TransactionListService _service;
  Map<String, Category> _categoriesCache = {};
  Map<String, Account> _accountsCache = {};
  bool _processingAction = false;

  @override
  void initState() {
    super.initState();
    _service = TransactionListService(userId: widget.userId);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories = await _service.loadCategories();
      final accounts = await _service.loadAccounts();
      
      if (mounted) {
        setState(() {
          _categoriesCache = categories;
          _accountsCache = accounts;
        });
      }
    } catch (e) {
      print('Error al cargar datos: $e');
      widget.onError?.call('Error al cargar datos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _service.getTransactionsQuery(
        selectedAccountId: widget.selectedAccountId,
        selectedCategoryId: widget.selectedCategoryId,
      ).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          widget.onError?.call(
            'Error al cargar transacciones: ${snapshot.error}',
          );

          return Center(
            child: Text(
              "Error al cargar transacciones: ${snapshot.error}",
              style: TextStyle(color: AppTheme.errorColor),
            ),
          );
        }

        final documents = snapshot.data?.docs ?? [];

        if (documents.isEmpty) {
          return _buildEmptyState();
        }

        // Aplicar filtros adicionales
        final filteredDocs = _service.filterTransactionsByDate(
          documents,
          widget.startDate,
          widget.endDate,
        );

        if (filteredDocs.isEmpty) {
          return _buildEmptyState(isFiltered: true);
        }

        // Agrupar transacciones por día
        final groupedTransactions = _service.groupTransactionsByDay(filteredDocs);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
          child: ListView.builder(
            itemCount: groupedTransactions.length,
            itemBuilder: (context, index) {
              final dateGroup = groupedTransactions.keys.elementAt(index);
              final transactionsForDay = groupedTransactions[dateGroup]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingS,
                    ),
                    child: Text(
                      dateGroup,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...transactionsForDay.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;

                    return TransactionCard(
                      transaction: data,
                      docId: docId,
                      onEdit: widget.onEditTransaction,
                      category: _categoriesCache[data['categoryId']],
                      account: _accountsCache[data['accountId']],
                      onDuplicate: () => _duplicateTransaction(data),
                      onMoveToTrash: () async {
                        if (await _confirmMoveToTrash(docId)) {
                          await _moveToTrash(docId);
                        }
                      },
                    );
                  }).toList(),
                  const Divider(),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({bool isFiltered = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            isFiltered 
                ? "No hay transacciones con los filtros seleccionados" 
                : "No hay transacciones",
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(height: AppTheme.spacingM),
            TextButton.icon(
              onPressed: () {
                // Esta acción se manejaría desde la pantalla principal
                // donde se aplican los filtros
              },
              icon: Icon(Icons.filter_list_off, color: AppTheme.primaryColor),
              label: Text(
                "Quitar filtros",
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ]
        ],
      ),
    );
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
      await _service.moveToTrash(docId, context);
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
        context
      );
      
      if (newTransactionId != null) {
        final docSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .doc(newTransactionId)
          .get();
        final duplicatedTransaction = docSnapshot.data();

        if (duplicatedTransaction != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(
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