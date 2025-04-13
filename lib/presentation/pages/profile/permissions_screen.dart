import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({Key? key}) : super(key: key);

  @override
  _PermissionsScreenState createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  // Estado de los permisos
  bool _notificationPermissionGranted = false;
  bool _storagePermissionGranted = false;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      // Usar métodos más específicos para diferentes plataformas
      final notificationStatus = Platform.isIOS 
          ? await Permission.notification.status 
          : await Permission.notification.status;
      
      final storageStatus = Platform.isAndroid 
          ? await Permission.storage.status 
          : PermissionStatus.granted;
      
      final locationStatus = await Permission.location.status;

      setState(() {
        _notificationPermissionGranted = notificationStatus.isGranted;
        _storagePermissionGranted = storageStatus.isGranted;
        _locationPermissionGranted = locationStatus.isGranted;
      });
    } catch (e) {
      print('Error al verificar permisos: $e');
      // Manejar el error de manera graciosa
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron verificar los permisos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      setState(() {
        _notificationPermissionGranted = status.isGranted;
      });

      if (!status.isGranted) {
        _showPermissionDeniedDialog('Notificaciones');
      }
    } catch (e) {
      print('Error al solicitar permiso de notificación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al solicitar permiso: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestStoragePermission() async {
    final status = await Permission.storage.request();
    setState(() {
      _storagePermissionGranted = status.isGranted;
    });

    if (!status.isGranted) {
      _showPermissionDeniedDialog('Almacenamiento');
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    setState(() {
      _locationPermissionGranted = status.isGranted;
    });

    if (!status.isGranted) {
      _showPermissionDeniedDialog('Ubicación');
    }
  }

  void _showPermissionDeniedDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permiso de $permissionType Denegado'),
        content: Text(
          'No has concedido el permiso de $permissionType. '
          'Puedes habilitarlo manualmente en la configuración de tu dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Permisos'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.7),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          children: [
            _buildPermissionCard(
              title: 'Notificaciones',
              subtitle: 'Recibe recordatorios y alertas',
              icon: Icons.notifications,
              isGranted: _notificationPermissionGranted,
              onTap: _requestNotificationPermission,
            ),
            // const SizedBox(height: AppTheme.spacingM),
            // _buildPermissionCard(
            //   title: 'Almacenamiento',
            //   subtitle: 'Guardar y compartir archivos',
            //   icon: Icons.storage,
            //   isGranted: _storagePermissionGranted,
            //   onTap: _requestStoragePermission,
            // ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: isGranted 
                    ? AppTheme.successColor.withOpacity(0.2)
                    : AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(
                icon,
                color: isGranted 
                    ? AppTheme.successColor 
                    : AppTheme.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 18
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isGranted 
                    ? Colors.green.shade50 
                    : AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
              child: Text(
                isGranted ? 'Concedido' : 'Habilitar',
                style: TextStyle(
                  color: isGranted ? Colors.green : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}