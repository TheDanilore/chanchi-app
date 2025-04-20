// lib/features/profile/domain/providers/profile_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chanchi_app/features/profile/domain/services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final User user;
  final ProfileService _profileService;
  final FirebaseFirestore _firestore;
  
  // Estado de UI
  bool _isLoading = true;
  bool _isEditing = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isActive = true; // Para controlar si el provider está activo
  
  // Datos del perfil
  String _name = 'Usuario';
  String _email = '';
  String _avatarUrl = '';
  String _bio = 'Agrega una descripción sobre ti';
  
  // Estadísticas
  int _totalTransactions = 0;
  int _incomeCount = 0;
  int _expenseCount = 0;
  
  // Controladores para edición
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  // Constructor
  ProfileProvider(this.user, {
    ProfileService? profileService,
    FirebaseFirestore? firestore,
  }) : 
    _profileService = profileService ?? ProfileService(),
    _firestore = firestore ?? FirebaseFirestore.instance {
    // Inicializar perfil
    _initProfile();
  }
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  String get name => _name;
  String get email => _email;
  String get avatarUrl => _avatarUrl;
  String get bio => _bio;
  int get totalTransactions => _totalTransactions;
  int get incomeCount => _incomeCount;
  int get expenseCount => _expenseCount;
  
  // Método seguro para notificar a los oyentes
  void _safeNotifyListeners() {
    if (_isActive) {
      notifyListeners();
    }
  }
  
  // Manejar error
  void _handleError(dynamic error) {
    _hasError = true;
    
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        _errorMessage = 'No tienes permisos para realizar esta operación. Por favor, contacta a soporte.';
      } else {
        _errorMessage = 'Error de Firebase: ${error.message ?? error.code}';
      }
    } else {
      _errorMessage = error.toString();
    }
    
    print('Error en ProfileProvider: $_errorMessage');
  }
  
  // Inicializar perfil
  Future<void> _initProfile() async {
    if (!_isActive) return;
    
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    _safeNotifyListeners();
    
    try {
      // Asegurar que el usuario esté inicializado en Firestore
      try {
        await _profileService.initializeUser(user);
      } catch (e) {
        print('Error al inicializar usuario: $e');
        // Continuar a pesar del error de inicialización
      }
      
      // Cargar datos del perfil
      try {
        await _loadProfileData();
      } catch (e) {
        print('Error al cargar datos del perfil: $e');
        _handleError(e);
        // Continuar con datos predeterminados
      }
      
      // Cargar estadísticas
      try {
        await _loadStatistics();
      } catch (e) {
        print('Error al cargar estadísticas: $e');
        // No manejar como error crítico, continuar con estadísticas en cero
      }
      
    } catch (e) {
      _handleError(e);
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }
  
  // Cargar datos del perfil
  Future<void> _loadProfileData() async {
    if (!_isActive) return;
    
    try {
      final userData = await _profileService.getUserData(user.uid).first;
      
      if (userData.exists) {
        final data = userData.data() as Map<String, dynamic>;
        
        _name = data['name'] ?? user.displayName ?? 'Usuario';
        _email = data['email'] ?? user.email ?? 'Sin correo';
        _avatarUrl = data['avatarUrl'] ?? '';
        _bio = data['bio'] ?? 'Agrega una descripción sobre ti';
        
        // Inicializar controladores
        nameController.text = _name;
        bioController.text = _bio;
      } else {
        // Si no hay datos, usar datos del usuario de Firebase Auth
        _name = user.displayName ?? 'Usuario';
        _email = user.email ?? 'Sin correo';
        _avatarUrl = user.photoURL ?? '';
        
        // Inicializar controladores
        nameController.text = _name;
        bioController.text = _bio;
      }
      
      _safeNotifyListeners();
    } catch (e) {
      // En caso de error, usar datos básicos del usuario
      _name = user.displayName ?? 'Usuario';
      _email = user.email ?? 'Sin correo';
      _avatarUrl = user.photoURL ?? '';
      
      // Inicializar controladores
      nameController.text = _name;
      bioController.text = _bio;
      
      throw e;
    }
  }
  
  // Cargar estadísticas
  Future<void> _loadStatistics() async {
    if (!_isActive) return;
    
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .where('isInTrash', isEqualTo: false)
          .get();
      
      _totalTransactions = snapshot.docs.length;
      _incomeCount = 0;
      _expenseCount = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'income') {
          _incomeCount++;
        } else if (data['type'] == 'expense') {
          _expenseCount++;
        }
      }
      
      _safeNotifyListeners();
    } catch (e) {
      // En caso de error, dejar las estadísticas en cero
      _totalTransactions = 0;
      _incomeCount = 0;
      _expenseCount = 0;
      throw e;
    }
  }
  
  // Refrescar perfil
  void refreshProfile() {
    if (!_isActive) return;
    _initProfile();
  }
  
  // Actualizar estado de carga
  void setLoading(bool loading) {
    if (!_isActive) return;
    _isLoading = loading;
    _safeNotifyListeners();
  }
  
  // Cambiar a modo edición
  void setEditing([bool editing = true]) {
    if (!_isActive) return;
    _isEditing = editing;
    
    if (!editing) {
      // Si salimos de edición, limpiar contraseñas
      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    }
    
    _safeNotifyListeners();
  }
  
  // Limpiar error
  void clearError() {
    if (!_isActive) return;
    _hasError = false;
    _errorMessage = '';
    _safeNotifyListeners();
  }
  
  // Guardar perfil
  Future<bool> saveProfile() async {
    if (!_isActive) return false;
    
    setLoading(true);
    clearError();
    
    try {
      // Actualizar datos básicos
      await _profileService.updateUserProfile(user.uid, {
        'name': nameController.text.trim(),
        'bio': bioController.text.trim(),
      });

      // Cambiar contraseña si es necesario
      if (newPasswordController.text.isNotEmpty) {
        if (newPasswordController.text != confirmPasswordController.text) {
          throw Exception("Las contraseñas no coinciden");
        }

        if (oldPasswordController.text.isEmpty) {
          throw Exception("Debes ingresar tu contraseña actual");
        }

        await _profileService.changePassword(
          user,
          oldPasswordController.text,
          newPasswordController.text,
        );
      }
      
      // Actualizar datos locales
      _name = nameController.text.trim();
      _bio = bioController.text.trim();
      
      // Salir de modo edición
      setEditing(false);
      setLoading(false);
      return true;
    } catch (e) {
      _handleError(e);
      setLoading(false);
      return false;
    }
  }
  
  // Cerrar sesión
  Future<bool> signOut() async {
    if (!_isActive) return false;
    
    setLoading(true);
    clearError();
    
    try {
      await _profileService.signOut();
      setLoading(false);
      return true;
    } catch (e) {
      _handleError(e);
      setLoading(false);
      return false;
    }
  }
  
  // Eliminar cuenta
  Future<bool> deleteAccount(String password) async {
    if (!_isActive) return false;
    
    setLoading(true);
    clearError();
    
    try {
      await _profileService.deleteAccount(user, password);
      setLoading(false);
      return true;
    } catch (e) {
      _handleError(e);
      setLoading(false);
      return false;
    }
  }
  
  @override
  void dispose() {
    _isActive = false;
    // Limpiar controladores
    nameController.dispose();
    bioController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}