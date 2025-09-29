import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _addDemoTransaction() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> transactions = prefs.getStringList('payment_history') ?? [];
    
    Map<String, dynamic> demoTransaction = {
      'id': 'DEMO${DateTime.now().millisecondsSinceEpoch}',
      'amount': '100.00',
      'receiverName': 'Demo Merchant',
      'receiverUpiId': 'demo@upi',
      'note': 'Demo GST Payment',
      'status': 'Success',
      'timestamp': DateTime.now().toIso8601String(),
      'transactionId': 'DEMO${DateTime.now().millisecondsSinceEpoch}',
    };
    
    transactions.add(jsonEncode(demoTransaction));
    await prefs.setStringList('payment_history', transactions);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> transactionStrings = prefs.getStringList('payment_history') ?? [];
    
    List<Map<String, dynamic>> loadedTransactions = transactionStrings
        .map((transactionString) => jsonDecode(transactionString) as Map<String, dynamic>)
        .toList();
    
    // Sort by timestamp (newest first)
    loadedTransactions.sort((a, b) => 
        DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
    
    setState(() {
      transactions = loadedTransactions;
      isLoading = false;
    });
  }

  String _formatDateTime(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addDemoTransaction,
            tooltip: 'Add Demo Transaction',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _loadTransactions();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No payment history found',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(transaction['status']).withOpacity(0.1),
                          child: Icon(
                            _getStatusIcon(transaction['status']),
                            color: _getStatusColor(transaction['status']),
                          ),
                        ),
                        title: Text(
                          '₹${transaction['amount']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('To: ${transaction['receiverName']}'),
                            Text('UPI: ${transaction['receiverUpiId']}'),
                            if (transaction['note'].toString().isNotEmpty)
                              Text('Note: ${transaction['note']}'),
                            Text(
                              _formatDateTime(transaction['timestamp']),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(transaction['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            transaction['status'],
                            style: TextStyle(
                              color: _getStatusColor(transaction['status']),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () {
                          _showTransactionDetails(transaction);
                        },
                      ),
                    );
                  },
                ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount', '₹${transaction['amount']}'),
            _buildDetailRow('Status', transaction['status']),
            _buildDetailRow('Receiver', transaction['receiverName']),
            _buildDetailRow('UPI ID', transaction['receiverUpiId']),
            _buildDetailRow('Transaction ID', transaction['transactionId']),
            _buildDetailRow('Reference ID', transaction['id']),
            if (transaction['note'].toString().isNotEmpty)
              _buildDetailRow('Note', transaction['note']),
            _buildDetailRow('Date & Time', _formatDateTime(transaction['timestamp'])),
          ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
