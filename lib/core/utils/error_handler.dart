// lib/core/utils/error_handler.dart
import 'package:flutter/material.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'dart:developer' as developer;

class ErrorHandler {
  // Mostrar un snackbar de error
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
  
  // Mostrar un snackbar de éxito
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
  
  // Registrar un error en el log
  static void logError(String message, dynamic error, [StackTrace? stackTrace]) {
    developer.log(
      message,
      error: error,
      stackTrace: stackTrace,
      name: 'ChanchiApp',
    );
  }
  
  // Manejo de errores con códigos específicos
  static String getErrorMessage(dynamic error) {
    // Para Firebase Auth
    if (error.toString().contains('wrong-password')) {
      return 'Contraseña incorrecta';
    } else if (error.toString().contains('user-not-found')) {
      return 'No existe una cuenta con este correo';
    } else if (error.toString().contains('email-already-in-use')) {
      return 'Ya existe una cuenta con este correo';
    } else if (error.toString().contains('weak-password')) {
      return 'La contraseña es demasiado débil';
    } else if (error.toString().contains('invalid-email')) {
      return 'Correo electrónico inválido';
    } else if (error.toString().contains('network-request-failed')) {
      return 'Error de conexión. Verifica tu conexión a internet';
    } else if (error.toString().contains('too-many-requests')) {
      return 'Demasiados intentos fallidos. Inténtalo más tarde';
    }
    
    // Error genérico
    return error.toString();
  }
  
  // Ejecutar una operación con manejo de errores
  static Future<T?> handleFuture<T>(
    Future<T> Function() operation,
    BuildContext context, {
    String? successMessage,
    String? errorMessage,
    Function(T)? onSuccess,
  }) async {
    try {
      final result = await operation();
      
      if (successMessage != null) {
        showSuccessSnackBar(context, successMessage);
      }
      
      if (onSuccess != null) {
        onSuccess(result);
      }
      
      return result;
    } catch (e, stackTrace) {
      final message = errorMessage ?? getErrorMessage(e);
      showErrorSnackBar(context, message);
      logError(message, e, stackTrace);
      return null;
    }
  }
  
  // Mostrar un diálogo de confirmación
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color confirmColor = Colors.red,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  // Mostrar un diálogo de carga
  static void showLoadingDialog(
    BuildContext context, {
    String message = 'Cargando...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }
  
  // Cerrar diálogo de carga
  static void hideLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }
  
  // Ejecutar operación con diálogo de carga
  static Future<T?> handleFutureWithLoading<T>(
    Future<T> Function() operation,
    BuildContext context, {
    String loadingMessage = 'Cargando...',
    String? successMessage,
    String? errorMessage,
    Function(T)? onSuccess,
  }) async {
    showLoadingDialog(context, message: loadingMessage);
    
    try {
      final result = await operation();
      
      hideLoadingDialog(context);
      
      if (successMessage != null) {
        showSuccessSnackBar(context, successMessage);
      }
      
      if (onSuccess != null) {
        onSuccess(result);
      }
      
      return result;
    } catch (e, stackTrace) {
      hideLoadingDialog(context);
      
      final message = errorMessage ?? getErrorMessage(e);
      showErrorSnackBar(context, message);
      logError(message, e, stackTrace);
      return null;
    }
  }
}