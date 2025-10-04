import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  double totalAmount = 0.0;
  int successfulPayments = 0;
  int failedPayments = 0;
  int pendingPayments = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
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
            colors: [color.withValues(alpha: 0.8), color],
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
                    color: Colors.white.withValues(alpha: 0.3),
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
                color: Colors.white.withValues(alpha: 0.8),
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
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
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
                    Navigator.pop(context);
                    // Navigate to payment history
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
                      backgroundColor: _getStatusColor(transaction['status']).withValues(alpha: 0.1),
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
                        color: _getStatusColor(transaction['status']).withValues(alpha: 0.1),
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
        actions: [
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
          : SingleChildScrollView(
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
            ),
    );
  }
}
