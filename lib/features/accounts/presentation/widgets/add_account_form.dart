import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/core/utils/currency_util.dart';
import 'package:chanchi_app/features/accounts/domain/services/account_service.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:flutter/material.dart';

class AddAccountForm extends StatefulWidget {
  final String userId;
  final Account? account;
  final bool isEditing;
  final String? initialAccountType;

  const AddAccountForm({
    super.key,
    required this.userId,
    this.account,
    required this.isEditing,
    this.initialAccountType,
  });

  @override
  State<AddAccountForm> createState() => _AddAccountFormState();
}

class _AddAccountFormState extends State<AddAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final AccountService _accountService = AccountService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _creditLimitController = TextEditingController();

  String _selectedAccountType = 'checking';
  String _selectedIcon = 'wallet';
  Color _selectedColor = Colors.blue;
  String _selectedCurrency = 'PEN';
  bool _isCreditCard = false;
  bool _includeInTotalBalance = true;
  DateTime? _billingCycleEndDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      // Inicializar con datos de la cuenta existente
      _nameController.text = widget.account!.name;
      _institutionController.text = widget.account!.institution;
      _balanceController.text = widget.account!.balance.toString();

      // Mapear los tipos antiguos a los nuevos
      Map<String, String> typeMapping = {
        'Efectivo': 'cash',
        'Cuenta Corriente': 'checking',
        'Cuenta de Ahorros': 'savings',
        'Tarjeta de Crédito': 'credit_card',
        'Inversión': 'investment',
      };

      // Verificar y normalizar el tipo de cuenta
      _selectedAccountType =
          typeMapping[widget.account!.type] ??
          (widget.account!.type == 'cash' ||
                  widget.account!.type == 'checking' ||
                  widget.account!.type == 'savings' ||
                  widget.account!.type == 'credit_card' ||
                  widget.account!.type == 'investment' ||
                  widget.account!.type == 'other'
              ? widget.account!.type
              : 'other');

      _selectedIcon = widget.account!.iconName ?? 'wallet';
      _selectedColor =
          widget.account!.color != null
              ? Color(
                int.parse(widget.account!.color!.substring(1, 7), radix: 16) +
                    0xFF000000,
              )
              : Colors.blue;
      _selectedCurrency = widget.account!.currencyCode ?? 'PEN';
      _isCreditCard =
          widget.account!.isCreditCard || widget.account!.type == 'credit_card';
      _includeInTotalBalance = widget.account!.includeInTotalBalance;
      _billingCycleEndDate = widget.account!.billingCycleEndDate;

      if (_isCreditCard && widget.account!.creditLimit != null) {
        _creditLimitController.text = widget.account!.creditLimit.toString();
      }
    } else if (widget.initialAccountType != null) {
      // Si se especifica un tipo inicial
      _selectedAccountType = widget.initialAccountType!;
      _isCreditCard = widget.initialAccountType == 'credit_card';

      // Para tarjetas de crédito, inicializar con iconos y colores apropiados
      if (_isCreditCard) {
        _selectedIcon = 'credit_card';
        _selectedColor = Colors.deepPurple[800]!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              widget.isEditing ? "Editar Cuenta" : "Nueva Cuenta",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Tipo de cuenta
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de Cuenta',
                prefixIcon: Icon(Icons.account_balance),
              ),
              value: _selectedAccountType,
              items: const [
                DropdownMenuItem(
                  value: 'checking',
                  child: Text('Cuenta Corriente'),
                ),
                DropdownMenuItem(
                  value: 'savings',
                  child: Text('Cuenta de Ahorros'),
                ),
                DropdownMenuItem(
                  value: 'credit_card',
                  child: Text('Tarjeta de Crédito'),
                ),
                DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
                DropdownMenuItem(value: 'investment', child: Text('Inversión')),
                DropdownMenuItem(value: 'other', child: Text('Otro')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedAccountType = value;
                    _isCreditCard = value == 'credit_card';
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Nombre de la cuenta
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Cuenta',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un nombre';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Institución
            TextFormField(
              controller: _institutionController,
              decoration: const InputDecoration(
                labelText: 'Institución',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa una institución';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Balance inicial / monto utilizado
            TextFormField(
              controller: _balanceController,
              decoration: InputDecoration(
                labelText:
                    _isCreditCard ? 'Monto Utilizado' : 'Balance Inicial',
                prefixIcon: Icon(Icons.account_balance_wallet),
                prefixText: CurrencyUtil.currencies[_selectedCurrency]!.symbol,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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

            // Opciones específicas para tarjetas de crédito
            if (_isCreditCard) ...[
              const SizedBox(height: 16),

              // Límite de crédito
              TextFormField(
                controller: _creditLimitController,
                decoration: InputDecoration(
                  labelText: 'Límite de Crédito',
                  prefixIcon: Icon(Icons.credit_card),
                  prefixText:
                      CurrencyUtil.currencies[_selectedCurrency]!.symbol,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el límite de crédito';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Fecha de cierre de ciclo
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Fecha de Cierre de Ciclo'),
                subtitle: Text(
                  _billingCycleEndDate != null
                      ? 'Día ${_billingCycleEndDate!.day} de cada mes'
                      : 'No especificado',
                ),
                trailing: Icon(Icons.edit),
                onTap: () async {
                  // Mostrar un selector simple para el día del mes
                  final int? selectedDay = await showDialog<int>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Selecciona el día de cierre'),
                        content: Container(
                          width: double.maxFinite,
                          child: GridView.builder(
                            shrinkWrap: true,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  childAspectRatio: 1,
                                ),
                            itemCount: 31,
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap:
                                    () => Navigator.of(context).pop(index + 1),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        _billingCycleEndDate?.day == index + 1
                                            ? Theme.of(context).primaryColor
                                            : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color:
                                            _billingCycleEndDate?.day ==
                                                    index + 1
                                                ? Colors.white
                                                : null,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Cancelar'),
                          ),
                        ],
                      );
                    },
                  );

                  if (selectedDay != null) {
                    setState(() {
                      final now = DateTime.now();
                      _billingCycleEndDate = DateTime(
                        now.year,
                        now.month,
                        selectedDay <= DateTime(now.year, now.month + 1, 0).day
                            ? selectedDay
                            : DateTime(now.year, now.month + 1, 0).day,
                      );
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Incluir en balance total
              SwitchListTile(
                title: Text('Incluir en Balance Total'),
                subtitle: Text(
                  'Si está activado, los gastos en esta tarjeta se reflejarán en tu balance total',
                ),
                value: _includeInTotalBalance,
                onChanged: (value) {
                  setState(() {
                    _includeInTotalBalance = value;
                  });
                },
              ),
            ],

            const SizedBox(height: 16),

            // Selección de moneda
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Moneda',
                prefixIcon: Icon(Icons.attach_money),
              ),
              value: _selectedCurrency,
              items:
                  CurrencyUtil.currencies.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text('${entry.value.symbol} ${entry.value.name}'),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Selección de icono y color
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _selectedColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconData(_selectedIcon),
                    color: _selectedColor,
                    size: 28,
                  ),
                ),
                title: Text(
                  'Icono y Color',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text('Personaliza la apariencia de tu cuenta'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showIconColorSelector(context);
                },
              ),
            ),

            const SizedBox(height: 24),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Cancelar'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAccount,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child:
                        _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(widget.isEditing ? 'Actualizar' : 'Guardar'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final double balance = double.parse(_balanceController.text);
        double? creditLimit;

        if (_isCreditCard && _creditLimitController.text.isNotEmpty) {
          creditLimit = double.parse(_creditLimitController.text);
        }

        final account = Account(
          id: widget.account?.id ?? '',
          name: _nameController.text,
          type: _selectedAccountType,
          institution: _institutionController.text,
          balance: balance,
          iconName: _selectedIcon,
          color: '#${_selectedColor.value.toRadixString(16).substring(2)}',
          currencyCode: _selectedCurrency,
          isCreditCard: _isCreditCard,
          creditLimit: creditLimit,
          includeInTotalBalance: _includeInTotalBalance,
          billingCycleEndDate: _billingCycleEndDate,
        );

        if (widget.isEditing) {
          await _accountService.updateAccount(widget.userId, account);
        } else {
          await _accountService.addAccount(widget.userId, account);
        }

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isEditing
                    ? "Cuenta actualizada con éxito"
                    : "Cuenta creada con éxito",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Método para mostrar el selector de iconos y colores
  void _showIconColorSelector(BuildContext context) {
    // Lista de iconos disponibles
    final List<String> availableIcons = [
      'wallet',
      'credit_card',
      'savings',
      'account_balance',
      'money',
    ];

    // Lista de colores predefinidos
    final List<Color> availableColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.deepPurple,
      Colors.lightBlue,
      Colors.deepOrange,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Personaliza tu cuenta",
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Sección de iconos
                  Text(
                    "Selecciona un icono",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: availableIcons.length,
                    itemBuilder: (context, index) {
                      final iconName = availableIcons[index];
                      final isSelected = iconName == _selectedIcon;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIcon = iconName;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? _selectedColor.withOpacity(0.2) 
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: _selectedColor, width: 2)
                                : null,
                          ),
                          child: Icon(
                            _getIconData(iconName),
                            color: isSelected ? _selectedColor : Colors.grey[600],
                            size: 28,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sección de colores
                  Text(
                    "Selecciona un color",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      childAspectRatio: 1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: availableColors.length,
                    itemBuilder: (context, index) {
                      final color = availableColors[index];
                      final isSelected = color.value == _selectedColor.value;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                          
                          // También actualizar el estado del widget padre
                          this.setState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text("Confirmar"),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Método para obtener el IconData basado en el nombre del icono
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'credit_card':
        return Icons.credit_card;
      case 'savings':
        return Icons.savings;
      case 'account_balance':
        return Icons.account_balance;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'money':
        return Icons.attach_money;
      default:
        return Icons.account_balance_wallet;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _balanceController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }
}
