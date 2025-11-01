import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'services/upi_handle_service.dart';

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
  
  String _currentUPIType = '';



  Future<void> _initiatePayment() async {
    if (_validateInputs()) {
      // Show loading indicator
      _showLoadingDialog();
      
      try {
        // Check UPI type
        String upiType = await UPIHandleService.checkUPIType(_upiIdController.text);
        
        // Hide loading dialog
        Navigator.of(context).pop();
        
        // Show UPI type popup and proceed with payment
        await _showUPITypeDialog(upiType);
        
      } catch (e) {
        // Hide loading dialog
        Navigator.of(context).pop();
        await _saveTransaction('Failed');
        _showPaymentDialog('Failed to check UPI type. Please try again.', false);
      }
    }
  }

  Future<void> _proceedWithPayment() async {
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
      'note': _noteController.text.isEmpty ? 'Payment' : _noteController.text,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
      'transactionId': 'TXN${DateTime.now().millisecondsSinceEpoch}',
    };
    
    transactions.add(jsonEncode(transaction));
    await prefs.setStringList('payment_history', transactions);
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Checking UPI type...'),
          ],
        ),
      ),
    );
  }

  Future<void> _showUPITypeDialog(String upiType) async {
    IconData icon;
    Color iconColor;
    String title;
    String message;

    switch (upiType.toLowerCase()) {
      case 'bank':
        icon = Icons.account_balance;
        iconColor = Colors.blue;
        title = 'Bank UPI';
        message = 'This UPI ID is registered with a Bank account. The payment will be processed through your bank.';
        break;
      case 'wallet':
        icon = Icons.account_balance_wallet;
        iconColor = Colors.green;
        title = 'Wallet UPI';
        message = 'This UPI ID is registered with a Digital Wallet. The payment will be processed through the wallet service.';
        break;
      default:
        icon = Icons.help_outline;
        iconColor = Colors.orange;
        title = 'Unknown UPI Type';
        message = 'Unable to determine the UPI type. The payment will still proceed normally.';
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: iconColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'UPI ID: ${_upiIdController.text}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _proceedWithPayment();
            },
            icon: const Icon(Icons.payment),
            label: const Text('Proceed to Pay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
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
    setState(() {
      _currentUPIType = '';
    });
  }

  Future<void> _onUPIIdChanged(String value) async {
    if (value.contains('@') && value.length > 3) {
      try {
        String upiType = await UPIHandleService.checkUPIType(value);
        setState(() {
          _currentUPIType = upiType;
        });
      } catch (e) {
        setState(() {
          _currentUPIType = '';
        });
      }
    } else {
      setState(() {
        _currentUPIType = '';
      });
    }
  }

  Future<void> _showUPIHandlesDialog() async {
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading UPI handles...'),
          ],
        ),
      ),
    );

    try {
      final handles = await UPIHandleService.getAllHandles();
      
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Check if handles are empty
      if (handles.isEmpty || (handles['bank']?.isEmpty == true && handles['wallet']?.isEmpty == true)) {
        _showSnackBar('No UPI handles found. Please check your internet connection.');
        return;
      }
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Available UPI Handles (${(handles['bank']?.length ?? 0) + (handles['wallet']?.length ?? 0)} total)'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.account_balance),
                        text: 'Bank (${handles['bank']?.length ?? 0})',
                      ),
                      Tab(
                        icon: const Icon(Icons.account_balance_wallet),
                        text: 'Wallet (${handles['wallet']?.length ?? 0})',
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildHandlesList(handles['bank'] ?? [], 'bank'),
                        _buildHandlesList(handles['wallet'] ?? [], 'wallet'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                UPIHandleService.clearCache();
                Navigator.of(context).pop();
                _showUPIHandlesDialog(); // Reload
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Close loading dialog
      Navigator.of(context).pop();
      _showSnackBar('Failed to load UPI handles: ${e.toString()}');
      print('Error in _showUPIHandlesDialog: $e');
    }
  }

  Widget _buildHandlesList(List<String> handles, String type) {
    if (handles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'bank' ? Icons.account_balance : Icons.account_balance_wallet,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type} handles found',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your internet connection\nand try refreshing',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: handles.length,
      itemBuilder: (context, index) {
        final handle = handles[index];
        return ListTile(
          dense: true,
          leading: Icon(
            type == 'bank' ? Icons.account_balance : Icons.account_balance_wallet,
            size: 20,
            color: type == 'bank' ? Colors.blue : Colors.green,
          ),
          title: Text(
            handle,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            'Tap to use this ${type} handle',
            style: const TextStyle(fontSize: 10),
          ),
          onTap: () {
            // Add the handle to current UPI ID if it doesn't already have one
            String currentText = _upiIdController.text;
            if (!currentText.contains('@')) {
              _upiIdController.text = currentText + handle;
            } else {
              // Replace the handle part
              String userPart = currentText.split('@').first;
              _upiIdController.text = userPart + handle;
            }
            Navigator.of(context).pop();
            _onUPIIdChanged(_upiIdController.text);
          },
        );
      },
    );
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _upiIdController,
                          decoration: InputDecoration(
                            labelText: 'UPI ID',
                            hintText: 'example@upi',
                            prefixIcon: const Icon(Icons.alternate_email),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.help_outline),
                              onPressed: _showUPIHandlesDialog,
                              tooltip: 'View available UPI handles',
                            ),
                          ),
                          onChanged: _onUPIIdChanged,
                        ),
                        if (_currentUPIType.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  _currentUPIType == 'bank' 
                                    ? Icons.account_balance
                                    : _currentUPIType == 'wallet'
                                      ? Icons.account_balance_wallet
                                      : Icons.help_outline,
                                  size: 16,
                                  color: _currentUPIType == 'bank'
                                    ? Colors.blue
                                    : _currentUPIType == 'wallet'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _currentUPIType == 'bank'
                                    ? 'Bank UPI'
                                    : _currentUPIType == 'wallet'
                                      ? 'Wallet UPI'
                                      : 'Unknown type',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _currentUPIType == 'bank'
                                      ? Colors.blue
                                      : _currentUPIType == 'wallet'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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
