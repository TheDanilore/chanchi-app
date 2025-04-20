// lib/features/home/presentation/widgets/home_body.dart
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/core/widgets/offline_indicator_widget.dart';
import 'package:chanchi_app/features/home/presentation/widgets/analytics_dashboard.dart';
import 'package:chanchi_app/features/home/presentation/widgets/budget_dashboard_widget.dart';
import 'package:chanchi_app/features/home/presentation/widgets/financial_summary_dashboard_widgets.dart';
import 'package:chanchi_app/features/home/presentation/widgets/month_selector_widget.dart';
import 'package:chanchi_app/features/home/presentation/widgets/transaction_list_widgets.dart';
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
    // Esta función será implementada después al refactorizar AddTransactionScreen
  }

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: widget.tabController,
      children: [
        _buildGeneralTab(),
        AnalyticsDashboard(userId: widget.userId),
      ],
    );
  }

  Widget _buildGeneralTab() {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        await widget.onRefresh();
      },
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Indicador de modo sin conexión
              if (widget.isOffline && widget.pendingOperationsCount > 0)
                SliverToBoxAdapter(
                  child: OfflineIndicatorWidget(
                    isOffline: widget.isOffline,
                    isSyncing: widget.isSyncing,
                    pendingOperationsCount: widget.pendingOperationsCount,
                    onSyncPressed: widget.onSyncPressed,
                  ),
                ),

              // Selector de mes
              SliverToBoxAdapter(
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
                                _showFinancialSummary = !_showFinancialSummary;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.spacingS),

                      // Widget de resumen financiero
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 300),
                        crossFadeState: _showFinancialSummary
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: FinancialSummaryDashboard(
                          userId: widget.userId,
                          selectedMonth: widget.selectedMonth,
                          onNavigateToTab: (index) {
                            // Implementar navegación entre tabs cuando esté disponible
                          },
                        ),
                        secondChild: const SizedBox(height: 0),
                      ),

                      const SizedBox(height: AppTheme.spacingL),

                      // Widget de presupuestos
                      if (_showFinancialSummary)
                        BudgetDashboardWidget(userId: widget.userId),

                      const SizedBox(height: AppTheme.spacingL),

                      // Cabecera de Movimientos
                      Row(
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
                    ],
                  ),
                ),
              ),

              // Lista de transacciones
              SliverFillRemaining(
                hasScrollBody: true,
                child: TransactionList(
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
                  onRefresh: () {
                    widget.onRefresh();
                  },
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
    );
  }
}