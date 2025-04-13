import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/services/notification_service.dart';
import 'package:flutter/material.dart';

class DailyReminderWidget extends StatefulWidget {
  const DailyReminderWidget({Key? key}) : super(key: key);

  @override
  _DailyReminderWidgetState createState() => _DailyReminderWidgetState();
}

class _DailyReminderWidgetState extends State<DailyReminderWidget> {
  final NotificationService _notificationService = NotificationService();
  bool _isReminderEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkReminderStatus();
  }

  Future<void> _checkReminderStatus() async {
    try {
      final isEnabled = await _notificationService.isDailyReminderEnabled();
      setState(() {
        _isReminderEnabled = isEnabled;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al verificar estado del recordatorio: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleReminder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isReminderEnabled) {
        await _notificationService.cancelDailyReminder();
        _showSnackBar('Recordatorio diario desactivado');
      } else {
        bool success = await _notificationService.scheduleDailyReminder();
        if (success) {
          _showSnackBar('Recordatorio diario activado para las 8:00 PM');
        } else {
          _showSnackBar('No se pudo activar el recordatorio. Verifica los permisos de notificación.');
        }
      }
      
      await _checkReminderStatus();
    } catch (e) {
      print('Error al cambiar estado del recordatorio: $e');
      _showSnackBar('Error al cambiar el recordatorio');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recordatorio diario',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Switch(
                        value: _isReminderEnabled,
                        onChanged: (_) => _toggleReminder(),
                        activeColor: AppTheme.primaryColor,
                      ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Recibe una notificación diaria a las 8:00 PM para recordarte registrar tus transacciones del día',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            if (!_isReminderEnabled && !_isLoading)
              OutlinedButton.icon(
                onPressed: _toggleReminder,
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Activar recordatorio'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}