import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class UPIPaymentScreen extends StatefulWidget {
  const UPIPaymentScreen({super.key});

  @override
  State<UPIPaymentScreen> createState() => _UPIPaymentScreenState();
}

class _UPIPaymentScreenState extends State<UPIPaymentScreen> {
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();



  Future<void> _initiatePayment() async {
    if (_validateInputs()) {
      final upiUrl = _generateUpiUrl();
      try {
        final uri = Uri.parse(upiUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          await _saveTransaction('Success');
          _showPaymentDialog('Payment initiated successfully!', true);
        } else {
          throw 'Could not launch UPI app';
        }
      } catch (e) {
        await _saveTransaction('Failed');
        _showPaymentDialog('Failed to initiate payment. Please try again.', false);
      }
    }
  }

  bool _validateInputs() {
    if (_upiIdController.text.isEmpty) {
      _showSnackBar('Please enter UPI ID');
      return false;
    }
    if (_nameController.text.isEmpty) {
      _showSnackBar('Please enter receiver name');
      return false;
    }
    if (_amountController.text.isEmpty || double.tryParse(_amountController.text) == null) {
      _showSnackBar('Please enter valid amount');
      return false;
    }
    return true;
  }

  Future<void> _saveTransaction(String status) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> transactions = prefs.getStringList('payment_history') ?? [];
    
    Map<String, dynamic> transaction = {
      'id': 'TXN${DateTime.now().millisecondsSinceEpoch}',
      'amount': _amountController.text,
      'receiverName': _nameController.text,
      'receiverUpiId': _upiIdController.text,
      'note': _noteController.text.isEmpty ? 'GST Payment' : _noteController.text,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
      'transactionId': 'TXN${DateTime.now().millisecondsSinceEpoch}',
    };
    
    transactions.add(jsonEncode(transaction));
    await prefs.setStringList('payment_history', transactions);
  }

  void _showPaymentDialog(String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isSuccess ? 'Success' : 'Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (isSuccess) {
                _clearForm();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _upiIdController.clear();
    _nameController.clear();
    _amountController.clear();
    _noteController.clear();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _generateUpiUrl() {
    if (!_validateInputs()) return '';
    
    return 'upi://pay?pa=${_upiIdController.text}&pn=${_nameController.text}&am=${_amountController.text}&tn=${_noteController.text.isEmpty ? 'GST Payment' : _noteController.text}&cu=INR';
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _upiIdController,
                      decoration: const InputDecoration(
                        labelText: 'UPI ID',
                        hintText: 'example@upi',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Receiver Name',
                        hintText: 'Enter receiver name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        hintText: 'Payment description',
                        prefixIcon: Icon(Icons.note),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _initiatePayment,
                    icon: const Icon(Icons.payment),
                    label: const Text('Make Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Click "Make Payment" to choose your preferred UPI app and complete the transaction.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
