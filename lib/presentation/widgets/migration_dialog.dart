import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chanchi_app/config/theme.dart';

class MigrationDialog extends StatefulWidget {
  final String userId;
  final VoidCallback? onComplete;

  const MigrationDialog({
    Key? key,
    required this.userId,
    this.onComplete,
  }) : super(key: key);

  @override
  _MigrationDialogState createState() => _MigrationDialogState();
}

class _MigrationDialogState extends State<MigrationDialog> {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  int _updatedCount = 0;
  String? _errorMessage;
  bool _migrationComplete = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_migrationComplete
          ? "Actualización Completada"
          : "Actualizar Base de Datos"),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 300, minHeight: 150),
        child: _isLoading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Actualizando transacciones..."),
                ],
              )
            : _migrationComplete
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Se actualizaron $_updatedCount transacciones correctamente.",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Esta herramienta actualizará tus transacciones existentes para que funcionen con las nuevas características de la aplicación.",
                        textAlign: TextAlign.center,
                      ),
                      if (_errorMessage != null) ...[
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
      actions: _migrationComplete
          ? [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (widget.onComplete != null) {
                    widget.onComplete!();
                  }
                },
                child: Text("Cerrar"),
              ),
            ]
          : [
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                child: Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _migrateTransactions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: Text("Actualizar"),
              ),
            ],
    );
  }

  Future<void> _migrateTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obtener todas las transacciones del usuario
      final QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: widget.userId)
          .get();

      // Usar WriteBatch para actualizar múltiples documentos eficientemente
      WriteBatch batch = _firestore.batch();
      int totalUpdated = 0;
      int batchSize = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Actualizar solo si no tiene los campos necesarios
        if (!data.containsKey('isInTrash')) {
          batch.update(doc.reference, {'isInTrash': false});
          batchSize++;
          totalUpdated++;
        }

        // Firestore tiene un límite de 500 operaciones por lote
        if (batchSize >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          batchSize = 0;
        }
      }

      // Commit final para cualquier documento restante
      if (batchSize > 0) {
        await batch.commit();
      }

      setState(() {
        _isLoading = false;
        _migrationComplete = true;
        _updatedCount = totalUpdated;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error durante la migración: $e";
      });
    }
  }
}