import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:chanchi_app/features/home/presentation/widgets/trash_transaction_card.dart';
import 'package:chanchi_app/features/home/domain/services/transaction_list_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TrashScreen extends StatefulWidget {
  final String userId;

  const TrashScreen({super.key, required this.userId});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final _firestore = FirebaseFirestore.instance;
  late TransactionListService _service;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _service = TransactionListService(userId: widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Papelera de Transacciones",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.lightBackgroundColor,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _confirmEmptyTrash(),
            tooltip: 'Vaciar papelera',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Las transacciones se eliminarán automáticamente después de 30 días",
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: _buildTransactionList(),
                ),
              ],
            ),
    );
  }

  Widget _buildTransactionList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('transactions')
          .where('userId', isEqualTo: widget.userId)
          .where('isInTrash', isEqualTo: true)
          .orderBy('trashedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error al cargar las transacciones: ${snapshot.error}",
              style: TextStyle(color: AppTheme.errorColor),
            ),
          );
        }

        final transactions = snapshot.data?.docs ?? [];

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 64,
                  color: AppTheme.textSecondaryColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  "La papelera está vacía",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final doc = transactions[index];
            final data = doc.data() as Map<String, dynamic>;
            final id = doc.id;
            
            return TrashTransactionCard(
              transaction: data,
              docId: id,
              onRestore: () async {
                if (await _confirmRestore(id)) {
                  await _restoreTransaction(id);
                }
              },
              onDelete: () async {
                if (await _confirmPermanentDelete(id)) {
                  await _deleteTransactionPermanently(id);
                }
              },
              onViewDetails: () => _viewTransactionDetails(data, id),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmPermanentDelete(String docId) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar permanentemente"),
        content: const Text(
          "¿Estás seguro de que deseas eliminar permanentemente esta transacción? Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Eliminar",
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _confirmRestore(String docId) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restaurar transacción"),
        content: const Text(
          "¿Deseas restaurar esta transacción? Se volverá a ajustar el balance de la cuenta.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Restaurar"),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _restoreTransaction(String docId) async {
    setState(() => _isLoading = true);
    
    try {
      await _service.restoreFromTrash(docId, context);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _viewTransactionDetails(Map<String, dynamic> transaction, String docId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          userId: widget.userId,
          transaction: {
            ...transaction,
            'isInTrash': true,  // Asegurarnos de que se sabe que está en papelera
          },
          docId: docId,
          isEditing: true,
        ),
      ),
    );
  }

  Future<void> _deleteTransactionPermanently(String docId) async {
    setState(() => _isLoading = true);
    
    try {
      await _service.deleteTransactionPermanently(docId, context);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmEmptyTrash() async {
    final shouldEmpty = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Vaciar papelera"),
        content: const Text(
          "¿Estás seguro de que deseas eliminar permanentemente todas las transacciones en la papelera? Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Vaciar papelera",
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (shouldEmpty) {
      setState(() => _isLoading = true);
      try {
        await _service.emptyTrash(context);
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}