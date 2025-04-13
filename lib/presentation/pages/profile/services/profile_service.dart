// profile_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Obtener datos del usuario actual
  Stream<DocumentSnapshot> getUserData(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // Actualizar datos del usuario
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  // Subir imagen de perfil
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    // Crear referencia en Storage
    final storageRef = _storage
        .ref()
        .child('user_avatars')
        .child('${userId}_${path.basename(imageFile.path)}');

    // Subir imagen
    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask.whenComplete(() {});
    
    // Obtener URL
    final downloadUrl = await snapshot.ref.getDownloadURL();
    
    // Actualizar en Firestore
    await updateUserProfile(userId, {'avatarUrl': downloadUrl});
    
    return downloadUrl;
  }

  // Inicializar usuario en Firestore (si no existe)
  Future<void> initializeUser(User user) async {
    // Verificar si el usuario ya existe
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    
    if (!userDoc.exists) {
      // Si no existe, crear nuevo documento
      await _firestore.collection('users').doc(user.uid).set({
        'name': user.displayName ?? 'Usuario',
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'avatarUrl': user.photoURL ?? '', // Usar foto de Google si está disponible
        'bio': 'Agrega una descripción sobre ti',
      });
    } else if (user.photoURL != null && userDoc.data()?['avatarUrl'] == '') {
      // Si el usuario existe pero no tiene avatarUrl y viene de Google, actualizar
      await updateUserProfile(user.uid, {'avatarUrl': user.photoURL});
    }
  }

  // Cambiar contraseña
  Future<void> changePassword(User user, String oldPassword, String newPassword) async {
    // Reautenticar usuario
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );
    
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  // Eliminar cuenta
  Future<void> deleteAccount(User user, String password) async {
    // Reautenticar si es necesario
    if (user.providerData.any((provider) => provider.providerId == 'password')) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }
    
    // Eliminar datos del usuario
    final batch = _firestore.batch();
    
    // Eliminar transacciones
    final transactionsSnapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .get();
    
    for (var doc in transactionsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // Eliminar cuentas
    final accountsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('accounts')
        .get();
    
    for (var doc in accountsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // Eliminar el documento de usuario
    batch.delete(_firestore.collection('users').doc(user.uid));
    
    // Ejecutar operaciones en lote
    await batch.commit();
    
    // Eliminar la cuenta de autenticación
    await user.delete();
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
}