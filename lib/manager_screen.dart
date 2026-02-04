import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  final TextEditingController _salaryController = TextEditingController();
  String _salaryType = 'Monthly';
  bool _showResults = false;
  double _monthlySalary = 0;
  double _yearlySalary = 0;

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  void _calculateInvestmentPlan() {
    if (_salaryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your salary')),
      );
      return;
    }

    double salary = double.tryParse(_salaryController.text) ?? 0;
    if (salary <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid salary amount')),
      );
      return;
    }

    setState(() {
      if (_salaryType == 'Monthly') {
        _monthlySalary = salary;
        _yearlySalary = salary * 12;
      } else {
        _yearlySalary = salary;
        _monthlySalary = salary / 12;
      }
      _showResults = true;
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the link')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _getAIFinancialAdvice() async {
    // Create a detailed financial summary for AI analysis
    String financialSummary = '''
I need personalized financial advice based on my income:

Monthly Salary: ₹${_monthlySalary.toStringAsFixed(0)}
Yearly Salary: ₹${_yearlySalary.toStringAsFixed(0)}

Please provide:
1. Customized investment strategy for my income level
2. Best mutual funds or investment options in India
3. Tax-saving recommendations under Section 80C and other sections
4. Emergency fund planning
5. Retirement planning advice
6. Risk management and insurance needs
7. Short-term and long-term financial goals I should set

Consider Indian financial markets and regulations in your advice.
    ''';

    // URL encode the prompt
    String encodedPrompt = Uri.encodeComponent(financialSummary);
    
    // Show dialog to choose AI platform
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.psychology, color: Colors.purple.shade700),
              const SizedBox(width: 8),
              const Text('Choose AI Assistant'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select an AI platform for personalized financial advice:'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text('ChatGPT'),
                subtitle: const Text('OpenAI\'s ChatGPT'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _launchURL('https://chat.openai.com/?q=$encodedPrompt');
                },
              ),
              
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWebResourceCard(String title, String description, String url, IconData icon, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _launchURL(url),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String amount, String description, Color color) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    amount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Manager'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Investment Rule Calculator',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Apply smart investment rules to your income',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            
            // Input Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Your Salary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _salaryController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Salary Amount',
                        prefixIcon: const Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _salaryType,
                      decoration: InputDecoration(
                        labelText: 'Salary Type',
                        prefixIcon: const Icon(Icons.calendar_month),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: ['Monthly', 'Yearly'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _salaryType = newValue!;
                          _showResults = false;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _calculateInvestmentPlan,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Calculate Investment Plan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (_showResults) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _getAIFinancialAdvice,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(color: Colors.purple.shade700, width: 2),
                          ),
                          icon: Icon(Icons.psychology, color: Colors.purple.shade700),
                          label: Text(
                            'Get AI Financial Advice',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_showResults) ...[
              const SizedBox(height: 32),
              Text(
                'Your Investment Breakdown',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Monthly: ₹${_monthlySalary.toStringAsFixed(0)} | Yearly: ₹${_yearlySalary.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // 50-30-20 Rule
              Text(
                '50-30-20 Rule (Monthly)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildResultCard(
                'Needs (50%)',
                '₹${(_monthlySalary * 0.5).toStringAsFixed(0)}',
                'Essential expenses: rent, groceries, utilities, insurance',
                Colors.blue,
              ),
              _buildResultCard(
                'Wants (30%)',
                '₹${(_monthlySalary * 0.3).toStringAsFixed(0)}',
                'Entertainment, dining out, hobbies, subscriptions',
                Colors.orange,
              ),
              _buildResultCard(
                'Savings & Investments (20%)',
                '₹${(_monthlySalary * 0.2).toStringAsFixed(0)}',
                'Emergency fund, retirement, investments, debt repayment',
                Colors.green,
              ),

              const SizedBox(height: 24),
              Text(
                'Other Investment Rules',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildResultCard(
                '10% Savings Rule (Monthly)',
                '₹${(_monthlySalary * 0.1).toStringAsFixed(0)}',
                'Minimum monthly savings recommendation',
                Colors.teal,
              ),
              _buildResultCard(
                'Emergency Fund Target',
                '₹${(_monthlySalary * 6).toStringAsFixed(0)}',
                '6 months of expenses (based on your monthly salary)',
                Colors.red,
              ),
              _buildResultCard(
                'Maximum Debt Payment (36%)',
                '₹${(_monthlySalary * 0.36).toStringAsFixed(0)}',
                'Your total debt payments should not exceed this amount',
                Colors.purple,
              ),
              _buildResultCard(
                'Annual Investment Target',
                '₹${(_yearlySalary * 0.2).toStringAsFixed(0)}',
                '20% of yearly income for long-term wealth building',
                Colors.indigo,
              ),

              const SizedBox(height: 24),
              Text(
                '70-20-10 Rule (Monthly)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildResultCard(
                'Living Expenses (70%)',
                '₹${(_monthlySalary * 0.7).toStringAsFixed(0)}',
                'Monthly living expenses and essential bills',
                Colors.cyan,
              ),
              _buildResultCard(
                'Savings & Investments (20%)',
                '₹${(_monthlySalary * 0.2).toStringAsFixed(0)}',
                'Future goals, emergency fund, and investments',
                Colors.green,
              ),
              _buildResultCard(
                'Fun & Entertainment (10%)',
                '₹${(_monthlySalary * 0.1).toStringAsFixed(0)}',
                'Guilt-free spending on hobbies and entertainment',
                Colors.pink,
              ),

              const SizedBox(height: 24),
              Text(
                'Retirement & Tax Planning',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildResultCard(
                '15% Retirement Savings Rule',
                '₹${(_monthlySalary * 0.15).toStringAsFixed(0)}/month',
                'Recommended monthly retirement savings (15% of salary)',
                Colors.deepOrange,
              ),
              _buildResultCard(
                'Section 80C Limit (Yearly)',
                '₹1,50,000',
                'Maximum tax deduction limit under Section 80C (EPF, PPF, ELSS, Insurance)',
                Colors.brown,
              ),
              _buildResultCard(
                'Retirement Corpus (25x Rule)',
                '₹${(_yearlySalary * 25).toStringAsFixed(0)}',
                'Target retirement corpus (25 times your annual expenses)',
                Colors.deepPurple,
              ),

              const SizedBox(height: 24),
              Text(
                'Asset Allocation & Investment Strategy',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildResultCard(
                '60-40 Asset Allocation',
                '60% Equity : 40% Debt',
                'Balanced portfolio: 60% in stocks/equity funds, 40% in bonds/debt',
                Colors.blueGrey,
              ),
              _buildResultCard(
                '10-5-3 Expected Returns',
                '10% Equity | 5% Debt | 3% Savings',
                'Average annual returns: Equity 10%, Debt 5%, Savings 3%',
                Colors.lime,
              ),
              _buildResultCard(
                'Gold Allocation (10-15%)',
                '₹${(_monthlySalary * 0.1).toStringAsFixed(0)} - ₹${(_monthlySalary * 0.15).toStringAsFixed(0)}',
                'Recommended monthly investment in gold for portfolio diversification',
                Colors.amber,
              ),

              const SizedBox(height: 24),
              Text(
                'Insurance & Protection',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildResultCard(
                'Life Insurance (10x Rule)',
                '₹${(_yearlySalary * 10).toStringAsFixed(0)}',
                'Recommended life insurance coverage (10 times annual salary)',
                Colors.red.shade700,
              ),
              _buildResultCard(
                'Health Insurance',
                '₹5,00,000 - ₹10,00,000',
                'Minimum recommended health insurance coverage per family',
                Colors.teal.shade700,
              ),

              const SizedBox(height: 24),
              Text(
                'Housing & Major Expenses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildResultCard(
                '28% Housing Rule',
                '₹${(_monthlySalary * 0.28).toStringAsFixed(0)}',
                'Maximum housing cost (rent/EMI + utilities) should not exceed 28% of monthly income',
                Colors.blue.shade800,
              ),
              _buildResultCard(
                '20% Down Payment Rule',
                'Save 20% of property value',
                'Target down payment for home purchase to avoid high EMIs and insurance',
                Colors.green.shade800,
              ),

              const SizedBox(height: 24),
              Text(
                'Quick Investment Calculators',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildResultCard(
                'Rule of 72',
                'Years to double = 72 ÷ Return %',
                'Calculate years to double your money at different return rates. At 12% return: 6 years',
                Colors.indigo.shade700,
              ),
              _buildResultCard(
                'SIP for 1 Crore (20 years)',
                '₹${(10000000 / (240 * 1.8)).toStringAsFixed(0)}/month',
                'Approximate monthly SIP to accumulate ₹1 Cr in 20 years @12% returns',
                Colors.purple.shade700,
              ),
              _buildResultCard(
                '4% Withdrawal Rule',
                '₹${(_yearlySalary * 25 * 0.04).toStringAsFixed(0)}/year',
                'Safe withdrawal amount in retirement (4% of your retirement corpus annually)',
                Colors.orange.shade700,
              ),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Pro Tips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Start investing early to benefit from compound interest\n'
                      '• Review and rebalance your portfolio annually\n'
                      '• Increase SIP by 10% every year with salary hikes\n'
                      '• Keep 3-6 months expenses in emergency fund\n'
                      '• Don\'t put all money in one investment\n'
                      '• Take term insurance, avoid traditional insurance plans\n'
                      '• Max out Section 80C for tax savings',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Text(
                'Investment Resources & Tools',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore investment platforms and calculators',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),

              _buildWebResourceCard(
                'Groww - Mutual Funds & Stocks',
                'Start investing in mutual funds and stocks',
                'https://groww.in',
                Icons.trending_up,
                Colors.green,
              ),
              _buildWebResourceCard(
                'Zerodha - Trading Platform',
                'India\'s largest stock broker for trading',
                'https://zerodha.com',
                Icons.show_chart,
                Colors.blue,
              ),
              _buildWebResourceCard(
                'ET Money - SIP Calculator',
                'Calculate your SIP returns and plan investments',
                'https://www.etmoney.com/mutual-funds/sip-calculator',
                Icons.calculate,
                Colors.purple,
              ),
              _buildWebResourceCard(
                'ClearTax - Tax Saving',
                'Tax planning and Section 80C calculator',
                'https://cleartax.in/s/income-tax-calculator',
                Icons.receipt_long,
                Colors.orange,
              ),
              _buildWebResourceCard(
                'Paytm Money - Investment',
                'Invest in mutual funds, stocks & gold',
                'https://www.paytmmoney.com',
                Icons.account_balance_wallet,
                Colors.indigo,
              ),
              _buildWebResourceCard(
                'NPS - Pension Scheme',
                'National Pension System for retirement',
                'https://www.npscra.nsdl.co.in',
                Icons.elderly,
                Colors.teal,
              ),
              _buildWebResourceCard(
                'PPF Calculator',
                'Calculate Public Provident Fund returns',
                'https://www.paisabazaar.com/saving-schemes/ppf-calculator/',
                Icons.savings,
                Colors.brown,
              ),
              _buildWebResourceCard(
                'Financial Education - Varsity',
                'Learn stock market & trading basics',
                'https://zerodha.com/varsity',
                Icons.school,
                Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
