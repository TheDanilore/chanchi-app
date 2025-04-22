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

// Modificación a HomeScreenContent para resolver el problema de acceso a la pantalla de agregar transacción
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
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

  // Método corregido para construir el cuerpo de la aplicación
  Widget _buildBody(HomeProvider provider) {
    // Usamos un IndexedStack para mantener el estado de las páginas
    return IndexedStack(
      index: provider.selectedIndex,
      children: [
        // Pantalla de inicio
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
            try {
              // Cargar cuentas primero
              final transactionService = TransactionService();
              final accounts = await transactionService.loadAccounts(
                provider.userId,
              );

              if (context.mounted) {
                // Mostrar pantalla de transferencia
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => TransferScreen(
                          userId: provider.userId,
                          accounts: accounts,
                        ),
                  ),
                );

                // Opcional: Manejar resultado si es necesario
                if (result == true) {
                  provider.refreshData();
                }
              }
            } catch (e) {
              print('Error al cargar cuentas para transferencia: $e');
            }
          },
        ),

        // Pantalla de agregar transacción (con manejo de errores)
        Builder(
          builder: (context) {
            // Usamos un try-catch para manejar posibles errores
            try {
              return AddTransactionScreen(
                userId: provider.userId,
                hideAppBar: true,
              );
            } catch (e) {
              // En caso de error, mostrar un widget simple con mensaje de error
              print('Error al cargar pantalla de agregar transacción: $e');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Error al cargar la pantalla de transacción'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Volver a la pantalla de inicio
                        provider.onItemTapped(0);
                      },
                      child: Text('Volver al inicio'),
                    ),
                  ],
                ),
              );
            }
          },
        ),

        // Pantalla de cuentas (con manejo de errores)
        Builder(
          builder: (context) {
            try {
              return AccountsScreen(userId: provider.userId);
            } catch (e) {
              // En caso de error, mostrar un widget simple con mensaje de error
              print('Error al cargar pantalla de cuentas: $e');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Error al cargar la pantalla de cuentas'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Volver a la pantalla de inicio
                        provider.onItemTapped(0);
                      },
                      child: Text('Volver al inicio'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
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
