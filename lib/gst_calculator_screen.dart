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

  // MODIFIED: Added 0 to the list
  final List<double> _quickGstRates = [0, 5, 12, 18, 28];

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

      // MODIFIED: Allow 0% GST, but not negative rates
      if (currentGstRate < 0) {
        _resetResults();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            // MODIFIED: Updated message
            const SnackBar(content: Text('GST Rate cannot be negative.')),
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
        // Handle division by zero if currentGstRate is -100, though validation prevents this
        calculatedGstAmount = (100 + currentGstRate == 0) ? 0 : (amount * currentGstRate) / (100 + currentGstRate);
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
      // MODIFIED: Allow 0 for display, but guard against negative if it somehow bypasses validation
      return rate >= 0 ? rate : 0;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calculate,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('GST Calculator'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.bookmark_add_outlined, color: Theme.of(context).colorScheme.primary),
            tooltip: 'Save Calculation',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Save feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
            tooltip: 'History',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Main Input Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.currency_rupee, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Amount Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Amount Input
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount (₹)',
                          hintText: 'Enter amount',
                          prefixIcon: const Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                          if (double.parse(value) <= 0) { // Amount still must be > 0
                            return 'Amount must be > 0';
                          }
                          return null;
                        },
                        onChanged: (_) => _resetResults(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // GST Rate Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.percent, color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 8),
                          Text(
                            'GST Rate',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Text(
                        'Quick Select',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _quickGstRates.map((rate) {
                          final isSelected = _selectedQuickGstRate == rate;
                          return Material(
                            elevation: isSelected ? 4 : 1,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () {
                                if (mounted) {
                                  setState(() {
                                    _selectedQuickGstRate = rate;
                                    _gstRateController.text = rate.toStringAsFixed(0); // Update text field as well
                                    _resetResults(); // Reset results when rate changes
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected 
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  '${rate.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: isSelected 
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      
                      Text(
                        'Custom Rate',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // GST Rate Custom Input
                      TextFormField(
                        controller: _gstRateController,
                        decoration: InputDecoration(
                          labelText: 'Enter Custom GST Rate (%)',
                          hintText: 'e.g., 15',
                          prefixIcon: const Icon(Icons.percent),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                            // MODIFIED: Allow 0%, but not negative
                            if (rateValue < 0) {
                              // MODIFIED: Updated message
                              return 'Rate cannot be negative';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Settings Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.settings, color: Theme.of(context).colorScheme.tertiary),
                          const SizedBox(width: 8),
                          Text(
                            'Calculation Settings',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Calculation Mode Selector
                      Text('Calculation Mode', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (mounted) {
                                    setState(() {
                                      _isSelectedMode = [true, false];
                                      _resetResults();
                                    });
                                  }
                                },
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _isSelectedMode[0] 
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Inclusive GST',
                                    style: TextStyle(
                                      color: _isSelectedMode[0] 
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (mounted) {
                                    setState(() {
                                      _isSelectedMode = [false, true];
                                      _resetResults();
                                    });
                                  }
                                },
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _isSelectedMode[1] 
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Exclusive GST',
                                    style: TextStyle(
                                      color: _isSelectedMode[1] 
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Transaction Type Selector
                      Text('Transaction Type', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                if (mounted) {
                                  setState(() {
                                    _isSelectedTransactionType = [true, false];
                                    _resetResults();
                                  });
                                }
                              },
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _isSelectedTransactionType[0] 
                                      ? Theme.of(context).colorScheme.secondary
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_city,
                                      color: _isSelectedTransactionType[0] 
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.onSurface,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Intra-State (CGST + SGST)',
                                      style: TextStyle(
                                        color: _isSelectedTransactionType[0] 
                                            ? Colors.white
                                            : Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              height: 1,
                              color: Colors.grey.shade300,
                            ),
                            InkWell(
                              onTap: () {
                                if (mounted) {
                                  setState(() {
                                    _isSelectedTransactionType = [false, true];
                                    _resetResults();
                                  });
                                }
                              },
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _isSelectedTransactionType[1] 
                                      ? Theme.of(context).colorScheme.secondary
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.public,
                                      color: _isSelectedTransactionType[1] 
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.onSurface,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Inter-State (IGST)',
                                      style: TextStyle(
                                        color: _isSelectedTransactionType[1] 
                                            ? Colors.white
                                            : Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Calculate Button
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _calculateGstOnClick,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Calculate GST',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Results Section
              if (_finalPrice > 0 || _basePrice > 0 || _gstAmountValue > 0 || (_amountController.text.isNotEmpty && (double.tryParse(_amountController.text) ?? 0) > 0) ) // Show card if results or valid amount
                Card(
                  elevation: 6,
                  shadowColor: Colors.green.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.shade50,
                          Colors.blue.shade50,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.receipt_long,
                                  color: Colors.green.shade700,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Calculation Results',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildResultRow('Base Price:', _basePrice.toStringAsFixed(2)),
                                const SizedBox(height: 12),
                                _buildResultRow('GST Amount:', _gstAmountValue.toStringAsFixed(2)),
                                if (_isSelectedTransactionType[0]) ...[ // Intra-State
                                  const SizedBox(height: 8),
                                  _buildResultRow('  CGST (${(currentRateForDisplay() / 2).toStringAsFixed(1)}%):', _cgst.toStringAsFixed(2)),
                                  const SizedBox(height: 4),
                                  _buildResultRow('  SGST (${(currentRateForDisplay() / 2).toStringAsFixed(1)}%):', _sgst.toStringAsFixed(2)),
                                ] else ...[ // Inter-State
                                  const SizedBox(height: 8),
                                  _buildResultRow('  IGST (${currentRateForDisplay().toStringAsFixed(1)}%):', _igst.toStringAsFixed(2)),
                                ],
                                const SizedBox(height: 16),
                                Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.green.shade300, Colors.blue.shade300],
                                    ),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildResultRow('Final Price:', _finalPrice.toStringAsFixed(2), isTotal: true),
                              ],
                            ),
                          ),
                        ],
                      ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.green.shade700 : Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '₹ $value',
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? Colors.green.shade700 : Colors.black87,
          ),
        ),
      ],
    );
  }
}