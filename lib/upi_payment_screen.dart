import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

  // Popular UPI apps with their package names
  final List<Map<String, String>> upiApps = [
    {'name': 'PhonePe', 'package': 'com.phonepe.app', 'icon': '📱'},
    {'name': 'Google Pay', 'package': 'com.google.android.apps.nbu.paisa.user', 'icon': '💳'},
    {'name': 'Paytm', 'package': 'net.one97.paytm', 'icon': '💰'},
    {'name': 'BHIM UPI', 'package': 'in.org.npci.upiapp', 'icon': '🏦'},
    {'name': 'Amazon Pay', 'package': 'com.amazon.mobile.shopping', 'icon': '📦'},
  ];

  Future<void> _initiatePayment(String appPackage) async {
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

  void _showQrCode() {
    if (_validateInputs()) {
      final upiUrl = _generateUpiUrl();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('UPI QR Code'),
          content: SizedBox(
            width: 280,
            height: 280,
            child: Column(
              children: [
                QrImageView(
                  data: upiUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan this QR code with any UPI app to pay',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Payment'),
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
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showQrCode,
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Generate QR Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Select UPI App',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: upiApps.length,
              itemBuilder: (context, index) {
                final app = upiApps[index];
                return Card(
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _initiatePayment(app['package']!),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            app['icon']!,
                            style: const TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            app['name']!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
