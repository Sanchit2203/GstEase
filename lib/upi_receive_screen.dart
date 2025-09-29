import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class UPIReceiveScreen extends StatefulWidget {
  const UPIReceiveScreen({super.key});

  @override
  State<UPIReceiveScreen> createState() => _UPIReceiveScreenState();
}

class _UPIReceiveScreenState extends State<UPIReceiveScreen> {
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _generateReceiveQR() {
    if (_upiIdController.text.isEmpty || _nameController.text.isEmpty) {
      return '';
    }
    
    String upiUrl = 'upi://pay?pa=${_upiIdController.text}&pn=${_nameController.text}&cu=INR';
    
    if (_amountController.text.isNotEmpty) {
      upiUrl += '&am=${_amountController.text}';
    }
    
    if (_noteController.text.isNotEmpty) {
      upiUrl += '&tn=${_noteController.text}';
    }
    
    return upiUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Payment'),
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
                      'Your Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _upiIdController,
                      decoration: const InputDecoration(
                        labelText: 'Your UPI ID',
                        hintText: 'yourname@upi',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        hintText: 'Enter your name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹) - Optional',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        hintText: 'Payment description',
                        prefixIcon: Icon(Icons.note),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_upiIdController.text.isNotEmpty && _nameController.text.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Your Payment QR Code',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: QrImageView(
                          data: _generateReceiveQR(),
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Share this QR code for others to pay you',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_amountController.text.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text(
                            'Amount: ₹${_amountController.text}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (_upiIdController.text.isEmpty || _nameController.text.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter your UPI ID and name to generate QR code',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
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
