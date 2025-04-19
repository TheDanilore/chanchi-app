import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/services/notification_service.dart';
import 'package:flutter/material.dart';

class NotificationSettingsWidget extends StatefulWidget {
  const NotificationSettingsWidget({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsWidget> createState() => _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState extends State<NotificationSettingsWidget> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  bool _isReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final isEnabled = await _notificationService.isDailyReminderEnabled();
      final configuredTime = await _notificationService.getConfiguredReminderTime();
      
      setState(() {
        _isReminderEnabled = isEnabled;
        _reminderTime = configuredTime;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar configuración de notificaciones: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _toggleReminder(bool value) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (value) {
        // Solicitar permisos y programar recordatorio
        bool hasPermission = await _notificationService.requestNotificationPermissions();
        
        if (!hasPermission) {
          _showMessage('Permisos de notificación denegados', isError: true);
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        bool success = await _notificationService.scheduleDailyReminder(
          hour: _reminderTime.hour,
          minute: _reminderTime.minute,
        );
        
        if (success) {
          _showMessage(
            'Recordatorio diario activado para las ${_reminderTime.format(context)}',
            isError: false,
          );
          setState(() {
            _isReminderEnabled = true;
          });
        } else {
          _showMessage('No se pudo activar el recordatorio', isError: true);
        }
      } else {
        // Cancelar recordatorio
        await _notificationService.cancelDailyReminder();
        _showMessage('Recordatorio diario desactivado');
        setState(() {
          _isReminderEnabled = false;
        });
      }
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _selectTime() async {
    if (!_isReminderEnabled) return;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        bool success = await _notificationService.scheduleDailyReminder(
          hour: picked.hour,
          minute: picked.minute,
        );
        
        if (success) {
          setState(() {
            _reminderTime = picked;
          });
          _showMessage(
            'Hora actualizada a las ${picked.format(context)}',
            isError: false,
          );
        } else {
          _showMessage('No se pudo actualizar la hora', isError: true);
        }
      } catch (e) {
        _showMessage('Error al actualizar hora: $e', isError: true);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
              'Recordatorio Diario',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    children: [
                      // Switch para activar/desactivar
                      SwitchListTile(
                        title: const Text('Activar recordatorio diario'),
                        subtitle: Text(
                          _isReminderEnabled
                              ? 'Recibirás una notificación a las ${_reminderTime.format(context)}'
                              : 'No recibirás recordatorios diarios',
                        ),
                        value: _isReminderEnabled,
                        onChanged: _toggleReminder,
                        contentPadding: EdgeInsets.zero,
                      ),
                      
                      // Selector de hora
                      if (_isReminderEnabled) ...[
                        const Divider(),
                        ListTile(
                          title: const Text('Hora del recordatorio'),
                          subtitle: Text(_reminderTime.format(context)),
                          leading: const Icon(Icons.access_time),
                          trailing: const Icon(Icons.edit, size: 20),
                          contentPadding: EdgeInsets.zero,
                          onTap: _selectTime,
                        ),
                      ],
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}