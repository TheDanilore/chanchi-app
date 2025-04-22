import 'package:flutter/material.dart';
import 'package:chanchi_app/core/utils/currency_util.dart';

class TransactionAmountField extends StatelessWidget {
  final TextEditingController amountController;
  final String? selectedCurrency;
  final VoidCallback? onCalculatorPressed;
  final String Function(String?)? validator;

  const TransactionAmountField({
    Key? key,
    required this.amountController,
    this.selectedCurrency,
    this.onCalculatorPressed,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: amountController,
      decoration: InputDecoration(
        labelText: 'Monto',
        prefixText: CurrencyUtil.currencies[selectedCurrency ?? 'PEN']!.symbol,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calculate_outlined),
          tooltip: 'Calculadora',
          onPressed: onCalculatorPressed,
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
    );
  }
}

class TransactionDescriptionField extends StatelessWidget {
  final TextEditingController descriptionController;

  const TransactionDescriptionField({
    Key? key,
    required this.descriptionController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: descriptionController,
      decoration: const InputDecoration(
        labelText: 'Descripción',
        prefixIcon: Icon(Icons.description),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresa una descripción';
        }
        return null;
      },
    );
  }
}

class TransactionNotesField extends StatelessWidget {
  final TextEditingController notesController;

  const TransactionNotesField({
    Key? key,
    required this.notesController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: notesController,
      decoration: const InputDecoration(
        labelText: 'Notas (opcional)',
        prefixIcon: Icon(Icons.note),
      ),
      maxLines: 3,
    );
  }
}

class CurrencyDropdown extends StatelessWidget {
  final String? selectedCurrency;
  final List<String> currencyOptions;
  final ValueChanged<String?> onChanged;

  const CurrencyDropdown({
    Key? key,
    required this.selectedCurrency,
    required this.currencyOptions,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Moneda',
        prefixText: CurrencyUtil.currencies[selectedCurrency ?? 'PEN']!.symbol,
      ),
      value: selectedCurrency ?? 'PEN',
      items: currencyOptions.map((String currency) {
        return DropdownMenuItem<String>(
          value: currency,
          child: Text(CurrencyUtil.currencies[currency]!.name),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}