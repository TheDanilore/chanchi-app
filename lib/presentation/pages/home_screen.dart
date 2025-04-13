import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/presentation/pages/accounts_screen.dart';
import 'package:chanchi_app/presentation/pages/add_transaction_screen.dart';
import 'package:chanchi_app/presentation/pages/profile/profile_screen.dart';
import 'package:chanchi_app/presentation/pages/trash_screen.dart';
import 'package:chanchi_app/presentation/widgets/analytics_dashboard.dart';
import 'package:chanchi_app/presentation/widgets/budget_dashboard_widget.dart';
import 'package:chanchi_app/presentation/widgets/financial_summary_dashboard_widgets.dart';
import 'package:chanchi_app/presentation/widgets/transaction_list_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  late TabController _tabController;
  bool _showFilterOptions = false;
  bool _showFinancialSummary =
      true; // Control para mostrar/ocultar el resumen financiero

  // Variables para filtros
  String? _selectedCategoryId;
  String? _selectedAccountId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

    // Determinar el título del AppBar basado en la pestaña seleccionada
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

    return Scaffold(
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
                  // Botón para acceder a la papelera
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
                  // Botón para acceder a la papelera
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
    );
  }

  Future<void> _refreshData() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Widget _buildHomePage(String userId) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Pestaña de resumen general
        RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: _refreshData,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Título del resumen financiero con opción para ocultar/mostrar
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
                              _showFinancialSummary = !_showFinancialSummary;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingS),

                    // Dashboard financiero mejorado (ocultable)
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState:
                          _showFinancialSummary
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                      firstChild: FinancialSummaryDashboard(
                        userId: userId,
                        onNavigateToTab: (index) {
                          setState(() => _selectedIndex = index);
                        },
                      ),
                      secondChild: const SizedBox(height: 0),
                    ),

                    const SizedBox(height: AppTheme.spacingL),

                    // Presupuestos (ocultable junto con el resumen financiero)
                    _showFinancialSummary
                        ? BudgetDashboardWidget(userId: userId)
                        : const SizedBox(),

                    const SizedBox(height: AppTheme.spacingL),

                    // Sección de filtros con animación
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Filtros",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  if (_startDate != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "Activos",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              IconButton(
                                icon: Icon(
                                  _showFilterOptions
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    _showFilterOptions = !_showFilterOptions;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_showFilterOptions) ...[
                            const SizedBox(height: AppTheme.spacingS),
                            // Solo filtro por fecha
                            _buildDateFilterChip(context),
                          ],
                        ],
                      ),
                    ),

                    // Título con indicador de filtros y fecha actual
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
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
                            const SizedBox(width: 8),
                            if (_startDate != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _startDate = null;
                                    _endDate = null;
                                  });
                                },
                                child: Icon(
                                  Icons.filter_list_off,
                                  size: 18,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(DateTime.now()),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.spacingS),
                  ]),
                ),
              ),

              // Lista de transacciones rediseñada
              SliverFillRemaining(
                child: TransactionList(
                  userId: userId,
                  onEditTransaction: _editTransaction,
                  selectedCategoryId: null, // No aplicamos filtro por categoría
                  selectedAccountId: null, // No aplicamos filtro por cuenta
                  startDate: _startDate,
                  endDate: _endDate,
                ),
              ),
            ],
          ),
        ),

        // Pestaña de análisis usando el widget externo
        AnalyticsDashboard(userId: userId),
      ],
    );
  }

  // Método para construir el filtro de fecha
  Widget _buildDateFilterChip(BuildContext context) {
    final hasDateFilter = _startDate != null || _endDate != null;

    String chipLabel = "Fecha";
    if (hasDateFilter) {
      final DateFormat formatter = DateFormat('dd/MM');
      if (_startDate != null && _endDate != null) {
        chipLabel =
            "${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}";
      } else if (_startDate != null) {
        chipLabel = "Desde ${formatter.format(_startDate!)}";
      } else if (_endDate != null) {
        chipLabel = "Hasta ${formatter.format(_endDate!)}";
      }
    }

    return FilterChip(
      label: Text(chipLabel),
      labelStyle: TextStyle(
        color:
            hasDateFilter ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      avatar: Icon(
        Icons.date_range,
        size: 16,
        color:
            hasDateFilter ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
      ),
      backgroundColor: Colors.white,
      selectedColor:
          hasDateFilter ? AppTheme.primaryColor.withOpacity(0.1) : null,
      selected: hasDateFilter,
      showCheckmark: false,
      elevation: 1,
      shadowColor: Colors.black12,
      side: BorderSide(
        color: hasDateFilter ? AppTheme.primaryColor : Colors.grey.shade300,
        width: 1,
      ),
      onSelected: (_) => _showDateRangePicker(context),
    );
  }

  void _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
            dialogBackgroundColor: Colors.white,
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
              elevation: 8,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
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
              hideAppBar: true,
            ),
      ),
    );
  }
}
