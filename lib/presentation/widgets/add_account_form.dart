import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/models/account.dart';
import 'package:chanchi_app/models/currency_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddAccountForm extends StatefulWidget {
  final String userId;
  final Account? account;
  final bool isEditing;

  const AddAccountForm({
    Key? key,
    required this.userId,
    this.account,
    this.isEditing = false,
  }) : super(key: key);

  @override
  _AddAccountFormState createState() => _AddAccountFormState();
}

class _AddAccountFormState extends State<AddAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();

  String _selectedType = 'Débito';
  String _selectedIcon = 'account_balance_wallet';
  String _selectedColor = '#4A6FFF';

  String _selectedCurrency = 'PEN';

  final List<String> _currencyOptions = ['PEN', 'USD', 'EUR'];

  // Lista de opciones
  final List<String> _accountTypes = [
    'Débito',
    'Crédito',
    'Efectivo',
    'Ahorros',
    'Inversión',
    'Otro',
  ];

  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'account_balance_wallet', 'icon': Icons.account_balance_wallet},
    {'name': 'credit_card', 'icon': Icons.credit_card},
    {'name': 'savings', 'icon': Icons.savings},
    {'name': 'account_balance', 'icon': Icons.account_balance},
    {'name': 'wallet', 'icon': Icons.wallet},
  ];

  final List<String> _colorOptions = [
    '#4A6FFF',
    '#6C63FF',
    '#00C6FF',
    '#FF7F50',
    '#2ED573',
    '#FF4757',
    '#FFBE21',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.isEditing && widget.account != null) {
      _nameController.text = widget.account!.name;
      _institutionController.text = widget.account!.institution;
      _balanceController.text = widget.account!.balance.toString();
      _selectedType = widget.account!.type;
      _selectedIcon = widget.account!.iconName ?? 'account_balance_wallet';
      _selectedColor = widget.account!.color ?? '#4A6FFF';
      _selectedCurrency = widget.account!.currencyCode ?? 'PEN';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppTheme.spacingL,
        right: AppTheme.spacingL,
        top: AppTheme.spacingL,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isEditing ? "Editar Cuenta" : "Nueva Cuenta",
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingL),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nombre de la cuenta",
                  hintText: "Ej: Cuenta Sueldo BCP",
                  prefixIcon: Icon(Icons.account_circle),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un nombre';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppTheme.spacingM),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Tipo de cuenta",
                  prefixIcon: Icon(Icons.category),
                ),
                value: _selectedType,
                items:
                    _accountTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  }
                },
              ),

              const SizedBox(height: AppTheme.spacingM),

              TextFormField(
                controller: _institutionController,
                decoration: const InputDecoration(
                  labelText: "Institución financiera",
                  hintText: "Ej: BCP, Interbank, Efectivo",
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una institución';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppTheme.spacingM),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Moneda',
                  prefixText:
                      CurrencyUtil
                          .currencies[_selectedCurrency ?? 'PEN']!
                          .symbol,
                ),
                value: _selectedCurrency ?? 'PEN',
                items:
                    _currencyOptions.map((String currency) {
                      return DropdownMenuItem<String>(
                        value: currency,
                        child: Text(CurrencyUtil.currencies[currency]!.name),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCurrency = newValue;
                    });
                  }
                },
              ),

              const SizedBox(height: AppTheme.spacingM),

              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: "Balance actual",
                  hintText: "0.00",
                  prefixText:
                      CurrencyUtil.currencies[_selectedCurrency]!.symbol,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un balance';
                  }
                  try {
                    double.parse(value);
                  } catch (e) {
                    return 'Por favor ingresa un número válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppTheme.spacingL),

              // Selector de íconos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Ícono:", style: Theme.of(context).textTheme.titleSmall),
                  Row(
                    children:
                        _iconOptions.map((option) {
                          return IconButton(
                            icon: Icon(option['icon']),
                            color:
                                _selectedIcon == option['name']
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondaryColor,
                            onPressed: () {
                              setState(() {
                                _selectedIcon = option['name'];
                              });
                            },
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  _selectedIcon == option['name']
                                      ? AppTheme.primaryColor.withOpacity(0.1)
                                      : Colors.transparent,
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingM),

              // Selector de colores
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Color:", style: Theme.of(context).textTheme.titleSmall),
                  Row(
                    children:
                        _colorOptions.map((colorHex) {
                          final color = Color(
                            int.parse(colorHex.substring(1, 7), radix: 16) +
                                0xFF000000,
                          );
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedColor = colorHex;
                              });
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      _selectedColor == colorHex
                                          ? Colors.white
                                          : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow:
                                    _selectedColor == colorHex
                                        ? [
                                          BoxShadow(
                                            color: color.withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                        : null,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingXL),

              // Botones de acción
              Row(
                children: [
                  if (widget.isEditing)
                    IconButton(
                      onPressed: _deleteAccount,
                      icon: const Icon(Icons.delete),
                      color: AppTheme.errorColor,
                      tooltip: "Eliminar cuenta",
                    ),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Cancelar"),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveAccount,
                      child: Text(widget.isEditing ? "Actualizar" : "Guardar"),
                    ),
                  ),
                ],
              ),
              // Espacio adicional para pantallas pequeñas
              const SizedBox(height: AppTheme.spacingM),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAccount() async {
    if (_formKey.currentState?.validate() ?? false) {
      final account = Account(
        id: widget.isEditing ? widget.account!.id : '',
        name: _nameController.text,
        type: _selectedType,
        institution: _institutionController.text,
        balance: double.tryParse(_balanceController.text) ?? 0.0,
        iconName: _selectedIcon,
        color: _selectedColor,
        currencyCode: _selectedCurrency,
      );

      try {
        if (widget.isEditing) {
          await _firestore
              .collection('users')
              .doc(widget.userId)
              .collection('accounts')
              .doc(account.id)
              .update(account.toMap());
        } else {
          await _firestore
              .collection('users')
              .doc(widget.userId)
              .collection('accounts')
              .add(account.toMap());
        }
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _deleteAccount() async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Eliminar Cuenta"),
                content: const Text(
                  "¿Estás seguro de que deseas eliminar esta cuenta? Esta acción no se puede deshacer y se eliminarán todas las transacciones asociadas.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Cancelar"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      "Eliminar",
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (shouldDelete) {
      try {
        await _firestore
            .collection('users')
            .doc(widget.userId)
            .collection('accounts')
            .doc(widget.account!.id)
            .delete();
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al eliminar: ${e.toString()}"),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
