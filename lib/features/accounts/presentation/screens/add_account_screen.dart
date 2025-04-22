import 'package:chanchi_app/core/utils/icon_utils.dart';
import 'package:chanchi_app/features/accounts/presentation/screens/account_transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/features/accounts/domain/services/account_service.dart';

class AddAccountScreen extends StatefulWidget {
  final String userId;
  final Account? account;
  final bool isEditing;
  final String? initialAccountType;

  const AddAccountScreen({
    Key? key,
    required this.userId,
    this.account,
    this.isEditing = false,
    this.initialAccountType,
  }) : super(key: key);

  @override
  _AddAccountScreenState createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final AccountService _accountService = AccountService();
  final _nameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _balanceController = TextEditingController();
  final _creditLimitController = TextEditingController();

  // Día del cierre de facturación para tarjetas de crédito
  final _billingDayController = TextEditingController();

  String _selectedType = 'cash';
  String _selectedIconName = 'account_balance_wallet';
  String _selectedColor = '#4A6FFF';
  bool _isSaving = false;
  bool _isCreditCard = false;
  bool _includeInTotalBalance = true;

  @override
  void initState() {
    super.initState();

    // Si se proporciona un tipo inicial, usarlo
    if (widget.initialAccountType != null) {
      _selectedType = widget.initialAccountType!;
      _isCreditCard = widget.initialAccountType == 'credit_card';

      // Actualizar icono automáticamente según el tipo
      if (_selectedType == 'credit_card') {
        _selectedIconName = 'credit_card';
      } else if (_selectedType == 'savings') {
        _selectedIconName = 'savings';
      } else if (_selectedType == 'checking') {
        _selectedIconName = 'account_balance';
      }
    }

    if (widget.account != null) {
      // Cargar datos de la cuenta existente
      _nameController.text = widget.account!.name;
      _institutionController.text = widget.account!.institution;
      _balanceController.text = widget.account!.balance.toString();
      _selectedType = widget.account!.type;
      _selectedIconName = widget.account!.iconName ?? 'account_balance_wallet';
      _selectedColor = widget.account!.color ?? '#4A6FFF';

      // Verificar si es tarjeta de crédito
      _isCreditCard = _selectedType == 'credit_card';

      // Cargar límite de crédito si existe
      if (widget.account!.creditLimit != null) {
        _creditLimitController.text = widget.account!.creditLimit.toString();
      }

      // Cargar día de cierre si existe
      if (widget.account!.billingCycleEndDate != null) {
        _billingDayController.text =
            widget.account!.billingCycleEndDate!.day.toString();
      }

      // Valores booleanos adicionales si están disponibles
      if (widget.account!.toMap().containsKey('includeInTotalBalance')) {
        _includeInTotalBalance =
            widget.account!.toMap()['includeInTotalBalance'] ?? true;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _balanceController.dispose();
    _creditLimitController.dispose();
    _billingDayController.dispose();
    super.dispose();
  }

  Map<String, String> getAccountTypes() {
    return {
      'cash': 'Efectivo',
      'checking': 'Cuenta Corriente',
      'savings': 'Cuenta de Ahorros',
      'credit_card': 'Tarjeta de Crédito',
      'investment': 'Inversión',
    };
  }

  Map<String, IconData> getAccountIcons() {
    return {
      for (var entry in [
        'account_balance_wallet',
        'credit_card',
        'savings',
        'account_balance',
        'attach_money',
        'trending_up',
      ])
        entry: IconUtils.getIconByName(entry),
    };
  }

  List<Map<String, dynamic>> getColorOptions() {
    return [
      {'name': 'Azul', 'value': '#4A6FFF'},
      {'name': 'Verde', 'value': '#4CAF50'},
      {'name': 'Rojo', 'value': '#F44336'},
      {'name': 'Naranja', 'value': '#FF9800'},
      {'name': 'Morado', 'value': '#9C27B0'},
      {'name': 'Turquesa', 'value': '#009688'},
    ];
  }

  Color getColorFromHex(String hexColor) {
    return Color(int.parse(hexColor.substring(1, 7), radix: 16) + 0xFF000000);
  }

  Future<void> _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final name = _nameController.text;
        final institution = _institutionController.text;
        final balance = double.tryParse(_balanceController.text) ?? 0.0;

        // Crear el mapa de la cuenta
        final accountMap = {
          'name': name,
          'type': _selectedType,
          'institution': institution,
          'balance': balance,
          'iconName': _selectedIconName,
          'color': _selectedColor,
          'isCreditCard': _isCreditCard,
          'includeInTotalBalance': _includeInTotalBalance,
          'currencyCode': 'PEN', // Por defecto
        };

        // Añadir campos adicionales para tarjetas de crédito
        if (_isCreditCard) {
          double? creditLimit = double.tryParse(_creditLimitController.text);
          if (creditLimit != null && creditLimit > 0) {
            accountMap['creditLimit'] = creditLimit;
          }

          int? billingDay = int.tryParse(_billingDayController.text);
          if (billingDay != null && billingDay >= 1 && billingDay <= 31) {
            // Crear una fecha para el día de cierre (usamos el mes actual)
            final now = DateTime.now();
            final billingDate = DateTime(now.year, now.month, billingDay);
            accountMap['billingCycleEndDate'] = billingDate;
          }
        }

        if (widget.account == null) {
          // Crear nueva cuenta
          await _accountService.addAccount(
            widget.userId,
            Account.fromMap(accountMap, ''),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Cuenta creada con éxito"),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Actualizar cuenta existente
          String accountId = widget.account!.id;
          if (accountId.contains('/')) {
            final parts = accountId.split('/');
            accountId = parts[1];
          }

          await _accountService.updateAccount(
            widget.userId,
            Account.fromMap(accountMap, accountId),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Cuenta actualizada con éxito"),
                backgroundColor: Colors.green,
              ),
            );
          }
        }

        // Cerrar la pantalla
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        print('Error al guardar cuenta: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account == null ? 'Nueva Cuenta' : 'Editar Cuenta'),
        backgroundColor: getColorFromHex(_selectedColor),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions:
            widget.account != null
                ? [
                  // Botón de historial de transacciones
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => AccountTransactionsScreen(
                                userId: widget.userId,
                                account: widget.account!,
                                onEditTransaction: (transaction, id) {},
                              ),
                        ),
                      );
                    },
                    tooltip: 'Ver historial',
                  ),
                  // Botón de eliminar cuenta
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      // Mostrar diálogo de confirmación de eliminación
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Eliminar Cuenta'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '¿Estás seguro de que quieres eliminar esta cuenta?',
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Esta acción eliminará permanentemente la cuenta y todas sus transacciones.',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    // Llamar al método de eliminación de cuenta
                                    _deleteAccount();
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                      );
                    },
                    tooltip: 'Eliminar cuenta',
                  ),
                ]
                : null,
      ),
      body:
          _isSaving
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Cabecera coloreada
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      color: getColorFromHex(_selectedColor),
                      child: _buildAccountTypeSelector(context),
                    ),

                    // Formulario principal
                    Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nombre de la cuenta
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Nombre de la cuenta',
                                prefixIcon: Icon(
                                  IconUtils.getIconByName(
                                    _selectedIconName,
                                    fallbackType: _selectedType,
                                  ),
                                  color: getColorFromHex(_selectedColor),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: getColorFromHex(_selectedColor),
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa un nombre';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Institución
                            TextFormField(
                              controller: _institutionController,
                              decoration: InputDecoration(
                                labelText: 'Institución (Banco, etc.)',
                                prefixIcon: const Icon(Icons.business),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: getColorFromHex(_selectedColor),
                                    width: 2.0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Saldo
                            TextFormField(
                              controller: _balanceController,
                              decoration: InputDecoration(
                                labelText:
                                    _isCreditCard
                                        ? 'Saldo actual (utilizado)'
                                        : 'Saldo actual',
                                prefixIcon: const Icon(Icons.monetization_on),
                                helperText:
                                    _isCreditCard
                                        ? 'Para tarjetas de crédito, ingresa el monto utilizado (deuda)'
                                        : 'Ingresa el saldo actual de la cuenta',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: getColorFromHex(_selectedColor),
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa un valor';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Ingresa un número válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Mostrar campos adicionales para tarjetas de crédito
                            if (_isCreditCard) ...[
                              // Límite de crédito
                              TextFormField(
                                controller: _creditLimitController,
                                decoration: InputDecoration(
                                  labelText: 'Límite de crédito',
                                  prefixIcon: const Icon(Icons.credit_score),
                                  helperText:
                                      'Ingresa el límite máximo de tu tarjeta',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: getColorFromHex(_selectedColor),
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final limit = double.tryParse(value);
                                    if (limit == null) {
                                      return 'Ingresa un número válido';
                                    }
                                    if (limit <= 0) {
                                      return 'El límite debe ser mayor a 0';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Día de cierre
                              TextFormField(
                                controller: _billingDayController,
                                decoration: InputDecoration(
                                  labelText: 'Día de cierre de facturación',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  helperText:
                                      'Ingresa el día del mes en que cierra tu ciclo de facturación',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: getColorFromHex(_selectedColor),
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final day = int.tryParse(value);
                                    if (day == null) {
                                      return 'Ingresa un número válido';
                                    }
                                    if (day < 1 || day > 31) {
                                      return 'El día debe estar entre 1 y 31';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Selección de color
                            _buildColorSelector(),
                            const SizedBox(height: 20),

                            // Opciones adicionales (switch)
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SwitchListTile(
                                  title: const Text('Incluir en balance total'),
                                  subtitle: const Text(
                                    'Determina si esta cuenta se suma al balance total de tus finanzas',
                                  ),
                                  value: _includeInTotalBalance,
                                  activeColor: getColorFromHex(_selectedColor),
                                  onChanged: (value) {
                                    setState(() {
                                      _includeInTotalBalance = value;
                                    });
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Botón de guardar
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _saveAccount,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: getColorFromHex(
                                    _selectedColor,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  widget.account == null
                                      ? 'Crear Cuenta'
                                      : 'Guardar Cambios',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // Método para eliminar la cuenta
  Future<void> _deleteAccount() async {
    try {
      // Extraer el ID de la cuenta correctamente
      String accountId = widget.account!.id;
      if (accountId.contains('/')) {
        final parts = accountId.split('/');
        accountId = parts[1];
      }

      // Llamar al servicio para eliminar la cuenta
      await _accountService.deleteAccount(widget.userId, accountId);

      // Navegar de vuelta y mostrar mensaje de éxito
      if (mounted) {
        Navigator.of(context).pop(); // Volver a la pantalla anterior
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cuenta eliminada con éxito"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error al eliminar cuenta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al eliminar cuenta: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAccountTypeSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Tipo de Cuenta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children:
                  getAccountTypes().entries.map((entry) {
                    final isSelected = _selectedType == entry.key;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = entry.key;
                            _isCreditCard = entry.key == 'credit_card';

                            // Actualizar icono automáticamente según el tipo
                            if (entry.key == 'cash') {
                              _selectedIconName = 'account_balance_wallet';
                            } else if (entry.key == 'checking') {
                              _selectedIconName = 'account_balance';
                            } else if (entry.key == 'savings') {
                              _selectedIconName = 'savings';
                            } else if (entry.key == 'credit_card') {
                              _selectedIconName = 'credit_card';
                            } else if (entry.key == 'investment') {
                              _selectedIconName = 'trending_up';
                            }
                          });
                        },
                        child: Container(
                          width: 110,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                // Use IconUtils to get the icon
                                IconUtils.getIconByName(
                                  entry
                                      .key, // Use the account type or icon name
                                  fallbackType: 'account', // Provide a fallback
                                ),
                                color: Colors.white,
                                size: 30,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  getColorOptions()
                      .map(
                        (color) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color['value'];
                              });
                            },
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: getColorFromHex(color['value']),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      _selectedColor == color['value']
                                          ? Colors.white
                                          : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow:
                                    _selectedColor == color['value']
                                        ? [
                                          BoxShadow(
                                            color: getColorFromHex(
                                              color['value'],
                                            ).withOpacity(0.6),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                        : [],
                              ),
                              child:
                                  _selectedColor == color['value']
                                      ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 24,
                                      )
                                      : null,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
