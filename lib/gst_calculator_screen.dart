import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for TextInputFormatter
import 'dart:math'; // For precision

class GstCalculatorScreen extends StatefulWidget {
  const GstCalculatorScreen({super.key});

  @override
  State<GstCalculatorScreen> createState() => _GstCalculatorScreenState();
}

class _GstCalculatorScreenState extends State<GstCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _gstRateController = TextEditingController();

  // For quick select GST Rate buttons
  double? _selectedQuickGstRate;

  // Calculation mode: true for Inclusive, false for Exclusive
  List<bool> _isSelectedMode = [false, true]; // [Inclusive, Exclusive], Exclusive by default

  // Transaction type: true for Intra-State (CGST/SGST), false for Inter-State (IGST)
  // Corrected: Intra-State is typically CGST+SGST (index 0), Inter-State is IGST (index 1)
  // Let's assume _isSelectedTransactionType[0] is Intra-State by default.
  List<bool> _isSelectedTransactionType = [true, false]; // [Intra-State, Inter-State], Intra-State by default

  double _basePrice = 0.0;
  double _gstAmountValue = 0.0;
  double _finalPrice = 0.0;
  double _cgst = 0.0;
  double _sgst = 0.0;
  double _igst = 0.0;

  final List<double> _quickGstRates = [5, 12, 18, 28];

  @override
  void dispose() {
    _amountController.dispose();
    _gstRateController.dispose();
    super.dispose();
  }

  double _roundDouble(double value, int places) {
    num mod = pow(10.0, places);
    return ((value * mod).round().toDouble() / mod);
  }

  void _resetRateSelection({bool keepCustomRate = false}) {
    // When a rate is selected/deselected, results should also reset until calculation
    if (mounted) { // Check if the widget is still in the tree
      setState(() {
        _selectedQuickGstRate = null;
        if (!keepCustomRate) {
          _gstRateController.clear();
        }
        // _resetResults(); // Reset results when rate selection changes
      });
    }
  }
  
  void _resetResults() {
    if (mounted) {
      setState(() {
        _basePrice = 0.0;
        _gstAmountValue = 0.0;
        _finalPrice = 0.0;
        _cgst = 0.0;
        _sgst = 0.0;
        _igst = 0.0;
      });
    }
  }

  void _calculateGstOnClick() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final double amount = double.tryParse(_amountController.text) ?? 0.0;
      // Use _gstRateController.text for custom rate, _selectedQuickGstRate for quick selection
      final double gstRateFromField = double.tryParse(_gstRateController.text) ?? 0.0;
      
      // Prioritize quick select rate if chosen and valid, otherwise use text field rate
      final double currentGstRate = _selectedQuickGstRate ?? gstRateFromField;

      if (currentGstRate <= 0) {
        _resetResults();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GST Rate must be greater than 0.')),
          );
        }
        return;
      }
      
      bool isInclusiveModeSelected = _isSelectedMode[0]; // true if "Inclusive" is selected at index 0
      bool isIntraStateSelected = _isSelectedTransactionType[0]; // true if "Intra-State" is selected at index 0

      double calculatedBasePrice = 0.0;
      double calculatedGstAmount = 0.0;
      double calculatedFinalPrice = 0.0;

      if (isInclusiveModeSelected) {
        // Amount is Final Price
        calculatedFinalPrice = amount;
        calculatedGstAmount = (amount * currentGstRate) / (100 + currentGstRate);
        calculatedBasePrice = amount - calculatedGstAmount;
      } else {
        // Amount is Base Price
        calculatedBasePrice = amount;
        calculatedGstAmount = (amount * currentGstRate) / 100;
        calculatedFinalPrice = amount + calculatedGstAmount;
      }

      if (mounted) {
        setState(() {
          _basePrice = _roundDouble(calculatedBasePrice, 2);
          _gstAmountValue = _roundDouble(calculatedGstAmount, 2);
          _finalPrice = _roundDouble(calculatedFinalPrice, 2);

          if (isIntraStateSelected) { // Intra-State
            _cgst = _roundDouble(calculatedGstAmount / 2, 2);
            _sgst = _roundDouble(calculatedGstAmount / 2, 2);
            _igst = 0.0;
          } else { // Inter-State
            _igst = _roundDouble(calculatedGstAmount, 2);
            _cgst = 0.0;
            _sgst = 0.0;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine current GST rate for display in results, ensuring it's not null or 0 before division
    double currentRateForDisplay() {
        double rate = _selectedQuickGstRate ?? (double.tryParse(_gstRateController.text) ?? 0);
        return rate > 0 ? rate : 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('GST Calculator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Amount Input
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                   if (double.parse(value) <= 0) {
                    return 'Amount must be > 0';
                  }
                  return null;
                },
                onChanged: (_) => _resetResults(),
              ),
              const SizedBox(height: 20),

              // GST Rate Quick Select
              Text('GST Rate (%)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _quickGstRates.map((rate) {
                  return ElevatedButton(
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          _selectedQuickGstRate = rate;
                          _gstRateController.text = rate.toStringAsFixed(0); // Update text field as well
                          _resetResults(); // Reset results when rate changes
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedQuickGstRate == rate
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor: _selectedQuickGstRate == rate
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    child: Text('${rate.toStringAsFixed(0)}%'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // GST Rate Custom Input
              TextFormField(
                controller: _gstRateController,
                decoration: const InputDecoration(
                  labelText: 'Or Enter Custom GST Rate (%)',
                  hintText: 'e.g., 15',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                 onTap: () { 
                    if (_selectedQuickGstRate != null) {
                       _resetRateSelection(keepCustomRate: true); // keepCustomRate true as user is now typing
                    }
                 },
                onChanged: (value) {
                  if (mounted) {
                    setState(() {
                      if (_selectedQuickGstRate != null) {
                        _selectedQuickGstRate = null; // Clear quick selection if user types
                      }
                      _resetResults(); // Reset results when rate changes
                    });
                  }
                },
                validator: (value) {
                  // Validate only if no quick rate is selected
                  if (_selectedQuickGstRate == null) {
                    if (value == null || value.isEmpty) {
                      return 'Please select or enter a GST rate';
                    }
                    final rateValue = double.tryParse(value);
                    if (rateValue == null) {
                      return 'Please enter a valid rate';
                    }
                    if (rateValue <= 0) {
                       return 'Rate must be > 0';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Calculation Mode Selector
              Text('Calculation Mode', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ToggleButtons(
                isSelected: _isSelectedMode,
                onPressed: (int index) {
                  if (mounted) {
                    setState(() {
                      for (int i = 0; i < _isSelectedMode.length; i++) {
                        _isSelectedMode[i] = i == index;
                      }
                       _resetResults();
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8.0),
                constraints: BoxConstraints(minWidth: (MediaQuery.of(context).size.width - 48) / 2, minHeight: 40),
                children: const <Widget>[
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Inclusive GST')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Exclusive GST')),
                ],
              ),
              const SizedBox(height: 20),
              
              // Transaction Type Selector
              Text('Transaction Type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ToggleButtons(
                isSelected: _isSelectedTransactionType,
                onPressed: (int index) {
                  if (mounted) {
                    setState(() {
                      for (int i = 0; i < _isSelectedTransactionType.length; i++) {
                        _isSelectedTransactionType[i] = i == index;
                      }
                       _resetResults();
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8.0),
                constraints: BoxConstraints(minWidth: (MediaQuery.of(context).size.width - 48) / 2, minHeight: 40),
                children: const <Widget>[
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Intra-State (CGST/SGST)')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Inter-State (IGST)')),
                ],
              ),
              const SizedBox(height: 30),

              // Calculate Button
              ElevatedButton(
                onPressed: _calculateGstOnClick,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Calculate GST'),
              ),
              const SizedBox(height: 30),

              // Results Section
              if (_finalPrice > 0 || _basePrice > 0 || _gstAmountValue > 0)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text('Results', style: Theme.of(context).textTheme.headlineSmall),
                        const Divider(height: 20, thickness: 1),
                        _buildResultRow('Base Price:', _basePrice.toStringAsFixed(2)),
                        _buildResultRow('GST Amount:', _gstAmountValue.toStringAsFixed(2)),
                        if (_isSelectedTransactionType[0]) ...[ // Intra-State
                           _buildResultRow('  CGST (${(currentRateForDisplay() / 2).toStringAsFixed(1)}%):', _cgst.toStringAsFixed(2)),
                           _buildResultRow('  SGST (${(currentRateForDisplay() / 2).toStringAsFixed(1)}%):', _sgst.toStringAsFixed(2)),
                        ] else ...[ // Inter-State
                           _buildResultRow('  IGST (${currentRateForDisplay().toStringAsFixed(1)}%):', _igst.toStringAsFixed(2)),
                        ],
                        const Divider(height: 20, thickness: 1),
                        _buildResultRow('Final Price:', _finalPrice.toStringAsFixed(2), isTotal: true),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: TextStyle(fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
