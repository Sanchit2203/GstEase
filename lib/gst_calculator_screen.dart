import 'package:flutter/material.dart';

class GstCalculatorScreen extends StatefulWidget {
  const GstCalculatorScreen({super.key});

  @override
  State<GstCalculatorScreen> createState() => _GstCalculatorScreenState();
}

class _GstCalculatorScreenState extends State<GstCalculatorScreen> {
  final _amountController = TextEditingController();
  double _gstRate = 0.05; // Default GST rate
  double _gstAmount = 0.0;
  double _totalAmount = 0.0;

  final List<double> _gstSlabs = [0.05, 0.12, 0.18, 0.28]; // GST Slab Rates

  void _calculateGst() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    setState(() {
      _gstAmount = amount * _gstRate;
      _totalAmount = amount + _gstAmount;
    });
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Amount',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _calculateGst(),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<double>(
              value: _gstRate,
              decoration: const InputDecoration(
                labelText: 'Select GST Slab Rate',
                border: OutlineInputBorder(),
              ),
              items: _gstSlabs.map((rate) {
                return DropdownMenuItem<double>(
                  value: rate,
                  child: Text('${(rate * 100).toStringAsFixed(0)}%'),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _gstRate = newValue;
                    _calculateGst();
                  });
                }
              },
            ),
            const SizedBox(height: 30),
            Text(
              'GST Amount: ${_gstAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Total Amount (inclusive of GST): ${_totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}