// lib/features/home/presentation/screens/home_screen.dart
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:chanchi_app/features/transactions/domain/services/transaction_service.dart';
import 'package:chanchi_app/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:chanchi_app/features/transactions/presentation/screens/transfer_screen.dart';
import 'package:flutter/material.dart';
import 'package:chanchi_app/features/home/presentation/providers/home_provider.dart';
import 'package:chanchi_app/features/home/presentation/widgets/home_app_bar.dart';
import 'package:chanchi_app/features/home/presentation/widgets/home_body.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeProvider(),
      child: HomeScreenContent(),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Inicializar datos
    final provider = Provider.of<HomeProvider>(context, listen: false);
    provider.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HomeProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        if (provider.selectedIndex == 0) {
          provider.loadTransactions();
        }
        return true;
      },
      child: Scaffold(
        appBar: HomeAppBar(
          tabController: _tabController,
          selectedIndex: provider.selectedIndex,
          isOffline: provider.isOffline,
          isSyncing: provider.isSyncing,
          pendingOperationsCount: provider.pendingOperationsCount,
          onSyncPressed: provider.syncData,
        ),
        body: _buildBody(provider),
        bottomNavigationBar: _buildBottomNavigationBar(provider),
      ),
    );
  }

  // In HomeScreenContent class
  Widget _buildBody(HomeProvider provider) {
    final List<Widget> pages = [
      HomeBody(
        tabController: _tabController,
        userId: provider.userId,
        isOffline: provider.isOffline,
        isSyncing: provider.isSyncing,
        pendingOperationsCount: provider.pendingOperationsCount,
        selectedMonth: provider.selectedMonth,
        onMonthChanged: provider.changeMonth,
        onRefresh: provider.refreshData,
        onSyncPressed: provider.syncData,
        onTransferRequested: () async {
          // Load accounts first
          final transactionService = TransactionService();
          final accounts = await transactionService.loadAccounts(
            provider.userId,
          );

          // Show transfer screen
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (_) => TransferScreen(
                    userId: provider.userId,
                    accounts: accounts,
                  ),
            ),
          );

          // Optional: Handle result if needed
          if (result == true) {
            provider.refreshData();
          }
        },
      ),
      AddTransactionScreen(userId: provider.userId, hideAppBar: true),
      AccountsScreen(userId: provider.userId),
    ];

    return pages[provider.selectedIndex];
  }

  Widget _buildBottomNavigationBar(HomeProvider provider) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline_rounded),
          label: 'Agregar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Cuentas',
        ),
      ],
      currentIndex: provider.selectedIndex,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.textSecondaryColor,
      onTap: provider.onItemTapped,
    );
  }
}
