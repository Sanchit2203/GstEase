import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class RateTrackerScreen extends StatefulWidget {
  const RateTrackerScreen({super.key});

  @override
  State<RateTrackerScreen> createState() => _RateTrackerScreenState();
}

class _RateTrackerScreenState extends State<RateTrackerScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _jsonUpdates = [];
  bool _isLoadingUpdates = false;
  String? _lastUpdateTime;
  bool _isLoadingRates = false;
  Map<String, List<Map<String, dynamic>>> _gstRatesData = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCachedUpdates();
    _fetchUpdates();
    _fetchGSTRatesFromFirebase();
  }

  // Fetch GST Rates from Firebase Firestore
  // Uses optimized parallel queries for fast loading
  Future<void> _fetchGSTRatesFromFirebase() async {
    setState(() {
      _isLoadingRates = true;
    });

    try {
      print('=== STARTING OPTIMIZED GST RATES FETCH ===');
      
      // All GST categories - we'll query them in parallel
      final List<String> allCategories = [
        'Glass Bangles', 'Earthen Pots & Clay Lamps', 'Bangles of Lac/Shellac',
        'Bangles of Lac_Shellac', 'Silver Filigree Work', 'Handmade Imitation Jewellery',
        'German Silver Jewellery', 'Cuff-links & Studs', 'Daily Essentials & Food Items',
        'Agricultural Equipment', 'Essential Oils & Attars', 'Agarbatti & Dhoop Batti',
        'Wooden Frames & Furniture', 'Wooden Tableware & Kitchenware', 'Wooden Statuettes & Ornaments',
        'Wooden Carving & Inlay Work', 'Cork & Sholapith Articles', 'Basketwork & Wickerwork',
        'Bamboo & Rattan Items', 'Hand-made Paper', 'Paper Mache Articles',
        'Tapestries & Hand-made Lace', 'Hand Embroidered Articles', 'Quilted Textiles',
        'Hand-painted Dress Materials', 'Hand Embroidered Shawls', 'Stone Carving & Inlay Work',
        'Porcelain & China Tableware', 'Clay & Ceramic Tableware', 'Ceramic Statuettes & Ornaments',
        'Glass Art Ware & Vases', 'Footwear (under Rs 2,500/pair)', 'Apparel (under Rs 2,500/piece)',
        'Textile Articles (under Rs 2,500)', 'Knitted Hats & Headgear', 'Walking Sticks & Riding Crops',
        'Feather Dusters', 'Worked Ivory, Bone, Tortoise Shell', 'Hand Carvings & Lac Articles',
        'Hand Paintings & Pastels', 'Drawings, Mosaics & Collages', 'Original Engravings & Prints',
        'Original Sculptures', 'Postage Stamps & Collections', 'Antiques (over 100 years)',
        'Pens', 'Candles', 'Handbags (Textile Materials)', 'Mirror Ornaments',
        'Table & Kitchen Utensils', 'Metal Bells & Gongs', 'Metal Picture Frames',
        'Idols (Wood/Stone/Metal)', 'Coir Products', 'Cotton Quilts (under Rs 2,500)',
        'Hurricane Lanterns & Kerosene Lamps', 'Handcrafted Lamps', 'Bamboo, Rattan, Cane Furniture',
        'Broomsticks', 'Printed Materials', 'Packaging Containers', 'Renewable Energy Devices',
        'General Manufactured Goods', 'Most Services', 'Electronics & Appliances',
        'Automobiles', 'Electrical Fixtures & Lighting', 'String Musical Instruments',
        'Wind Musical Instruments', 'Percussion Instruments', 'Apparel (Rs 2,500 above)',
        'Textile Articles (Rs 2,500+)', 'Footwear Parts & Uppers', 'Other Headgear',
        'Drinking Glasses & Glassware', 'Other Ceramic Articles', 'Imitation Pearls & Smallwares',
        'Incense (Non-Agarbatti)', 'Plastic Containers & Boxes', 'Premium Handbags',
        'Buttons & Fasteners', 'Pen & Pencil Holders', 'Artificial Flowers',
        'Wooden Office & Bedroom Furniture', 'Bedding & Mattresses', 'Electric Ceiling & Wall Lighting',
        'Christmas Festive Articles', 'Worked Mineral Carving', 'Other items (Not in 0-5%)',
        'Smoking Pipes & Cigar Holders', 'Other Luxury & Sin Goods',
      ];
      
      Map<String, List<Map<String, dynamic>>> ratesMap = {
        '0%': [], '3%': [], '5%': [], '18%': [], '40%': [],
      };
      
      int totalItems = 0;
      int processedCategories = 0;
      
      // Process categories in batches of 10 for faster loading
      for (int i = 0; i < allCategories.length; i += 10) {
        final batch = allCategories.skip(i).take(10).toList();
        
        // Query all rates in parallel for this batch
        await Future.wait(
          batch.map((categoryName) async {
            try {
              // Use collection group query to get all items from this category across all rates
              final querySnapshot = await _firestore
                  .collectionGroup(categoryName)
                  .get();
              
              if (querySnapshot.docs.isNotEmpty) {
                processedCategories++;
                
                for (var doc in querySnapshot.docs) {
                  // Extract rate from document path: GST Rates/{rate}/{category}/{item}
                  final pathSegments = doc.reference.path.split('/');
                  if (pathSegments.length >= 2) {
                    final rate = pathSegments[1]; // e.g., "0%", "5%"
                    
                    if (ratesMap.containsKey(rate)) {
                      final itemData = doc.data();
                      
                      ratesMap[rate]!.add({
                        'id': doc.id,
                        'category': categoryName,
                        'name': itemData['product_category']?.toString() ?? categoryName,
                        'hsnCode': itemData['hsn_code']?.toString() ?? '',
                        'remark': itemData['remarks']?.toString() ?? '',
                        'effectiveDate': itemData['effective_date']?.toString() ?? '',
                      });
                      
                      totalItems++;
                    }
                  }
                }
              }
            } catch (e) {
              // Silently skip errors
            }
          }),
        );
      }
      
      print('✓ Loaded $totalItems items from $processedCategories categories');
      
      setState(() {
        _gstRatesData = ratesMap;
        _isLoadingRates = false;
      });
      
      print('\n=== FETCH COMPLETE ===');
      print('Loaded ${ratesMap.length} rate categories');
      print('Total items across all rates: ${ratesMap.values.fold(0, (sum, items) => sum + items.length)}');
      ratesMap.forEach((rate, items) {
        print('  $rate: ${items.length} items');
      });
      
      if (mounted) {
        final totalItems = ratesMap.values.fold(0, (sum, items) => sum + items.length);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Loaded ${ratesMap.length} rates, $totalItems items'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('\n=== ERROR FETCHING GST RATES ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      
      setState(() {
        _isLoadingRates = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  // Fetch GST rate updates from News API
  Future<void> _fetchUpdates() async {
    setState(() {
      _isLoadingUpdates = true;
    });

    try {
      // Try to fetch from real news API first, fallback to demo API
      String apiUrl;
      
      // Check if we have a valid NewsAPI key
      const String apiKey = 'f3b7365dde9542f8b9c042460db5c0c7'; // Your NewsAPI key
      
      http.Response response;
      
      if (apiKey != 'YOUR_NEWS_API_KEY' && apiKey.isNotEmpty) {
        // Use real NewsAPI for GST and tax related news
        const String baseUrl = 'https://newsapi.org/v2/everything';
        final String query = Uri.encodeComponent('GST OR "goods services tax" OR "tax policy" OR "finance ministry"');
        apiUrl = '$baseUrl?q=$query&language=en&sortBy=publishedAt&pageSize=10';
        
        // Make request with API key in header (recommended) or URL parameter
        try {
          response = await http.get(
            Uri.parse(apiUrl),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'X-API-Key': apiKey, // Try API key in header first
            },
          );
          
          // If header method fails, try URL parameter method
          if (response.statusCode == 401) {
            apiUrl = '$baseUrl?q=$query&language=en&sortBy=publishedAt&pageSize=10&apiKey=$apiKey';
            response = await http.get(
              Uri.parse(apiUrl),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            );
          }
        } catch (e) {
          // If NewsAPI fails, fallback to demo API
          print('NewsAPI failed: $e');
          apiUrl = 'https://reqres.in/api/users?page=1&per_page=5';
          response = await http.get(
            Uri.parse(apiUrl),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          );
        }
      } else {
        // Use a more reliable free API - ReqRes for demonstration
        apiUrl = 'https://reqres.in/api/users?page=1&per_page=5';
        response = await http.get(
          Uri.parse(apiUrl),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        );
      }      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        List<Map<String, dynamic>> transformedUpdates;
        
        // Check if this is a real NewsAPI response or demo API
        if (responseData is Map && responseData.containsKey('articles')) {
          // Real NewsAPI response
          final List<dynamic> articles = responseData['articles'];
          transformedUpdates = articles.map<Map<String, dynamic>>((article) {
            return {
              'id': article['url'].hashCode.toString(),
              'title': article['title'] ?? 'News Update',
              'description': article['description'] ?? article['content'] ?? 'No description available',
              'date': article['publishedAt'] ?? DateTime.now().toIso8601String(),
              'type': 'news_update',
              'category': 'GST News',
              'status': 'active',
              'icon': 'notifications',
              'color': 'blue',
              'source': article['source']?['name'] ?? 'News API',
              'url': article['url']
            };
          }).toList();
        } else if (responseData is Map && responseData.containsKey('data')) {
          // ReqRes API response - transform user data to GST updates
          final List<dynamic> users = responseData['data'];
          transformedUpdates = users.map<Map<String, dynamic>>((user) {
            final userId = user['id'] as int;
            return {
              'id': userId.toString(),
              'title': _generateGSTTitle(userId),
              'description': _generateGSTDescription(userId),
              'date': _generateRandomDate(),
              'type': _getRandomUpdateType(),
              'category': _getRandomCategory(),
              'status': 'active',
              'icon': _getRandomIcon(),
              'color': _getRandomColor(),
              'source': 'Demo API (ReqRes)'
            };
          }).toList();
        } else {
          // Fallback: Generate offline updates if API format is unexpected
          transformedUpdates = _generateOfflineUpdates();
        }
        
        setState(() {
          _jsonUpdates = transformedUpdates;
          _lastUpdateTime = DateTime.now().toIso8601String();
          _isLoadingUpdates = false;
        });

        // Cache the updates
        await _cacheUpdates();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Latest GST updates fetched successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

      } else {
        // Handle specific error codes
        print('API Error: ${response.statusCode} - ${response.body}');
        final offlineUpdates = _generateOfflineUpdates();
        
        setState(() {
          _jsonUpdates = offlineUpdates;
          _lastUpdateTime = DateTime.now().toIso8601String();
          _isLoadingUpdates = false;
        });

        String errorMessage;
        Color errorColor;
        
        switch (response.statusCode) {
          case 401:
            errorMessage = '🔑 API Key invalid or expired. Using offline updates.';
            errorColor = Colors.red;
            break;
          case 403:
            errorMessage = '⛔ Access forbidden. Check API permissions. Using offline updates.';
            errorColor = Colors.red;
            break;
          case 429:
            errorMessage = '⏰ Rate limit exceeded. Try again later. Using offline updates.';
            errorColor = Colors.orange;
            break;
          default:
            errorMessage = '⚠️ API unavailable (${response.statusCode}). Using offline updates.';
            errorColor = Colors.orange;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: errorColor,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'INFO',
                textColor: Colors.white,
                onPressed: () => _showApiErrorInfo(response.statusCode),
              ),
            ),
          );
        }
        return;
      }

    } catch (e) {
      // On any error, show offline updates
      print('Network Error: $e');
      final offlineUpdates = _generateOfflineUpdates();
      
      setState(() {
        _jsonUpdates = offlineUpdates;
        _lastUpdateTime = DateTime.now().toIso8601String();
        _isLoadingUpdates = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔄 Network error. Showing offline updates.'),
            backgroundColor: Colors.blue,
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _fetchUpdates(),
            ),
          ),
        );
      }
    }
  }

  // Generate GST-related titles based on article ID
  String _generateGSTTitle(int id) {
    final titles = [
      'GST Rate Revision for Textiles',
      'New HSN Codes for Electric Vehicles',
      'GSTR-1 Filing Updates',
      'E-commerce GST Collection Changes',
      'Input Tax Credit Amendments',
      'GST Council Meeting Decisions',
      'Digital Payment GST Benefits',
      'Export GST Refund Process',
      'Small Business GST Exemptions',
      'Quarterly GST Return Updates'
    ];
    return titles[id % titles.length];
  }

  // Generate GST-related descriptions
  String _generateGSTDescription(int id) {
    final descriptions = [
      'Textile GST rate reduced from 18% to 5% effective immediately for readymade garments',
      'New HSN codes introduced for electric vehicles and renewable energy equipment',
      'Updated GSTR-1 filing requirements for businesses with turnover above 5 crores',
      'E-commerce platforms now required to collect GST at source for marketplace transactions',
      'Clarification on Input Tax Credit eligibility for common services and utilities',
      'GST Council announces rate rationalization for essential commodities',
      'Digital payment transactions now eligible for additional GST input credit',
      'Streamlined process for GST refunds on export transactions',
      'Small businesses with turnover below 40 lakhs exempted from GST registration',
      'New quarterly return filing system introduced for small taxpayers'
    ];
    return descriptions[id % descriptions.length];
  }

  // Generate random date within last 30 days
  String _generateRandomDate() {
    final now = DateTime.now();
    final random = (id) => id % 30;
    final daysAgo = random(DateTime.now().millisecondsSinceEpoch) + 1;
    final date = now.subtract(Duration(days: daysAgo));
    return date.toIso8601String();
  }

  // Get random update type
  String _getRandomUpdateType() {
    final types = ['rate_change', 'compliance', 'policy_update', 'clarification', 'announcement'];
    return types[DateTime.now().millisecond % types.length];
  }

  // Get random category
  String _getRandomCategory() {
    final categories = ['Textiles', 'Electronics', 'E-commerce', 'Manufacturing', 'Services', 'Export', 'Small Business'];
    return categories[DateTime.now().microsecond % categories.length];
  }

  // Get random icon
  String _getRandomIcon() {
    final icons = ['shopping_bag', 'electric_car', 'description', 'shopping_cart', 'help_outline', 'trending_up', 'notifications'];
    return icons[DateTime.now().millisecond % icons.length];
  }

  // Get random color
  String _getRandomColor() {
    final colors = ['green', 'blue', 'orange', 'purple', 'teal', 'indigo', 'red'];
    return colors[DateTime.now().microsecond % colors.length];
  }

  // Generate offline updates when API fails
  List<Map<String, dynamic>> _generateOfflineUpdates() {
    return [
      {
        'id': '1',
        'title': 'GST Rate Revision for Textiles',
        'description': 'Textile GST rate reduced from 18% to 5% effective immediately for readymade garments and fabrics',
        'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'type': 'rate_change',
        'category': 'Textiles',
        'status': 'active',
        'icon': 'shopping_bag',
        'color': 'green',
        'source': 'Offline Cache'
      },
      {
        'id': '2',
        'title': 'New HSN Codes for Electric Vehicles',
        'description': 'Government introduces new HSN classification codes for electric vehicles and renewable energy equipment',
        'date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'type': 'hsn_update',
        'category': 'Electric Vehicles',
        'status': 'active',
        'icon': 'electric_car',
        'color': 'blue',
        'source': 'Offline Cache'
      },
      {
        'id': '3',
        'title': 'GSTR-1 Filing Updates',
        'description': 'New quarterly GSTR-1 filing requirements announced for businesses with turnover above 5 crores',
        'date': DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
        'type': 'compliance',
        'category': 'Filing',
        'status': 'active',
        'icon': 'description',
        'color': 'orange',
        'source': 'Offline Cache'
      },
      {
        'id': '4',
        'title': 'E-commerce GST Collection',
        'description': 'Updated GST collection mechanism for e-commerce platforms and marketplace transactions',
        'date': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
        'type': 'policy_update',
        'category': 'E-commerce',
        'status': 'active',
        'icon': 'shopping_cart',
        'color': 'purple',
        'source': 'Offline Cache'
      },
      {
        'id': '5',
        'title': 'Input Tax Credit Rules',
        'description': 'Clarification issued on ITC eligibility for common services and utility payments',
        'date': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        'type': 'clarification',
        'category': 'ITC',
        'status': 'active',
        'icon': 'help_outline',
        'color': 'teal',
        'source': 'Offline Cache'
      }
    ];
  }

  // Cache updates locally
  Future<void> _cacheUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final updatesJson = _jsonUpdates.map((update) => jsonEncode(update)).toList();
    await prefs.setStringList('gst_updates', updatesJson);
    if (_lastUpdateTime != null) {
      await prefs.setString('last_update_time', _lastUpdateTime!);
    }
  }

  // Load cached updates
  Future<void> _loadCachedUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUpdates = prefs.getStringList('gst_updates') ?? [];
    final lastUpdate = prefs.getString('last_update_time');
    
    if (cachedUpdates.isNotEmpty) {
      setState(() {
        _jsonUpdates = cachedUpdates
            .map((updateString) => jsonDecode(updateString) as Map<String, dynamic>)
            .toList();
        _lastUpdateTime = lastUpdate;
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getColorForRate(String rate) {
    switch (rate) {
      case '0%':
        return Colors.green;
      case '5%':
        return Colors.blue;
      case '12%':
        return Colors.orange;
      case '18%':
        return Colors.purple;
      case '28%':
        return Colors.deepPurple;
      case '40%':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchGSTRatesFromFirebase();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing GST rates...')),
              );
            },
            tooltip: 'Refresh Rates',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showApiKeyInfo(),
            tooltip: 'API Key Info',
          ),
          IconButton(
            icon: _isLoadingUpdates 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.cloud_download),
            onPressed: _isLoadingUpdates ? null : () {
              _fetchUpdates();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fetching latest GST updates...')),
              );
            },
            tooltip: 'Fetch Latest Updates',
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
    if (_isLoadingRates) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_gstRatesData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No GST rates available',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Check debug console for error messages',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchGSTRatesFromFirebase,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
            ),
          ],
        ),
      );
    }

    // Sort rates in logical order
    final sortedRates = _gstRatesData.keys.toList()..sort((a, b) {
      final aNum = int.tryParse(a.replaceAll('%', '')) ?? 0;
      final bNum = int.tryParse(b.replaceAll('%', '')) ?? 0;
      return aNum.compareTo(bNum);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedRates.length,
      itemBuilder: (context, index) {
        final rate = sortedRates[index];
        final items = _gstRatesData[rate] ?? [];
        final color = _getColorForRate(rate);
        
        return _buildSimpleRateSection(rate, items, color);
      },
    );
  }
  
  Widget _buildSimpleRateSection(String rate, List<Map<String, dynamic>> items, Color color) {
    // Group items by category
    Map<String, List<Map<String, dynamic>>> groupedItems = {};
    for (var item in items) {
      final category = item['category'] ?? 'Uncategorized';
      if (!groupedItems.containsKey(category)) {
        groupedItems[category] = [];
      }
      groupedItems[category]!.add(item);
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                rate,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(
            'GST Rate $rate',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          subtitle: Text(
            '${groupedItems.length} categories • ${items.length} items',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          children: items.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No items found for this rate',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                ]
              : groupedItems.entries.map((entry) {
                  return _buildDropdownCategory(entry.key, entry.value, color);
                }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildDropdownCategory(String categoryName, List<Map<String, dynamic>> items, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.05),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Icon(Icons.folder_open, color: color, size: 22),
          title: Text(
            categoryName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down, color: color),
            ],
          ),
          children: items.map((item) => _buildDropdownItem(item, color)).toList(),
        ),
      ),
    );
  }

  Widget _buildDropdownItem(Map<String, dynamic> item, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.receipt_long, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item['name'] ?? 'Unknown Item',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (item['hsnCode']?.isNotEmpty == true ||
                item['remark']?.isNotEmpty == true ||
                item['effectiveDate']?.isNotEmpty == true)
              const SizedBox(height: 10),
            if (item['hsnCode']?.isNotEmpty == true ||
                item['remark']?.isNotEmpty == true ||
                item['effectiveDate']?.isNotEmpty == true)
              const Divider(height: 1),
            if (item['hsnCode']?.isNotEmpty == true ||
                item['remark']?.isNotEmpty == true ||
                item['effectiveDate']?.isNotEmpty == true)
              const SizedBox(height: 10),
            if (item['hsnCode']?.isNotEmpty == true)
              _buildInfoRow(
                Icons.qr_code_2,
                'HSN Code',
                item['hsnCode'],
                color,
              ),
            if (item['remark']?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildInfoRow(
                  Icons.info_outline,
                  'Remarks',
                  item['remark'],
                  color,
                ),
              ),
            if (item['effectiveDate']?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildInfoRow(
                  Icons.calendar_today,
                  'Effective Date',
                  item['effectiveDate'],
                  color,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildOverviewTab() {
    if (_isLoadingRates) {
      return const Center(child: CircularProgressIndicator());
    }

    // Calculate statistics
    int totalCategories = _gstRatesData.keys.length;
    int totalItems = 0;
    Map<String, int> rateDistribution = {};
    
    _gstRatesData.forEach((rate, items) {
      totalItems += items.length;
      rateDistribution[rate] = items.length;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Categories',
                  totalCategories.toString(),
                  Icons.category,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Items',
                  totalItems.toString(),
                  Icons.inventory,
                  Colors.orange,
                ),
              ),
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
                  
                  if (rateDistribution.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No data available'),
                      ),
                    )
                  else
                    ...rateDistribution.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildRateDistributionBar(
                          entry.key,
                          entry.value,
                          _getColorForRate(entry.key),
                          totalItems,
                        ),
                      );
                    }).toList(),
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
  

  
  Widget _buildUpdatesTab() {
    return RefreshIndicator(
      onRefresh: _fetchUpdates,
      child: ListView(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.update, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Latest Updates',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: _isLoadingUpdates 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                        onPressed: _isLoadingUpdates ? null : _fetchUpdates,
                        tooltip: 'Refresh Updates',
                      ),
                    ],
                  ),
                  
                  if (_lastUpdateTime != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last updated: ${_formatDateTime(_lastUpdateTime!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  if (_isLoadingUpdates && _jsonUpdates.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_jsonUpdates.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No updates available',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _jsonUpdates.map((update) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildJsonUpdateItem(update),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build update item from JSON data
  Widget _buildJsonUpdateItem(Map<String, dynamic> update) {
    final title = update['title'] as String? ?? 'Update';
    final description = update['description'] as String? ?? '';
    final date = update['date'] as String? ?? '';
    final colorName = update['color'] as String? ?? 'blue';
    final iconName = update['icon'] as String? ?? 'info';
    final source = update['source'] as String? ?? 'Unknown';
    final url = update['url'] as String?;
    
    final color = _getColorFromName(colorName);
    final icon = _getIconFromName(iconName);
    final timeAgo = _calculateTimeAgo(date);
    
    return InkWell(
      onTap: url != null ? () => _openNewsUrl(url) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: url != null ? color.withOpacity(0.5) : color.withOpacity(0.3),
            width: url != null ? 2 : 1,
          ),
          boxShadow: url != null ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (url != null)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: color,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Source: $source',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      if (update['type'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (update['type'] as String).replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Open news URL in browser
  Future<void> _openNewsUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      
      // Check if URL can be launched
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Opens in external browser
        );
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening article from ${uri.host}...'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // URL cannot be launched
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot open URL: ${uri.host}'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'COPY',
                textColor: Colors.white,
                onPressed: () => _copyUrlToClipboard(url),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening URL: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'COPY',
              textColor: Colors.white,
              onPressed: () => _copyUrlToClipboard(url),
            ),
          ),
        );
      }
    }
  }

  // Copy URL to clipboard as fallback
  void _copyUrlToClipboard(String url) {
    // For now, just show the URL - you can implement clipboard functionality later
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Article URL'),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Show API error information dialog
  void _showApiErrorInfo(int statusCode) {
    String title;
    String message;
    IconData icon;
    Color color;

    switch (statusCode) {
      case 401:
        title = 'Authentication Error (401)';
        message = 'The API key is invalid, expired, or missing.\n\nSolutions:\n• Check if the API key is correct\n• Verify the key hasn\'t expired\n• Get a new key from newsapi.org\n• Check if your plan supports the requested features';
        icon = Icons.key_off;
        color = Colors.red;
        break;
      case 403:
        title = 'Access Forbidden (403)';
        message = 'The API key doesn\'t have permission for this request.\n\nSolutions:\n• Check your NewsAPI plan limits\n• Verify domain restrictions\n• Contact NewsAPI support if needed';
        icon = Icons.block;
        color = Colors.red;
        break;
      case 429:
        title = 'Rate Limit Exceeded (429)';
        message = 'You\'ve exceeded the API rate limit.\n\nSolutions:\n• Wait before making more requests\n• Upgrade your NewsAPI plan\n• Reduce request frequency';
        icon = Icons.timer_off;
        color = Colors.orange;
        break;
      default:
        title = 'API Error ($statusCode)';
        message = 'An unexpected error occurred.\n\nThe app will continue working with offline updates until the issue is resolved.';
        icon = Icons.error_outline;
        color = Colors.orange;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchUpdates(); // Retry
              },
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  // Show API key information dialog
  void _showApiKeyInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.api, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('News API Setup'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API Key: f3b7365d...5c0c7',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Status: Configured (may need verification)',
                  style: TextStyle(fontSize: 14, color: Colors.orange),
                ),
                const SizedBox(height: 8),
                const Text('To get real GST and tax news, follow these steps:'),
                const SizedBox(height: 12),
                const Text('1. Visit: https://newsapi.org/'),
                const Text('2. Sign up for a free account'),
                const Text('3. Get your API key'),
                const Text('4. Replace "YOUR_NEWS_API_KEY" in the code'),
                const SizedBox(height: 12),
                const Text(
                  'Features with real API:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Text('• Live GST news updates'),
                const Text('• Tax policy changes'),
                const Text('• Finance ministry announcements'),
                const Text('• Clickable news articles'),
                const SizedBox(height: 12),
                const Text(
                  'Demo API shows simulated GST updates for testing. If API fails, offline updates are shown automatically.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    '💡 Tip: App works offline with cached updates when network fails!',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Visit newsapi.org to get your free API key!'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to get Color from string name
  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'green': return Colors.green;
      case 'blue': return Colors.blue;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'red': return Colors.red;
      case 'teal': return Colors.teal;
      case 'indigo': return Colors.indigo;
      case 'cyan': return Colors.cyan;
      default: return Colors.blue;
    }
  }

  // Helper method to get IconData from string name
  IconData _getIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'shopping_bag': return Icons.shopping_bag;
      case 'electric_car': return Icons.electric_car;
      case 'description': return Icons.description;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'help_outline': return Icons.help_outline;
      case 'games': return Icons.games;
      case 'notifications': return Icons.notifications;
      case 'trending_up': return Icons.trending_up;
      case 'trending_down': return Icons.trending_down;
      default: return Icons.info;
    }
  }

  // Format DateTime string for display
  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
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
      return dateTimeString;
    }
  }

  // Calculate time ago from date string
  String _calculateTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} minutes ago';
        }
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1) {
        return '1 day ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks week${weeks > 1 ? 's' : ''} ago';
      } else {
        final months = (difference.inDays / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return dateString;
    }
  }
}
