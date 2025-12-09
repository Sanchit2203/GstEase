import 'package:flutter/material.dart';
import 'package:gstease/services/fraud_report_service.dart';

class UPIFraudReportScreen extends StatefulWidget {
  const UPIFraudReportScreen({super.key});

  @override
  State<UPIFraudReportScreen> createState() => _UPIFraudReportScreenState();
}

class _UPIFraudReportScreenState extends State<UPIFraudReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _upiIdController = TextEditingController();
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedReason = 'Fraud Transaction';
  bool _isLoading = false;
  
  final List<String> _fraudReasons = [
    'Fraud Transaction',
    'Fake QR Code',
    'Phishing Attempt',
    'Unauthorized Payment',
    'Suspicious Activity',
    'Scam/Cheating',
    'Other'
  ];

  @override
  void dispose() {
    _upiIdController.dispose();
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await FraudReportService.submitFraudReport(
        upiId: _upiIdController.text.trim(),
        reason: _selectedReason,
        description: _descriptionController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully. Thank you for helping keep our community safe!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Clear form
        _upiIdController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedReason = 'Fraud Transaction';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkUpiIdReports() async {
    final upiId = _upiIdController.text.trim();
    if (upiId.isEmpty) return;

    try {
      final reportData = await FraudReportService.getUpiIdReportInfo(upiId);

      if (reportData != null && mounted) {
        final reportCount = reportData['report_count'] ?? 0;
        final status = reportData['status'] ?? 'unknown';
        final riskLevel = FraudReportService.getRiskLevel(reportCount);
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('UPI ID Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UPI ID: $upiId'),
                const SizedBox(height: 8),
                Text('Reports: $reportCount'),
                const SizedBox(height: 8),
                Text('Status: ${status.toUpperCase()}'),
                const SizedBox(height: 8),
                Text('Risk Level: $riskLevel'),
                if (reportCount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    reportCount >= 10
                        ? '🚨 CRITICAL RISK - Avoid this UPI ID!'
                        : reportCount >= 5 
                            ? '⚠️ HIGH RISK - Multiple reports received'
                            : reportCount >= 3
                                ? '⚡ MEDIUM RISK - Some reports received'
                                : '⚠️ LOW RISK - Few reports received',
                    style: TextStyle(
                      color: reportCount >= 10
                          ? Colors.red.shade900
                          : reportCount >= 5 
                              ? Colors.red 
                              : reportCount >=3 
                                  ? Colors.orange 
                                  : Colors.yellow.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ No reports found for this UPI ID - Appears safe'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking UPI ID: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Fraudulent UPI ID'),
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade700,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning Card
                Card(
                  color: Colors.orange.shade50,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Report Responsibly',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Only report UPI IDs that you genuinely believe are involved in fraudulent activities. False reports may have consequences.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // UPI ID Input
                Text(
                  'UPI ID to Report *',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _upiIdController,
                        decoration: const InputDecoration(
                          hintText: 'Enter suspicious UPI ID (e.g., user@paytm)',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a UPI ID';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid UPI ID';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _checkUpiIdReports,
                      icon: const Icon(Icons.search),
                      tooltip: 'Check existing reports',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.shade100,
                        foregroundColor: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Reason Dropdown
                Text(
                  'Reason for Report *',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedReason,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.report_problem),
                  ),
                  items: _fraudReasons.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(reason),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Description
                Text(
                  'Detailed Description *',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Provide details about the fraudulent activity...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.description),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a description';
                    }
                    if (value.trim().length < 10) {
                      return 'Please provide more details (at least 10 characters)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit Report',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info Card
                Card(
                  color: Colors.blue.shade50,
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'What happens next?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Your report is stored securely and anonymously\n'
                          '• Multiple reports increase the risk level of a UPI ID\n'
                          '• High-risk UPI IDs are flagged for community awareness\n'
                          '• Our team may investigate reports for verification',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}