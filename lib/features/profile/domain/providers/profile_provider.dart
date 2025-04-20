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
  String get name => _name;
  String get email => _email;
  String get avatarUrl => _avatarUrl;
  String get bio => _bio;
  int get totalTransactions => _totalTransactions;
  int get incomeCount => _incomeCount;
  int get expenseCount => _expenseCount;
  
  // Inicializar perfil
  Future<void> _initProfile() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Asegurar que el usuario esté inicializado en Firestore
      await _profileService.initializeUser(user);
      
      // Cargar datos del perfil
      await _loadProfileData();
      
      // Cargar estadísticas
      await _loadStatistics();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }
  
  // Cargar datos del perfil
  Future<void> _loadProfileData() async {
    try {
      final userData = await _profileService.getUserData(user.uid).first;
      
      if (userData.exists) {
        final data = userData.data() as Map<String, dynamic>;
        
        _name = data['name'] ?? 'Usuario';
        _email = data['email'] ?? user.email ?? 'Sin correo';
        _avatarUrl = data['avatarUrl'] ?? '';
        _bio = data['bio'] ?? 'Agrega una descripción sobre ti';
        
        // Inicializar controladores
        nameController.text = _name;
        bioController.text = _bio;
      }
      
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }
  
  // Cargar estadísticas
  Future<void> _loadStatistics() async {
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
      
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }
  
  // Refrescar perfil
  void refreshProfile() {
    _initProfile();
  }
  
  // Actualizar estado de carga
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Cambiar a modo edición
  void setEditing([bool editing = true]) {
    _isEditing = editing;
    
    if (!editing) {
      // Si salimos de edición, limpiar contraseñas
      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    }
    
    notifyListeners();
  }
  
  // Guardar perfil
  Future<void> saveProfile() async {
    setLoading(true);
    
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
    } catch (e) {
      setLoading(false);
      throw e;
    }
  }
  
  // Cerrar sesión
  Future<void> signOut() async {
    await _profileService.signOut();
  }
  
  // Eliminar cuenta
  Future<void> deleteAccount(String password) async {
    await _profileService.deleteAccount(user, password);
  }
  
  @override
  void dispose() {
    // Limpiar controladores
    nameController.dispose();
    bioController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}