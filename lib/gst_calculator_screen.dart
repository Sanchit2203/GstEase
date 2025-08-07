import 'package:flutter/material.dart';
import 'dart:math'; // For precision

class GstCalculatorScreen extends StatefulWidget {
  const GstCalculatorScreen({super.key});

  @override
  State<GstCalculatorScreen> createState() => _GstCalculatorScreenState();
}

class _GstCalculatorScreenState extends State<GstCalculatorScreen> {
  String _displayValue = "0"; // Main display for numbers and results
  double? _firstOperand;
  String? _operator;
  bool _waitingForSecondOperand = false;

  double _gstRate = 0.05; // Default GST rate
  double _gstAmount = 0.0;
  double _totalAmount = 0.0;

  // Added 0% and sorted for consistent display order
  final List<double> _gstSlabs = [0.0, 0.05, 0.12, 0.18, 0.28];

  // Helper for precision
  double _roundDouble(double value, int places) {
    num mod = pow(10, places); // Fixed: Changed 10.com to 10
    return ((value * mod).round().toDouble() / mod);
  }

  void _calculateGst() {
    final amount = double.tryParse(_displayValue) ?? 0;
    setState(() {
      _gstAmount = _roundDouble(amount * _gstRate, 2);
      _totalAmount = _roundDouble(amount + _gstAmount, 2);
    });
  }

  void _handleDigitInput(String digit) {
    setState(() {
      if (_waitingForSecondOperand) {
        _displayValue = digit;
        _waitingForSecondOperand = false;
      } else {
        if (_displayValue == "0" && digit != ".") {
          _displayValue = digit;
        } else if (digit == "." && _displayValue.contains(".")) {
          return; // Avoid multiple decimal points
        } else {
          _displayValue += digit;
        }
      }
      _calculateGst(); // Update GST as numbers are typed or after an operation reset display
    });
  }

  void _handleOperator(String selectedOperator) {
    setState(() {
      final inputValue = double.tryParse(_displayValue) ?? 0;

      if (_firstOperand == null && !_waitingForSecondOperand) {
        _firstOperand = inputValue;
      } else if (_operator != null && !_waitingForSecondOperand) {
        // Perform previous calculation if an operator is already pending and we have a second operand
        final result = _performCalculation(_firstOperand!, _operator!, inputValue);
        _displayValue = result.toStringAsFixed(2); // Show result
        _firstOperand = result; // Use result as the new first operand
        _calculateGst(); // Update GST based on new result
      } else if (_firstOperand != null && _waitingForSecondOperand) {
         // User is changing operator before entering second number
        _operator = selectedOperator;
        return;
      }
      
      _operator = selectedOperator;
      _waitingForSecondOperand = true;
    });
  }

  double _performCalculation(double operand1, String operator, double operand2) {
    switch (operator) {
      case '+':
        return operand1 + operand2;
      case '-':
        return operand1 - operand2;
      case '*':
        return operand1 * operand2;
      case '/':
        if (operand2 == 0) return 0.0; // Avoid division by zero
        return operand1 / operand2;
      default:
        return operand2; // Should not happen
    }
  }

  void _handleEquals() {
    setState(() {
      if (_operator != null && _firstOperand != null && !_waitingForSecondOperand) {
        final inputValue = double.tryParse(_displayValue) ?? 0;
        final result = _performCalculation(_firstOperand!, _operator!, inputValue);
        _displayValue = _roundDouble(result, 4).toString(); // Using 4 for intermediate precision
         // Format if it's a whole number
        if (result % 1 == 0) {
            _displayValue = result.toInt().toString();
        } else {
            _displayValue = _roundDouble(result, 2).toString();
        }


        _firstOperand = null; // Reset for next calculation chain
        _operator = null;
        _waitingForSecondOperand = false;
        _calculateGst(); // Final GST calculation on the result
      }
    });
  }

  void _handleClear() {
    setState(() {
      _displayValue = "0";
      _firstOperand = null;
      _operator = null;
      _waitingForSecondOperand = false;
      _calculateGst(); // Recalculate with 0
    });
  }

  void _handleBackspace() {
    setState(() {
      if (_waitingForSecondOperand) { // If waiting for B, pressing backspace should not alter A or Op
        return;
      }
      if (_displayValue.length > 1) {
        _displayValue = _displayValue.substring(0, _displayValue.length - 1);
      } else {
        _displayValue = "0";
      }
      // If we are not in the middle of an operation, update GST
      if (_operator == null || _waitingForSecondOperand) {
         _calculateGst();
      } else {
        // If we are entering the second operand, the GST is based on the first operand until '='
        // Or, we can choose to update GST live based on the current _displayValue always.
        // For simplicity, let's always update.
         _calculateGst();
      }
    });
  }

  void _handleSlabSelection(double newRate) {
    setState(() {
      _gstRate = newRate;
      _calculateGst();
    });
  }

  Widget _buildButton(String text, {VoidCallback? onPressed, Color? color, Color? textColor, int flex = 1}) {
    VoidCallback? effectiveOnPressed = onPressed;
    if (onPressed == null) {
      if (['+', '-', '*', '/'].contains(text)) {
        effectiveOnPressed = () => _handleOperator(text);
      } else if (text == "=") {
        effectiveOnPressed = _handleEquals;
      } else {
        effectiveOnPressed = () => _handleDigitInput(text);
      }
    }

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Theme.of(context).colorScheme.surfaceContainerHighest, // Fixed: Used surfaceContainerHighest
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            textStyle: TextStyle(fontSize: 20, color: textColor),
          ),
          onPressed: effectiveOnPressed,
          child: Text(text, style: TextStyle(color: textColor ?? Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GST Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Display Area
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
              alignment: Alignment.centerRight,
              child: Text(
                _displayValue,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),

            // GST Slab Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _gstSlabs.map((rate) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gstRate == rate ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondaryContainer,
                        foregroundColor: _gstRate == rate ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      onPressed: () => _handleSlabSelection(rate),
                      child: Text('${(rate * 100).toStringAsFixed(0)}%'),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Number Pad & Operators
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: <Widget>[
                      _buildButton("7"),
                      _buildButton("8"),
                      _buildButton("9"),
                      _buildButton("/", color: Colors.blueGrey, textColor: Colors.white),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      _buildButton("4"),
                      _buildButton("5"),
                      _buildButton("6"),
                      _buildButton("*", color: Colors.blueGrey, textColor: Colors.white),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      _buildButton("1"),
                      _buildButton("2"),
                      _buildButton("3"),
                      _buildButton("-", color: Colors.blueGrey, textColor: Colors.white),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      _buildButton("0"),
                      _buildButton("."),
                      _buildButton("=", color: Colors.orangeAccent, textColor: Colors.white),
                      _buildButton("+", color: Colors.blueGrey, textColor: Colors.white),
                    ],
                  ),
                   Row(
                    children: <Widget>[
                      _buildButton("C", onPressed: _handleClear, color: Colors.redAccent, textColor: Colors.white, flex: 2),
                      _buildButton("Del", onPressed: _handleBackspace, color: Colors.redAccent, textColor: Colors.white, flex: 2),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            // Results
            Text(
              'GST Amount: ${_gstAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Total Amount: ${_totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
