import 'package:android_intent_plus/android_intent.dart';
import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/presentation/widgets/notification_settings_widget.dart';
import 'package:chanchi_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
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

              const SizedBox(height: 16),
              // Botón para desactivar optimización de batería
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _disableBatteryOptimization(context),
                  icon: const Icon(Icons.battery_alert),
                  label: const Text('Desactivar optimización de batería'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
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

              const SizedBox(height: 16),

              // Sección de prueba y diagnóstico
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
                        'Diagnóstico y Prueba',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Usa estas opciones para verificar que las notificaciones funcionan correctamente.',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      ),

                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _sendTestNotification(context),
                            icon: const Icon(Icons.notifications_active),
                            label: const Text('Notificación inmediata'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),

                          ElevatedButton.icon(
                            onPressed:
                                () => _scheduleNotificationIn30Seconds(context),
                            icon: const Icon(Icons.timer),
                            label: const Text('Programar para 30s'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),

                          ElevatedButton.icon(
                            onPressed: () => _showNotificationStatus(context),
                            icon: const Icon(Icons.info_outline),
                            label: const Text('Ver estado'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
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
        Expanded(child: Text(text)),
      ],
    );
  }

  Future<void> _sendTestNotification(BuildContext context) async {
    try {
      final notificationService = NotificationService();

      await notificationService.showLocalNotification(
        'Prueba Inmediata',
        'Esta es una notificación de prueba enviada a las ${DateFormat('HH:mm:ss').format(DateTime.now())}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificación inmediata enviada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _scheduleNotificationIn30Seconds(BuildContext context) async {
    try {
      final notificationService = NotificationService();

      // Probar con 5 segundos para verificar más rápido
      await notificationService.scheduleNotification(
        title: 'Prueba Programada (5s)',
        body:
            'Esta notificación fue programada 5 segundos antes, a las ${DateFormat('HH:mm:ss').format(DateTime.now())}',
        seconds: 5, // Cambiar a 5 segundos para depuración
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificación programada para 5 segundos después'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Método para mostrar el estado de las notificaciones
  Future<void> _showNotificationStatus(BuildContext context) async {
    try {
      final notificationService = NotificationService();

      // Mostrar un diálogo de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verificando estado de notificaciones...'),
                ],
              ),
            ),
      );

      // Obtener el estado
      final status = await notificationService.debugNotificationStatus();

      // Cerrar el diálogo de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar el resultado
      if (context.mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Estado de Notificaciones'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...status.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black87),
                              children: [
                                TextSpan(
                                  text: '${entry.key}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: '${entry.value}'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      // Cerrar el diálogo de carga si sigue abierto
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _checkNotificationPermissions(BuildContext context) async {
    try {
      final notificationService = NotificationService();
      bool hasPermission =
          await notificationService.requestNotificationPermissions();

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

  Future<void> _disableBatteryOptimization(BuildContext context) async {
    // Intenta abrir la configuración de optimización de batería
    const intent = AndroidIntent(
      action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      data: 'package:com.example.chanchi_app', // Reemplaza con tu package
    );

    try {
      await intent.launch();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, desactiva la optimización de batería para que las notificaciones funcionen correctamente',
          ),
        ),
      );
    } catch (e) {
      // Si no se puede abrir automáticamente, dar instrucciones
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ve a Configuración > Aplicaciones > Chanchi App > Batería > Desactivar optimización',
          ),
        ),
      );
    }
  }
}
