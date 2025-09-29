import 'package:flutter/material.dart';

class RateTrackerScreen extends StatefulWidget {
  const RateTrackerScreen({super.key});

  @override
  State<RateTrackerScreen> createState() => _RateTrackerScreenState();
}

class _RateTrackerScreenState extends State<RateTrackerScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All Categories';
  
  // Sample GST rate data
  final List<GSTRateItem> _gstRates = [
    GSTRateItem('Essential Goods', 'Rice, Wheat, Milk, Vegetables', 0, Colors.green),
    GSTRateItem('Basic Necessities', 'Salt, Sugar, Tea, Coffee', 5, Colors.blue),
    GSTRateItem('Processed Foods', 'Biscuits, Namkeen, Sweets', 12, Colors.orange),
    GSTRateItem('Consumer Goods', 'Soaps, Toothpaste, Shampoo', 18, Colors.purple),
    GSTRateItem('Electronics', 'Mobile Phones, Laptops, TV', 18, Colors.indigo),
    GSTRateItem('Luxury Items', 'Cars, Cigarettes, Aerated Drinks', 28, Colors.red),
    GSTRateItem('Textiles', 'Fabrics, Readymade Garments', 12, Colors.teal),
    GSTRateItem('Medicines', 'Life Saving Drugs, Formulations', 12, Colors.cyan),
  ];
  
  final List<String> _categories = [
    'All Categories',
    'Essential Goods',
    'Basic Necessities', 
    'Processed Foods',
    'Consumer Goods',
    'Electronics',
    'Luxury Items',
    'Textiles',
    'Medicines',
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  List<GSTRateItem> get _filteredRates {
    if (_selectedCategory == 'All Categories') {
      return _gstRates;
    }
    return _gstRates.where((item) => item.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.trending_up,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Rate Tracker'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey.shade600,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'GST Rates'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Overview'),
            Tab(icon: Icon(Icons.history), text: 'Updates'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRatesTab(),
          _buildOverviewTab(),
          _buildUpdatesTab(),
        ],
      ),
    );
  }
  
  Widget _buildRatesTab() {
    return Column(
      children: [
        // Category Filter
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;
              
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        
        // Rates List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _filteredRates.length,
            itemBuilder: (context, index) {
              return _buildRateCard(_filteredRates[index]);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildRateCard(GSTRateItem item) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item.color.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Rate Badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${item.rate}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: item.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getRateLabel(item.rate),
                        style: TextStyle(
                          color: item.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Categories', '8', Icons.category, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Avg Rate', '15.5%', Icons.percent, Colors.orange)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Exempt Items', '1', Icons.free_breakfast, Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Luxury Tax', '28%', Icons.diamond, Colors.red)),
            ],
          ),
          const SizedBox(height: 32),
          
          // Rate Distribution
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pie_chart, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'GST Rate Distribution',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  _buildRateDistributionBar('0%', 1, Colors.green, 8),
                  const SizedBox(height: 12),
                  _buildRateDistributionBar('5%', 1, Colors.blue, 8),
                  const SizedBox(height: 12),
                  _buildRateDistributionBar('12%', 3, Colors.orange, 8),
                  const SizedBox(height: 12),
                  _buildRateDistributionBar('18%', 2, Colors.purple, 8),
                  const SizedBox(height: 12),
                  _buildRateDistributionBar('28%', 1, Colors.red, 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Recent Changes
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.update, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Recent Rate Changes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  _buildChangeItem('Textiles', '12% → 5%', 'Reduced', Colors.green),
                  const SizedBox(height: 12),
                  _buildChangeItem('Electronics', '18% → 12%', 'Reduced', Colors.green),
                  const SizedBox(height: 12),
                  _buildChangeItem('Luxury Cars', '28% → 31%', 'Increased', Colors.red),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRateDistributionBar(String rate, int count, Color color, int total) {
    double percentage = (count / total) * 100;
    
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            rate,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 8,
                width: MediaQuery.of(context).size.width * (percentage / 100) * 0.6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$count item${count == 1 ? '' : 's'}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildChangeItem(String item, String change, String type, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            type == 'Reduced' ? Icons.trending_down : Icons.trending_up,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  change,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              type,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUpdatesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Latest Updates',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                _buildUpdateItem(
                  'GST Rate Revision',
                  'Textile GST rate reduced from 12% to 5% effective from Jan 1, 2024',
                  '2 days ago',
                  Icons.shopping_bag,
                  Colors.green,
                ),
                const SizedBox(height: 16),
                
                _buildUpdateItem(
                  'New HSN Codes',
                  'Added new HSN codes for electric vehicles and renewable energy equipment',
                  '1 week ago',
                  Icons.electric_car,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                
                _buildUpdateItem(
                  'Compliance Update',
                  'New GSTR-1 filing requirements for businesses with turnover above 5 crores',
                  '2 weeks ago',
                  Icons.description,
                  Colors.orange,
                ),
                const SizedBox(height: 16),
                
                _buildUpdateItem(
                  'Rate Clarification',
                  'Clarification issued on GST rates for online gaming and betting services',
                  '3 weeks ago',
                  Icons.games,
                  Colors.purple,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildUpdateItem(String title, String description, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getRateLabel(int rate) {
    switch (rate) {
      case 0: return 'Exempt';
      case 5: return 'Essential';
      case 12: return 'Standard';
      case 18: return 'Standard+';
      case 28: return 'Luxury';
      default: return 'Other';
    }
  }
}

class GSTRateItem {
  final String category;
  final String description;
  final int rate;
  final Color color;
  
  GSTRateItem(this.category, this.description, this.rate, this.color);
}
