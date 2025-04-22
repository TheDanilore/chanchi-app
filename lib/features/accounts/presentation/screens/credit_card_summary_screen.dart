// ignore_for_file: deprecated_member_use
import 'package:chanchi_app/features/accounts/presentation/screens/add_account_screen.dart';
import 'package:chanchi_app/features/accounts/presentation/widgets/credit_card_item.dart';
import 'package:chanchi_app/features/accounts/presentation/widgets/credit_summary_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/data/models/account.dart';

class CreditCardSummaryScreen extends StatelessWidget {
  final String userId;

  const CreditCardSummaryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Tarjetas de Crédito"),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('accounts')
                .where('isCreditCard', isEqualTo: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error al cargar las tarjetas: ${snapshot.error}"),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState(context);
          }

          // Crear una lista de objetos Account
          final cards =
              docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Account.fromMap(data, doc.id);
              }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CreditSummaryWidget(cards: cards),
              const SizedBox(height: 24),
              // Usar el nuevo widget CreditCardItem
              ...cards.map((card) => CreditCardItem(
                  card: card, 
                  userId: userId,
                  onUpdateIncludeInBalance: _updateCardIncludeInBalance,
                )),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCreditCardDialog(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            "No tienes tarjetas de crédito",
            style: TextStyle(color: Colors.grey[600], fontSize: 18),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddCreditCardDialog(context),
            icon: const Icon(Icons.add),
            label: const Text("Agregar tarjeta"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCreditCardDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddAccountScreen(
          userId: userId,
          initialAccountType: 'credit_card',
        ),
      ),
    );
  }

  // Método para actualizar el campo includeInTotalBalance de la tarjeta
  void _updateCardIncludeInBalance(String cardId, bool includeInBalance) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(cardId)
        .update({'includeInTotalBalance': includeInBalance});
  }
}