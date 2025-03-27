import 'package:chanchi_app/presentation/pages/add_transaction_screen.dart';
import 'package:chanchi_app/presentation/pages/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:chanchi_app/config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "Inicia sesión para ver tu balance financiero",
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
        ),
      );
    }

    final List<Widget> pages = [
      _buildHomePage(user.uid),
      AddTransactionScreen(userId: user.uid),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chanchi App',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.lightBackgroundColor,
          ),
        ),
        actions: [_buildProfileButton(user)],
        backgroundColor: AppTheme.primaryColor,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildProfileButton(User user) {
    return IconButton(
      icon: CircleAvatar(
        backgroundImage:
            user.photoURL != null ? NetworkImage(user.photoURL!) : null,
        child:
            user.photoURL == null
                ? Icon(Icons.person, color: AppTheme.cardColor)
                : null,
      ),
      onPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => ProfileScreen(user: user)));
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Agregar'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.textSecondaryColor,
      onTap: _onItemTapped,
    );
  }

  Future<void> _refreshData() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Widget _buildHomePage(String userId) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboard(userId),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              "Últimos movimientos",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Expanded(child: _buildTransactionList(userId)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return _buildErrorMessage("No hay datos disponibles");
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        double balance = (userData['balance'] ?? 0.0).toDouble();
        String formattedBalance = NumberFormat.currency(
          locale: 'es_PE',
          symbol: 'S/',
        ).format(balance);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          elevation: 4,
          color: AppTheme.primarySwatch,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Balance Actual",
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.cardColor),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  formattedBalance,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.cardColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('users')
              .doc(userId)
              .collection('transactions')
              .orderBy('date', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorMessage("Error al cargar transacciones");
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 48,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  "No hay transacciones recientes",
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  "Desliza hacia abajo para actualizar",
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var transaction =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            String docId = snapshot.data!.docs[index].id;
            return GestureDetector(
              onTap: () => _editTransaction(transaction, docId),
              child: Dismissible(
                key: Key(docId),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: AppTheme.errorColor,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Icon(Icons.delete, color: AppTheme.cardColor),
                ),
                onDismissed:
                    (direction) => _deleteTransaction(docId, transaction),
                child: _buildTransactionItem(transaction),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    String title = transaction['title'] ?? 'Sin título';
    double amount = (transaction['amount'] ?? 0.0).toDouble();
    String formattedAmount = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/',
    ).format(amount);
    bool isIncome = amount >= 0;
    DateTime date = (transaction['date'] as Timestamp).toDate();
    String formattedDate = DateFormat('d MMM, yyyy').format(date);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isIncome ? AppTheme.successColor : AppTheme.errorColor,
          child: Icon(
            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: AppTheme.cardColor,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(formattedDate),
        trailing: Text(
          formattedAmount,
          style: TextStyle(
            color: isIncome ? AppTheme.successColor : AppTheme.errorColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _deleteTransaction(
    String docId,
    Map<String, dynamic> transaction,
  ) async {
    try {
      final userId = _auth.currentUser!.uid;
      final userRef = _firestore.collection('users').doc(userId);
      final double transactionAmount =
          (transaction['amount'] ?? 0.0).toDouble();

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw Exception("El documento del usuario no existe");
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final double currentBalance = (userData['balance'] ?? 0.0).toDouble();
        final double newBalance = currentBalance - transactionAmount;

        transaction.update(userRef, {'balance': newBalance});
        transaction.delete(userRef.collection('transactions').doc(docId));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transacción eliminada correctamente")),
      );

      // Mostrar mensaje de deshacer durante 5 segundos
      await Future.delayed(const Duration(seconds: 5));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("¿Deseas deshacer los cambios?")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al eliminar la transacción: ${e.toString()}"),
        ),
      );

      // Deshacer cambios en caso de error
      await Future.delayed(const Duration(seconds: 5));
      final userId = _auth.currentUser!.uid;
      final userRef = _firestore.collection('users').doc(userId);
      final double transactionAmount =
          (transaction['amount'] ?? 0.0).toDouble();

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw Exception("El documento del usuario no existe");
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final double currentBalance = (userData['balance'] ?? 0.0).toDouble();
        final double newBalance = currentBalance + transactionAmount;

        transaction.update(userRef, {'balance': newBalance});
      });
    }
  }

  void _editTransaction(Map<String, dynamic> transaction, String docId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => AddTransactionScreen(
              userId: _auth.currentUser!.uid,
              transaction: transaction,
              docId: docId,
              isEditing: true,
            ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Center(
      child: Text(message, style: TextStyle(color: AppTheme.errorColor)),
    );
  }
}
