// lib/features/home/presentation/providers/home_provider.dart
import 'dart:async';
import 'package:chanchi_app/core/utils/error_handler.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/data/models/category.dart';
import 'package:chanchi_app/features/home/domain/services/home_service.dart';
import 'package:chanchi_app/features/home/domain/services/transaction_list_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _homeService = HomeService();

  // Estado de UI
  int _selectedIndex = 0;
  bool _showFilterOptions = false;
  bool _showFinancialSummary = true;
  bool _isOffline = false;
  bool _isSyncing = false;
  int _pendingOperationsCount = 0;

  // Filtros
  String? _selectedCategoryId;
  String? _selectedAccountId;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime _selectedMonth = DateTime.now();

  // Suscripciones
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Variable para controlar si el provider está activo
  bool _isActive = true;

  // Getters
  int get selectedIndex => _selectedIndex;
  bool get showFilterOptions => _showFilterOptions;
  bool get showFinancialSummary => _showFinancialSummary;
  bool get isOffline => _isOffline;
  bool get isSyncing => _isSyncing;
  int get pendingOperationsCount => _pendingOperationsCount;
  String get userId => _auth.currentUser?.uid ?? '';
  DateTime get selectedMonth => _selectedMonth;

  @override
  void dispose() {
    _isActive = false;
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // Método de ayuda para verificar si es seguro llamar a notifyListeners
  void _safeNotifyListeners() {
    if (_isActive) {
      notifyListeners();
    }
  }

  // Métodos
  void onItemTapped(int index) {
    try {
      _selectedIndex = index;

      if (index == 0) {
        loadTransactions();
      }

      // Only notify listeners once at the end
      _safeNotifyListeners();
    } catch (e) {
      print('Error in onItemTapped: $e');
      // Ensure the state is updated even if there's an error
      _selectedIndex = index;
      _safeNotifyListeners();
    }
  }

  void toggleFilterOptions() {
    _showFilterOptions = !_showFilterOptions;
    _safeNotifyListeners();
  }

  void toggleFinancialSummary() {
    _showFinancialSummary = !_showFinancialSummary;
    _safeNotifyListeners();
  }

  // En HomeProvider:
  Map<String, Category> _categoriesCache = {};
  Map<String, Account> _accountsCache = {};

  // Y métodos getter:
  Map<String, Category> get categoriesCache => _categoriesCache;
  Map<String, Account> get accountsCache => _accountsCache;

  // Y cargar los datos en initialize()
  void initialize() {
    _checkConnectivity();
    _updatePendingOperationsCount();
    _loadCategoriesAndAccounts();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      _checkConnectivity();
    });
  }

  Future<void> _loadCategoriesAndAccounts() async {
    final service = TransactionListService(userId: userId);
    _categoriesCache = await service.loadCategories();
    _accountsCache = await service.loadAccounts();
    notifyListeners();
  }

  void updateCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    _safeNotifyListeners();
    loadTransactions(); // Recargar con el nuevo filtro
  }

  void updateAccountFilter(String? accountId) {
    _selectedAccountId = accountId;
    _safeNotifyListeners();
    loadTransactions(); // Recargar con el nuevo filtro
  }

  void updateDateRangeFilter(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _safeNotifyListeners();
    loadTransactions(); // Recargar con el nuevo filtro
  }

  void clearFilters() {
    _selectedCategoryId = null;
    _selectedAccountId = null;
    _startDate = null;
    _endDate = null;
    _safeNotifyListeners();
    loadTransactions(); // Recargar sin filtros
  }

  // Exponer también getters para estos filtros
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedAccountId => _selectedAccountId;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  Future<void> _updatePendingOperationsCount() async {
    if (_auth.currentUser != null) {
      final count = await _homeService.getPendingOperationsCount(
        _auth.currentUser!.uid,
      );
      _pendingOperationsCount = count;
      _safeNotifyListeners();
    }
  }

  Future<void> _checkConnectivity() async {
    bool wasOffline = _isOffline;
    final isConnected = await _homeService.checkConnectivity();
    _isOffline = !isConnected;

    if (!_isActive) return; // Verificar si el proveedor aún está activo
    _safeNotifyListeners();

    if (wasOffline && !_isOffline && _auth.currentUser != null) {
      await syncData();
    }
  }

  Future<void> syncData() async {
    if (_isSyncing || !_isActive) return;

    _isSyncing = true;
    _safeNotifyListeners();

    try {
      // El resultado se maneja en la UI
      await _updatePendingOperationsCount();
    } catch (e) {
      ErrorHandler.logError('Error al sincronizar', e);
    } finally {
      _isSyncing = false;
      _safeNotifyListeners();
    }
  }

  Future<void> loadTransactions() async {
    if (!_isActive) return;

    _safeNotifyListeners();
    await _updatePendingOperationsCount();
  }

  Future<void> refreshData() async {
    if (!_isActive) return;

    await loadTransactions();

    if (_isOffline && _pendingOperationsCount > 0) {
      await syncData();
    }

    _safeNotifyListeners();
  }

  void changeMonth(DateTime newMonth) {
    if (!_isActive) return;

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

    _safeNotifyListeners();
    loadTransactions();
  }

  void goToPreviousMonth() {
    changeMonth(DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1));
  }

  void goToNextMonth() {
    changeMonth(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1));
  }
}
