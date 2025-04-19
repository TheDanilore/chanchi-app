import 'package:flutter/material.dart';

class CalculatorDialog extends StatefulWidget {
  final double? initialValue;
  final Function(double) onResult;

  const CalculatorDialog({
    Key? key,
    this.initialValue,
    required this.onResult,
  }) : super(key: key);

  @override
  _CalculatorDialogState createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _displayValue = "0";
  String _previousValue = "";
  String _operation = "";
  bool _shouldResetDisplay = true;
  bool _hasDecimalPoint = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue! > 0) {
      _displayValue = widget.initialValue.toString();
      // Eliminar '.0' al final si el valor es entero
      if (_displayValue.endsWith('.0')) {
        _displayValue = _displayValue.substring(0, _displayValue.length - 2);
      }
      _hasDecimalPoint = _displayValue.contains('.');
    }
  }

  void _addDigit(String digit) {
    setState(() {
      if (_shouldResetDisplay) {
        _displayValue = digit;
        _shouldResetDisplay = false;
        _hasDecimalPoint = false;
      } else {
        // Evitar múltiples ceros al inicio
        if (_displayValue == "0" && digit != ".") {
          _displayValue = digit;
        } else {
          _displayValue += digit;
        }
      }
    });
  }

  void _addDecimalPoint() {
    setState(() {
      if (_shouldResetDisplay) {
        _displayValue = "0.";
        _shouldResetDisplay = false;
        _hasDecimalPoint = true;
      } else if (!_hasDecimalPoint) {
        _displayValue += ".";
        _hasDecimalPoint = true;
      }
    });
  }

  void _clear() {
    setState(() {
      _displayValue = "0";
      _previousValue = "";
      _operation = "";
      _shouldResetDisplay = true;
      _hasDecimalPoint = false;
    });
  }

  void _delete() {
    setState(() {
      if (_displayValue.length > 1) {
        // Verificar si estamos eliminando un punto decimal
        if (_displayValue[_displayValue.length - 1] == '.') {
          _hasDecimalPoint = false;
        }
        _displayValue = _displayValue.substring(0, _displayValue.length - 1);
      } else {
        _displayValue = "0";
        _shouldResetDisplay = true;
      }
    });
  }

  void _setOperation(String operation) {
    if (_previousValue.isNotEmpty) {
      _calculateResult();
    }
    
    setState(() {
      _previousValue = _displayValue;
      _operation = operation;
      _shouldResetDisplay = true;
    });
  }

  void _calculateResult() {
    if (_previousValue.isEmpty || _operation.isEmpty) return;

    double prev = double.parse(_previousValue);
    double current = double.parse(_displayValue);
    double result = 0;

    switch (_operation) {
      case "+":
        result = prev + current;
        break;
      case "-":
        result = prev - current;
        break;
      case "×":
        result = prev * current;
        break;
      case "÷":
        if (current != 0) {
          result = prev / current;
        } else {
          // División por cero
          setState(() {
            _displayValue = "Error";
            _previousValue = "";
            _operation = "";
            _shouldResetDisplay = true;
          });
          return;
        }
        break;
    }

    setState(() {
      // Formatear resultado para evitar decimales innecesarios
      if (result == result.toInt().toDouble()) {
        _displayValue = result.toInt().toString();
      } else {
        // Limitar a 6 decimales para evitar números muy largos
        _displayValue = result.toStringAsFixed(6);
        // Eliminar ceros al final
        while (_displayValue.contains('.') && _displayValue.endsWith('0')) {
          _displayValue = _displayValue.substring(0, _displayValue.length - 1);
        }
        // Eliminar punto decimal si quedó solo
        if (_displayValue.endsWith('.')) {
          _displayValue = _displayValue.substring(0, _displayValue.length - 1);
        }
      }

      _previousValue = "";
      _operation = "";
      _shouldResetDisplay = true;
      _hasDecimalPoint = _displayValue.contains('.');
    });
  }

  Widget _buildButton(String text, {Color? color, VoidCallback? onPressed, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            backgroundColor: color ?? Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 24.0,
              color: color != null ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Calculadora"),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(bottom: 20.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _displayValue,
                style: const TextStyle(fontSize: 32.0),
                textAlign: TextAlign.end,
              ),
            ),
            // Buttons
            Row(
              children: [
                _buildButton("C", color: Colors.red[400], onPressed: _clear),
                _buildButton("⌫", onPressed: _delete),
                _buildButton("÷", color: Colors.blue[700], onPressed: () => _setOperation("÷")),
              ],
            ),
            Row(
              children: [
                _buildButton("7", onPressed: () => _addDigit("7")),
                _buildButton("8", onPressed: () => _addDigit("8")),
                _buildButton("9", onPressed: () => _addDigit("9")),
                _buildButton("×", color: Colors.blue[700], onPressed: () => _setOperation("×")),
              ],
            ),
            Row(
              children: [
                _buildButton("4", onPressed: () => _addDigit("4")),
                _buildButton("5", onPressed: () => _addDigit("5")),
                _buildButton("6", onPressed: () => _addDigit("6")),
                _buildButton("-", color: Colors.blue[700], onPressed: () => _setOperation("-")),
              ],
            ),
            Row(
              children: [
                _buildButton("1", onPressed: () => _addDigit("1")),
                _buildButton("2", onPressed: () => _addDigit("2")),
                _buildButton("3", onPressed: () => _addDigit("3")),
                _buildButton("+", color: Colors.blue[700], onPressed: () => _setOperation("+")),
              ],
            ),
            Row(
              children: [
                _buildButton("0", flex: 2, onPressed: () => _addDigit("0")),
                _buildButton(".", onPressed: _addDecimalPoint),
                _buildButton("=", color: Colors.green[700], onPressed: _calculateResult),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: () {
            try {
              final result = double.parse(_displayValue);
              widget.onResult(result);
              Navigator.of(context).pop();
            } catch (e) {
              // Si hay un error, no hacer nada
            }
          },
          child: const Text("Confirmar"),
        ),
      ],
    );
  }
}