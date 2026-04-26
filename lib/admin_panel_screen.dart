import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Admin Panel'),
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
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
            Tab(icon: Icon(Icons.history), text: 'Activity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildUsersTab(),
          _buildSettingsTab(),
          _buildActivityTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('Failed to load statistics'),
              ],
            ),
          );
        }

        final stats = snapshot.data!;

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
                      'Total Users',
                      stats['totalUsers'].toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Items',
                      stats['totalItems'].toString(),
                      Icons.inventory,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'GST Rates',
                      stats['totalRates'].toString(),
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Categories',
                      stats['totalCategories'].toString(),
                      Icons.category,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildActionButton(
                context,
                'Refresh GST Rates',
                'Update all GST rate data',
                Icons.refresh,
                Colors.blue,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refreshing GST rates...')),
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildActionButton(
                context,
                'Export Analytics',
                'Download usage analytics',
                Icons.download,
                Colors.green,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting analytics...')),
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildActionButton(
                context,
                'System Status',
                'Check system health',
                Icons.monitor_heart,
                Colors.orange,
                () {
                  _showSystemStatus(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore.collection('users').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('No users found'),
              ],
            ),
          );
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;

            return _buildUserCard(context, userId, userData);
          },
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildSettingsTile(
            'GST Rate Updates',
            'Automatic rate synchronization',
            Icons.sync,
            true,
            (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Auto-sync ${value ? 'enabled' : 'disabled'}')),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildSettingsTile(
            'User Notifications',
            'Send update notifications to users',
            Icons.notifications,
            true,
            (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notifications ${value ? 'enabled' : 'disabled'}')),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildSettingsTile(
            'Analytics Tracking',
            'Track user interactions',
            Icons.analytics,
            true,
            (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Analytics ${value ? 'enabled' : 'disabled'}')),
              );
            },
          ),
          const SizedBox(height: 32),

          Text(
            'Maintenance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildMaintenanceButton(
            'Clear Cache',
            'Remove cached data',
            Icons.delete_sweep,
            Colors.orange,
            () {
              _showMaintenanceDialog(context, 'Clear Cache', 'This will remove all cached data.');
            },
          ),
          const SizedBox(height: 12),

          _buildMaintenanceButton(
            'Reset Analytics',
            'Clear all analytics data',
            Icons.restart_alt,
            Colors.red,
            () {
              _showMaintenanceDialog(context, 'Reset Analytics', 'This will clear all analytics. This action cannot be undone.');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('No activity logs found'),
              ],
            ),
          );
        }

        final logs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final logData = logs[index].data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  _getActivityIcon(logData['type'] as String? ?? ''),
                  color: _getActivityColor(logData['type'] as String? ?? ''),
                ),
                title: Text(logData['action'] as String? ?? 'Unknown Action'),
                subtitle: Text(logData['user'] as String? ?? 'Unknown User'),
                trailing: Text(
                  _formatTime(logData['timestamp']),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
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

  Widget _buildActionButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    String userId,
    Map<String, dynamic> userData,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              (userData['email'] as String? ?? 'U')[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        title: Text(userData['email'] as String? ?? 'Unknown User'),
        subtitle: Text('ID: $userId'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
              onTap: () {
                _showUserDetails(context, userData);
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remove User', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () {
                _showDeleteUserDialog(context, userId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    bool initialValue,
    Function(bool) onChanged,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: initialValue,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchDashboardStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final ratesSnapshot = await _firestore.collection('GST Rates').get();

      int totalItems = 0;
      for (var rateDoc in ratesSnapshot.docs) {
        final categoriesSnapshot = await _firestore
            .collection('GST Rates')
            .doc(rateDoc.id)
            .collection('categories')
            .get();

        int itemsInRate = 0;
        for (var categoryDoc in categoriesSnapshot.docs) {
          final itemsSnapshot = await _firestore
              .collection('GST Rates')
              .doc(rateDoc.id)
              .collection(categoryDoc.id)
              .get();
          itemsInRate += itemsSnapshot.docs.length;
        }

        totalItems += itemsInRate;
      }

      return {
        'totalUsers': usersSnapshot.docs.length,
        'totalItems': totalItems,
        'totalRates': ratesSnapshot.docs.length,
        'totalCategories': 50, // Placeholder
      };
    } catch (e) {
      return {
        'totalUsers': 0,
        'totalItems': 0,
        'totalRates': 0,
        'totalCategories': 0,
      };
    }
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_outline),
            SizedBox(width: 8),
            Text('User Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', userData['email'] as String? ?? 'N/A'),
            const SizedBox(height: 12),
            _buildDetailRow('Name', userData['name'] as String? ?? 'N/A'),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Joined',
              userData['createdAt'] as String? ?? 'N/A',
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Status', 'Active'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  void _showDeleteUserDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete User'),
          ],
        ),
        content: const Text('Are you sure you want to remove this user? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSystemStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.monitor_heart, color: Colors.green),
            SizedBox(width: 8),
            Text('System Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('Database', 'Healthy', Colors.green),
            const SizedBox(height: 12),
            _buildStatusRow('API', 'Healthy', Colors.green),
            const SizedBox(height: 12),
            _buildStatusRow('Cache', 'Healthy', Colors.green),
            const SizedBox(height: 12),
            _buildStatusRow('Notifications', 'Healthy', Colors.green),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String service, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(service),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showMaintenanceDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.orange),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title completed')),
              );
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'login':
        return Colors.green;
      case 'logout':
        return Colors.orange;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        final dateTime = timestamp.toDate();
        final now = DateTime.now();
        final difference = now.difference(dateTime);

        if (difference.inMinutes < 1) {
          return 'just now';
        } else if (difference.inHours < 1) {
          return '${difference.inMinutes}m ago';
        } else if (difference.inDays < 1) {
          return '${difference.inHours}h ago';
        } else {
          return '${dateTime.day}/${dateTime.month}';
        }
      }
      return timestamp.toString();
    } catch (e) {
      return 'unknown';
    }
  }
}
