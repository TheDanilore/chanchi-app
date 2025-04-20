// lib/features/home/presentation/widgets/home_body.dart
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/core/widgets/offline_indicator_widget.dart';
import 'package:chanchi_app/features/home/presentation/widgets/analytics_dashboard.dart';
import 'package:chanchi_app/features/home/presentation/widgets/budget_dashboard_widget.dart';
import 'package:chanchi_app/features/home/presentation/widgets/financial_summary_dashboard_widgets.dart';
import 'package:chanchi_app/features/home/presentation/widgets/month_selector_widget.dart';
import 'package:chanchi_app/features/home/presentation/widgets/transaction_list_widgets.dart';
import 'package:chanchi_app/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeBody extends StatefulWidget {
  final TabController tabController;
  final String userId;
  final bool isOffline;
  final bool isSyncing;
  final int pendingOperationsCount;
  final DateTime selectedMonth;
  final Function(DateTime) onMonthChanged;
  final Function() onRefresh;
  final Function() onSyncPressed;
  final VoidCallback? onTransferRequested;

  const HomeBody({
    Key? key,
    required this.tabController,
    required this.userId,
    required this.isOffline,
    required this.isSyncing,
    required this.pendingOperationsCount,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.onRefresh,
    required this.onSyncPressed,
    this.onTransferRequested,
  }) : super(key: key);

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  bool _showFinancialSummary = true;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isRefreshing = false;

  // Clave para el RefreshIndicator
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Referencias para actualizar los widgets hijos
  final GlobalKey<FinancialSummaryDashboardState> _financialSummaryKey =
      GlobalKey<FinancialSummaryDashboardState>();
  final GlobalKey<BudgetDashboardWidgetState> _budgetDashboardKey =
      GlobalKey<BudgetDashboardWidgetState>();
  final GlobalKey<TransactionListState> _transactionListKey =
      GlobalKey<TransactionListState>();

  @override
  void initState() {
    super.initState();
    _updateDateRange();
  }

  @override
  void didUpdateWidget(HomeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth) {
      _updateDateRange();
    }
  }

  void _updateDateRange() {
    setState(() {
      _startDate = DateTime(
        widget.selectedMonth.year,
        widget.selectedMonth.month,
        1,
        0,
        0,
        0,
      );
      _endDate = DateTime(
        widget.selectedMonth.year,
        widget.selectedMonth.month + 1,
        0,
        23,
        59,
        59,
        999,
      ).subtract(const Duration(milliseconds: 1));
    });
  }

  void _goToPreviousMonth() {
    widget.onMonthChanged(
      DateTime(widget.selectedMonth.year, widget.selectedMonth.month - 1, 1),
    );
  }

  void _goToNextMonth() {
    widget.onMonthChanged(
      DateTime(widget.selectedMonth.year, widget.selectedMonth.month + 1, 1),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedAccountId = null;
    });
  }

  void _editTransaction(Map<String, dynamic> transaction, String docId) async {
    try {
      // Navegar a la pantalla de edición de transacción
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => AddTransactionScreen(
                userId: widget.userId,
                transaction: transaction,
                docId: docId,
                isEditing: true,
              ),
        ),
      );

      // Refrescar los datos después de volver de la edición
      _refreshData();
    } catch (e) {
      print('Error al editar transacción: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al editar transacción: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para actualizar todos los componentes
  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Llamar al método de actualización del padre
      await widget.onRefresh();

      // Actualizar cada componente individualmente usando sus keys
      if (_financialSummaryKey.currentState != null) {
        await _financialSummaryKey.currentState!.refresh();
      }

      if (_budgetDashboardKey.currentState != null) {
        await _budgetDashboardKey.currentState!.refresh();
      }

      if (_transactionListKey.currentState != null) {
        await _transactionListKey.currentState!.loadData();
      }
    } catch (e) {
      print('Error al refrescar datos: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: widget.tabController,
      children: [_buildGeneralTab(), AnalyticsDashboard(userId: widget.userId)],
    );
  }

  Widget _buildGeneralTab() {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      color: AppTheme.primaryColor,
      onRefresh: _refreshData,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Indicador de modo sin conexión
              if (widget.isOffline && widget.pendingOperationsCount > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    child: OfflineIndicatorWidget(
                      isOffline: widget.isOffline,
                      isSyncing: widget.isSyncing,
                      pendingOperationsCount: widget.pendingOperationsCount,
                      onSyncPressed: widget.onSyncPressed,
                    ),
                  ),
                ),

              // Selector de mes
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 8.0),
                  child: MonthSelectorWidget(
                    selectedMonth: widget.selectedMonth,
                    onMonthChanged: widget.onMonthChanged,
                    onPreviousMonth: _goToPreviousMonth,
                    onNextMonth: _goToNextMonth,
                    canGoNext: widget.selectedMonth.isBefore(
                      DateTime(DateTime.now().year, DateTime.now().month + 1),
                    ),
                    style: MonthSelectorStyle(
                      selectedMonthStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      arrowColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),

              // Resumen Financiero
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 4.0,
                  ),
                  child: _buildFinancialSummarySection(),
                ),
              ),

              // Lista de transacciones
              SliverFillRemaining(
                hasScrollBody: true,
                child: TransactionList(
                  key: _transactionListKey,
                  userId: widget.userId,
                  onEditTransaction: _editTransaction,
                  selectedCategoryId: _selectedCategoryId,
                  selectedAccountId: _selectedAccountId,
                  startDate: _startDate,
                  endDate: _endDate,
                  selectedMonth: widget.selectedMonth,
                  onError: (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  onClearFilters: _clearFilters,
                  onRefresh: _refreshData,
                ),
              ),
            ],
          ),

          // Indicador de sincronización
          if (widget.isSyncing)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
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
    );
  }

  Widget _buildFinancialSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera de Resumen Financiero con botón desplegable
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Resumen Financiero",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(
                _showFinancialSummary
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppTheme.textSecondaryColor,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  _showFinancialSummary = !_showFinancialSummary;
                });
              },
            ),
          ],
        ),

        // Widget de resumen financiero
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState:
              _showFinancialSummary
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: FinancialSummaryDashboard(
              key: _financialSummaryKey,
              userId: widget.userId,
              selectedMonth: widget.selectedMonth,
              onNavigateToTab: (index) {
                // Implementar navegación entre tabs cuando esté disponible
              },
            ),
          ),
          secondChild: const SizedBox(height: 0),
        ),

        // Widget de presupuestos
        if (_showFinancialSummary)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: BudgetDashboardWidget(
              key: _budgetDashboardKey,
              userId: widget.userId,
            ),
          ),

        // Cabecera de Movimientos
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Movimientos",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
