// lib/features/home/presentation/providers/home_provider.dart
import 'dart:async';
import 'package:chanchi_app/core/utils/error_handler.dart';
import 'package:chanchi_app/features/home/domain/services/home_service.dart';
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
  
  // Getters
  int get selectedIndex => _selectedIndex;
  bool get showFilterOptions => _showFilterOptions;
  bool get showFinancialSummary => _showFinancialSummary;
  bool get isOffline => _isOffline;
  bool get isSyncing => _isSyncing;
  int get pendingOperationsCount => _pendingOperationsCount;
  String get userId => _auth.currentUser?.uid ?? '';
  DateTime get selectedMonth => _selectedMonth;
  
  // Inicialización
  void initialize() {
    _checkConnectivity();
    _updatePendingOperationsCount();
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      _checkConnectivity();
    });
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
  
  // Métodos
  void onItemTapped(int index) {
    _selectedIndex = index;
    notifyListeners();
    
    if (index == 0) {
      loadTransactions();
    }
  }
  
  void toggleFilterOptions() {
    _showFilterOptions = !_showFilterOptions;
    notifyListeners();
  }
  
  void toggleFinancialSummary() {
    _showFinancialSummary = !_showFinancialSummary;
    notifyListeners();
  }
  
  Future<void> _updatePendingOperationsCount() async {
    if (_auth.currentUser != null) {
      final count = await _homeService.getPendingOperationsCount(
        _auth.currentUser!.uid,
      );
      _pendingOperationsCount = count;
      notifyListeners();
    }
  }
  
  Future<void> _checkConnectivity() async {
    bool wasOffline = _isOffline;
    final isConnected = await _homeService.checkConnectivity();
    _isOffline = !isConnected;
    notifyListeners();
    
    if (wasOffline && !_isOffline && _auth.currentUser != null) {
      await syncData();
    }
  }
  
  Future<void> syncData() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      final success = await _homeService.attemptSync();
      // El resultado se maneja en la UI
      await _updatePendingOperationsCount();
    } catch (e) {
      ErrorHandler.logError('Error al sincronizar', e);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  Future<void> loadTransactions() async {
    notifyListeners();
    await _updatePendingOperationsCount();
  }
  
  Future<void> refreshData() async {
    await loadTransactions();
    
    if (_isOffline && _pendingOperationsCount > 0) {
      await syncData();
    }
    
    notifyListeners();
  }
  
  void changeMonth(DateTime newMonth) {
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
    
    notifyListeners();
    loadTransactions();
  }
  
  void goToPreviousMonth() {
    changeMonth(DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1));
  }
  
  void goToNextMonth() {
    changeMonth(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1));
  }
}