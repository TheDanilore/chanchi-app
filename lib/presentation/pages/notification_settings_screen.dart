import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/presentation/widgets/notification_settings_widget.dart';
import 'package:chanchi_app/services/notification_service.dart';
import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Notificaciones'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Widget de configuración de recordatorio diario
              const NotificationSettingsWidget(),
              
              const SizedBox(height: 24),
              
              // Sección informativa sobre notificaciones de presupuesto
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notificaciones de Presupuesto',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      const Text(
                        'Las notificaciones de presupuesto se envían automáticamente cuando:',
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildBulletPoint(
                        context,
                        'Te acercas al límite de tu presupuesto',
                        Icons.warning_amber_rounded,
                        Colors.orange,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      _buildBulletPoint(
                        context,
                        'Alcanzas el 100% de tu presupuesto',
                        Icons.error_outline,
                        Colors.red,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      _buildBulletPoint(
                        context,
                        'Excedes tu presupuesto',
                        Icons.money_off,
                        Colors.red.shade700,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      const Text(
                        'Puedes configurar las alertas individualmente para cada presupuesto desde la pantalla principal.',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botón para verificar permisos
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _checkNotificationPermissions(context),
                  icon: const Icon(Icons.security),
                  label: const Text('Verificar permisos de notificación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBulletPoint(
    BuildContext context, 
    String text, 
    IconData icon, 
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }
  
  Future<void> _checkNotificationPermissions(BuildContext context) async {
    try {
      final notificationService = NotificationService();
      bool hasPermission = await notificationService.requestNotificationPermissions();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasPermission
                  ? 'Tienes permisos para recibir notificaciones'
                  : 'No tienes permisos para recibir notificaciones',
            ),
            backgroundColor: hasPermission ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar permisos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}