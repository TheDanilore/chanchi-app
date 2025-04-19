import 'dart:async';
import 'package:chanchi_app/features/home/domain/services/home_service.dart';
import 'package:chanchi_app/features/home/presentation/widgets/analytics_dashboard.dart';
import 'package:chanchi_app/features/home/presentation/widgets/budget_dashboard_widget.dart';
import 'package:chanchi_app/features/home/presentation/widgets/financial_summary_dashboard_widgets.dart';
import 'package:chanchi_app/features/home/presentation/widgets/month_selector_widget.dart';
import 'package:chanchi_app/features/home/presentation/widgets/transaction_list_widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:chanchi_app/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:chanchi_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:chanchi_app/presentation/pages/trash_screen.dart';
import 'package:chanchi_app/core/widgets/offline_indicator_widget.dart';
import 'package:chanchi_app/services/connectivity_service.dart';
import 'package:chanchi_app/services/offline_sync_service.dart';
import 'package:chanchi_app/features/transactions/domain/services/transaction_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _homeService = HomeService(
    FirebaseFirestore.instance,
    TransactionService(),
    ConnectivityService(),
    OfflineSyncService(),
  );

  int _selectedIndex = 0;
  late TabController _tabController;
  bool _showFilterOptions = false;
  bool _showFinancialSummary = true;
  bool _isOffline = false;
  bool _isSyncing = false;
  int _pendingOperationsCount = 0;

  String? _selectedCategoryId;
  String? _selectedAccountId;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime _selectedMonth = DateTime.now();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkConnectivity();
    _updatePendingOperationsCount();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      _checkConnectivity();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      _loadTransactions();
    }
  }

  Future<void> _updatePendingOperationsCount() async {
    if (_auth.currentUser != null) {
      final count = await _homeService.getPendingOperationsCount(
        _auth.currentUser!.uid,
      );
      if (mounted) {
        setState(() {
          _pendingOperationsCount = count;
        });
      }
    }
  }

  Future<void> _checkConnectivity() async {
    bool wasOffline = _isOffline;
    final isConnected = await _homeService.checkConnectivity();
    _isOffline = !isConnected;

    if (mounted) {
      setState(() {});
    }

    if (wasOffline && !_isOffline && _auth.currentUser != null) {
      setState(() {
        _isSyncing = true;
      });

      try {
        await _homeService.syncPendingOperations(_auth.currentUser!.uid);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conexión restablecida. Datos sincronizados.'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al sincronizar: $e'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSyncing = false;
          });

          _updatePendingOperationsCount();
        }
      }
    } else if (!wasOffline && _isOffline && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Modo sin conexión. Los cambios se guardarán localmente.',
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.amber[700],
        ),
      );
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {});
    await _updatePendingOperationsCount();
  }

  void _changeMonth(DateTime newMonth) {
    setState(() {
      _selectedMonth = DateTime(newMonth.year, newMonth.month, 1);
      _startDate = DateTime(
        _selectedMonth.year,
        _selectedMonth.month,
        1,
        0,
        0,
        0,
      );
      _endDate = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
        23,
        59,
        59,
        999,
      ).subtract(const Duration(milliseconds: 1));
    });
    _loadTransactions();
  }

  void _goToPreviousMonth() {
    _changeMonth(DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1));
  }

  void _goToNextMonth() {
    _changeMonth(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1));
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

    String appBarTitle;
    switch (_selectedIndex) {
      case 0:
        appBarTitle = 'Chanchi App';
        break;
      case 1:
        appBarTitle = 'Agregar Transacción';
        break;
      case 2:
        appBarTitle = 'Mis Cuentas';
        break;
      default:
        appBarTitle = 'Chanchi App';
    }

    final List<Widget> pages = [
      _buildHomePage(user.uid),
      AddTransactionScreen(userId: user.uid, hideAppBar: true),
      AccountsScreen(userId: user.uid),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex == 0) {
          _loadTransactions();
        }
        return true;
      },
      child: Scaffold(
        appBar:
            _selectedIndex == 0
                ? AppBar(
                  elevation: 0,
                  title: Text(
                    appBarTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.lightBackgroundColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    if (_isOffline)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Tooltip(
                              message: 'Modo sin conexión',
                              child: Icon(
                                Icons.cloud_off,
                                color: Colors.white.withOpacity(0.8),
                                size: 20,
                              ),
                            ),
                            if (_pendingOperationsCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 12,
                                    minHeight: 12,
                                  ),
                                  child: Text(
                                    _pendingOperationsCount > 9
                                        ? '9+'
                                        : _pendingOperationsCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (_isOffline)
                      IconButton(
                        icon:
                            _isSyncing
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.sync),
                        tooltip: 'Intentar sincronizar',
                        onPressed:
                            _isSyncing
                                ? null
                                : () async {
                                  setState(() {
                                    _isSyncing = true;
                                  });

                                  try {
                                    final success =
                                        await _homeService.attemptSync();
                                    if (success && mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Datos sincronizados correctamente',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      setState(() {
                                        _isOffline = false;
                                      });
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No hay conexión disponible. Inténtalo más tarde.',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error al sincronizar: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _isSyncing = false;
                                      });
                                      _updatePendingOperationsCount();
                                    }
                                  }
                                },
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TrashScreen(userId: user.uid),
                          ),
                        );
                      },
                      tooltip: 'Papelera de transacciones',
                    ),
                    IconButton(
                      icon: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        backgroundImage:
                            user.photoURL != null
                                ? NetworkImage(user.photoURL!)
                                : null,
                        child:
                            user.photoURL == null
                                ? Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                )
                                : null,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(user: user),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  backgroundColor: AppTheme.primaryColor,
                  bottom:
                      _selectedIndex == 0
                          ? PreferredSize(
                            preferredSize: const Size.fromHeight(48),
                            child: Container(
                              color: AppTheme.primaryColor,
                              child: TabBar(
                                controller: _tabController,
                                indicatorColor: Colors.white,
                                indicatorWeight: 3,
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.white.withOpacity(
                                  0.7,
                                ),
                                tabs: const [
                                  Tab(text: "General"),
                                  Tab(text: "Análisis"),
                                ],
                              ),
                            ),
                          )
                          : null,
                )
                : AppBar(
                  elevation: 0,
                  title: Text(
                    appBarTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.lightBackgroundColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    if (_isOffline)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Tooltip(
                          message: 'Modo sin conexión',
                          child: Icon(
                            Icons.cloud_off,
                            color: Colors.white.withOpacity(0.8),
                            size: 20,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TrashScreen(userId: user.uid),
                          ),
                        );
                      },
                      tooltip: 'Papelera de transacciones',
                    ),
                    IconButton(
                      icon: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        backgroundImage:
                            user.photoURL != null
                                ? NetworkImage(user.photoURL!)
                                : null,
                        child:
                            user.photoURL == null
                                ? Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                )
                                : null,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(user: user),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  backgroundColor: AppTheme.primaryColor,
                  bottom:
                      _selectedIndex == 0
                          ? PreferredSize(
                            preferredSize: const Size.fromHeight(48),
                            child: Container(
                              color: AppTheme.primaryColor,
                              child: TabBar(
                                controller: _tabController,
                                indicatorColor: Colors.white,
                                indicatorWeight: 3,
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.white.withOpacity(
                                  0.7,
                                ),
                                tabs: const [
                                  Tab(text: "General"),
                                  Tab(text: "Análisis"),
                                ],
                              ),
                            ),
                          )
                          : null,
                ),
        body: pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
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
          currentIndex: _selectedIndex,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondaryColor,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    print('Iniciando actualización de datos...');
    setState(() {});
    await _updatePendingOperationsCount();

    if (_isOffline && _pendingOperationsCount > 0) {
      print('Detectadas operaciones pendientes, intentando sincronizar...');
      await _syncData();
    }

    setState(() {});

    try {
      print('Recargando transacciones...');
      await _loadTransactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transacciones actualizadas'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error al recargar transacciones: $e');
    }

    await Future.delayed(const Duration(milliseconds: 500));
    print('Actualización de datos completada');
  }

  Widget _buildHomePage(String userId) {
    return TabBarView(
      controller: _tabController,
      children: [
        RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: _refreshData,
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Indicador de modo sin conexión
                  if (_isOffline && _pendingOperationsCount > 0)
                    SliverToBoxAdapter(
                      child: OfflineIndicatorWidget(
                        isOffline: _isOffline,
                        isSyncing: _isSyncing,
                        pendingOperationsCount: _pendingOperationsCount,
                        onSyncPressed: _syncData,
                      ),
                    ),

                  // Selector de mes
                  SliverToBoxAdapter(
                    child: MonthSelectorWidget(
                      selectedMonth: _selectedMonth,
                      onMonthChanged: _changeMonth,
                      onPreviousMonth: _goToPreviousMonth,
                      onNextMonth: _goToNextMonth,
                      canGoNext: _selectedMonth.isBefore(
                        DateTime(DateTime.now().year, DateTime.now().month + 1),
                      ),
                      style: MonthSelectorStyle(
                        selectedMonthStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        arrowColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),

                  // Resumen Financiero
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Column(
                        children: [
                          // Cabecera de Resumen Financiero
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Resumen Financiero",
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: Icon(
                                  _showFinancialSummary
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    _showFinancialSummary =
                                        !_showFinancialSummary;
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: AppTheme.spacingS),

                          // Widget de resumen financiero
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 300),
                            crossFadeState:
                                _showFinancialSummary
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                            firstChild: FinancialSummaryDashboard(
                              userId: userId,
                              selectedMonth: _selectedMonth,
                              onNavigateToTab: (index) {
                                setState(() => _selectedIndex = index);
                              },
                            ),
                            secondChild: const SizedBox(height: 0),
                          ),

                          const SizedBox(height: AppTheme.spacingL),

                          // Widget de presupuestos
                          if (_showFinancialSummary)
                            BudgetDashboardWidget(userId: userId),

                          const SizedBox(height: AppTheme.spacingL),

                          // Cabecera de Movimientos
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Movimientos",
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(DateTime.now()),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Lista de transacciones
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: TransactionList(
                      userId: userId,
                      onEditTransaction: _editTransaction,
                      selectedCategoryId: _selectedCategoryId,
                      selectedAccountId: _selectedAccountId,
                      startDate: _startDate,
                      endDate: _endDate,
                      selectedMonth: _selectedMonth,
                      onError: (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                      onClearFilters: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _selectedCategoryId = null;
                          _selectedAccountId = null;
                          _changeMonth(_selectedMonth);
                        });
                      },
                      onRefresh: () {
                        _loadTransactions();
                        _updatePendingOperationsCount();
                      },
                    ),
                  ),
                ],
              ),

              // Indicador de sincronización
              if (_isSyncing)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Sincronizando...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        AnalyticsDashboard(userId: userId),
      ],
    );
  }

  Future<void> _syncData() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final success = await _homeService.attemptSync();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos sincronizados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        _updatePendingOperationsCount();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay conexión disponible. Inténtalo más tarde.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
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
              hideAppBar: true,
            ),
      ),
    );

    _updatePendingOperationsCount();
  }
}
