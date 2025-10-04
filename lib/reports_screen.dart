import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  double totalAmount = 0.0;
  int successfulPayments = 0;
  int failedPayments = 0;
  int pendingPayments = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> transactionStrings = prefs.getStringList('payment_history') ?? [];
    
    List<Map<String, dynamic>> loadedTransactions = transactionStrings
        .map((transactionString) => jsonDecode(transactionString) as Map<String, dynamic>)
        .toList();
    
    _calculateAnalytics(loadedTransactions);
    
    setState(() {
      transactions = loadedTransactions;
      isLoading = false;
    });
  }

  void _calculateAnalytics(List<Map<String, dynamic>> transactions) {
    totalAmount = 0.0;
    successfulPayments = 0;
    failedPayments = 0;
    pendingPayments = 0;

    for (var transaction in transactions) {
      String status = transaction['status'].toString().toLowerCase();
      double amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;
      
      switch (status) {
        case 'success':
          successfulPayments++;
          totalAmount += amount;
          break;
        case 'failed':
          failedPayments++;
          break;
        case 'pending':
          pendingPayments++;
          break;
      }
    }
  }

  // Calculate monthly transaction data from actual transactions
  Map<String, double> _calculateMonthlyData() {
    final now = DateTime.now();
    final Map<String, double> monthlyData = {};
    
    // Initialize last 6 months with zero values
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = _getMonthAbbreviation(month.month);
      monthlyData[monthKey] = 0.0;
    }
    
    // If no transactions, return months with zero values
    if (transactions.isEmpty) {
      return monthlyData;
    }
    
    // Calculate actual monthly totals from transactions
    for (var transaction in transactions) {
      try {
        // Parse transaction timestamp
        String timestampStr = transaction['timestamp']?.toString() ?? '';
        if (timestampStr.isEmpty) continue;
        
        DateTime transactionDate = DateTime.parse(timestampStr);
        String monthKey = _getMonthAbbreviation(transactionDate.month);
        
        // Only include transactions from the last 6 months
        if (monthlyData.containsKey(monthKey)) {
          double amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;
          String status = transaction['status'].toString().toLowerCase();
          
          // Only count successful transactions
          if (status == 'success') {
            monthlyData[monthKey] = (monthlyData[monthKey] ?? 0.0) + amount;
          }
        }
      } catch (e) {
        // Skip invalid transaction dates
        continue;
      }
    }
    
    return monthlyData;
  }

  // Get month abbreviation from month number
  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // Add demo transaction (merged from payment history screen)
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
    _loadAnalytics(); // Refresh data
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 32),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.trending_up, color: Colors.white, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart() {
    // Generate dynamic data based on actual transactions
    final Map<String, double> monthlyTransactionData = _calculateMonthlyData();
    final List<double> monthlyData = monthlyTransactionData.values.toList();
    final List<String> months = monthlyTransactionData.keys.toList();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Transaction Volume',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: monthlyData.isEmpty || monthlyData.every((value) => value == 0) 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transaction data available',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chart will update as you make transactions',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(monthlyData.length, (index) {
                      // Find the maximum value for proper scaling
                      double maxValue = monthlyData.isNotEmpty 
                          ? monthlyData.reduce((a, b) => a > b ? a : b) 
                          : 100;
                      if (maxValue == 0) maxValue = 100; // Prevent division by zero
                      
                      double normalizedHeight = (monthlyData[index] / maxValue) * 150;
                      if (normalizedHeight < 10 && monthlyData[index] > 0) {
                        normalizedHeight = 10; // Minimum height for visibility
                      }
                      
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            monthlyData[index] > 0 
                                ? '₹${monthlyData[index].toInt()}' 
                                : '₹0',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 30,
                            height: normalizedHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: monthlyData[index] > 0 ? [
                                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                  Theme.of(context).colorScheme.primary,
                                ] : [
                                  Colors.grey.shade300,
                                  Colors.grey.shade400,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            months[index],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Build analytics tab (existing content)
  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                title: 'Total Amount',
                value: '₹${totalAmount.toStringAsFixed(2)}',
                icon: Icons.currency_rupee,
                color: const Color(0xFF4CAF50),
              ),
              _buildStatCard(
                title: 'Successful',
                value: successfulPayments.toString(),
                icon: Icons.check_circle,
                color: const Color(0xFF2196F3),
              ),
              _buildStatCard(
                title: 'Failed',
                value: failedPayments.toString(),
                icon: Icons.error,
                color: const Color(0xFFF44336),
              ),
              _buildStatCard(
                title: 'Pending',
                value: pendingPayments.toString(),
                icon: Icons.access_time,
                color: const Color(0xFFFF9800),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Monthly Chart
          _buildMonthlyChart(),
          const SizedBox(height: 24),
          
          // Recent Transactions
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  // Build payment history tab (merged from payment history screen)
  Widget _buildPaymentHistoryTab() {
    List<Map<String, dynamic>> sortedTransactions = List.from(transactions);
    sortedTransactions.sort((a, b) => 
      DateTime.parse(b['timestamp'] ?? DateTime.now().toIso8601String())
          .compareTo(DateTime.parse(a['timestamp'] ?? DateTime.now().toIso8601String())));

    return transactions.isEmpty
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
                  'No Payment History',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your payment transactions will appear here',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _addDemoTransaction,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Demo Transaction'),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedTransactions.length,
            itemBuilder: (context, index) {
              final transaction = sortedTransactions[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(transaction['status']).withOpacity(0.2),
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
                      const SizedBox(height: 4),
                      Text(
                        'To: ${transaction['receiverName']}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (transaction['note'] != null && transaction['note'].isNotEmpty)
                        Text('Note: ${transaction['note']}'),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(transaction['timestamp'] ?? ''),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(transaction['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(transaction['status']).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      transaction['status'],
                      style: TextStyle(
                        color: _getStatusColor(transaction['status']),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildRecentTransactions() {
    List<Map<String, dynamic>> recentTransactions = transactions.take(5).toList();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _tabController.animateTo(1); // Switch to payment history tab
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentTransactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No transactions found',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: recentTransactions.map((transaction) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(transaction['status']).withOpacity(0.1),
                      child: Icon(
                        _getStatusIcon(transaction['status']),
                        color: _getStatusColor(transaction['status']),
                        size: 20,
                      ),
                    ),
                    title: Text('₹${transaction['amount']}'),
                    subtitle: Text(transaction['receiverName']),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to format date time
  String _formatDateTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays == 0) {
        return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Unknown date';
    }
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
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey.shade600,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.history), text: 'Payment History'),
          ],
        ),
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
              _loadAnalytics();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAnalyticsTab(),
                _buildPaymentHistoryTab(),
              ],
            ),
    );
  }
}
