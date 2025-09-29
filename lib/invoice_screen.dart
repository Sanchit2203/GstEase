import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _gstinController = TextEditingController();
  
  // Invoice items
  List<InvoiceItem> _invoiceItems = [];
  
  // Invoice totals
  double _subtotal = 0.0;
  double _totalGst = 0.0;
  double _grandTotal = 0.0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _addInvoiceItem(); // Add first item by default
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerAddressController.dispose();
    _gstinController.dispose();
    super.dispose();
  }
  
  void _addInvoiceItem() {
    setState(() {
      _invoiceItems.add(InvoiceItem());
    });
  }
  
  void _removeInvoiceItem(int index) {
    if (_invoiceItems.length > 1) {
      setState(() {
        _invoiceItems.removeAt(index);
        _calculateTotals();
      });
    }
  }
  
  void _calculateTotals() {
    double subtotal = 0.0;
    double totalGst = 0.0;
    
    for (var item in _invoiceItems) {
      if (item.isValid()) {
        double itemTotal = item.quantity * item.rate;
        double gst = (itemTotal * item.gstRate) / 100;
        subtotal += itemTotal;
        totalGst += gst;
      }
    }
    
    setState(() {
      _subtotal = subtotal;
      _totalGst = totalGst;
      _grandTotal = subtotal + totalGst;
    });
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
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Invoice Generator'),
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
            Tab(icon: Icon(Icons.person), text: 'Customer'),
            Tab(icon: Icon(Icons.list), text: 'Items'),
            Tab(icon: Icon(Icons.receipt), text: 'Preview'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            tooltip: 'Generate PDF',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF generation coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.blue),
            tooltip: 'Share Invoice',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCustomerTab(),
          _buildItemsTab(),
          _buildPreviewTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _addInvoiceItem,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
    );
  }
  
  Widget _buildCustomerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Customer Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name *',
                        prefixIcon: Icon(Icons.person),
                        hintText: 'Enter customer name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Customer name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _customerEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email),
                        hintText: 'Enter email address',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && !value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _gstinController,
                      decoration: const InputDecoration(
                        labelText: 'GSTIN',
                        prefixIcon: Icon(Icons.receipt_long),
                        hintText: 'Enter GSTIN number',
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _customerAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on),
                        hintText: 'Enter complete address',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildItemsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Invoice Items',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.orange.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _invoiceItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildItemCard(index);
                    },
                  ),
                  
                  if (_invoiceItems.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    _buildTotalsSummary(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildItemCard(int index) {
    final item = _invoiceItems[index];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Item ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_invoiceItems.length > 1)
                IconButton(
                  onPressed: () => _removeInvoiceItem(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove Item',
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          TextFormField(
            initialValue: item.description,
            decoration: const InputDecoration(
              labelText: 'Item Description',
              hintText: 'Enter item description',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              item.description = value;
            },
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.quantity > 0 ? item.quantity.toString() : '',
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: '1',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  onChanged: (value) {
                    item.quantity = double.tryParse(value) ?? 0.0;
                    _calculateTotals();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: item.rate > 0 ? item.rate.toString() : '',
                  decoration: const InputDecoration(
                    labelText: 'Rate (₹)',
                    hintText: '0.00',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  onChanged: (value) {
                    item.rate = double.tryParse(value) ?? 0.0;
                    _calculateTotals();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<double>(
                  value: item.gstRate > 0 ? item.gstRate : null,
                  decoration: const InputDecoration(
                    labelText: 'GST %',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [0, 5, 12, 18, 28].map((rate) {
                    return DropdownMenuItem(
                      value: rate.toDouble(),
                      child: Text('$rate%'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    item.gstRate = value ?? 0.0;
                    _calculateTotals();
                  },
                ),
              ),
            ],
          ),
          
          if (item.isValid()) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Item Total:'),
                  Text(
                    '₹ ${((item.quantity * item.rate) + ((item.quantity * item.rate * item.gstRate) / 100)).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTotalsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal:', _subtotal),
          const SizedBox(height: 8),
          _buildTotalRow('Total GST:', _totalGst),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _buildTotalRow('Grand Total:', _grandTotal, isGrandTotal: true),
        ],
      ),
    );
  }
  
  Widget _buildTotalRow(String label, double amount, {bool isGrandTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isGrandTotal ? 18 : 16,
            fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          '₹ ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isGrandTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isGrandTotal ? Colors.green.shade700 : Colors.black87,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white, size: 32),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INVOICE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Date: ${DateTime.now().toString().split(' ')[0]}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Customer Info
              if (_customerNameController.text.isNotEmpty) ...[
                const Text(
                  'Bill To:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_customerNameController.text, style: const TextStyle(fontSize: 16)),
                if (_customerEmailController.text.isNotEmpty)
                  Text(_customerEmailController.text, style: const TextStyle(color: Colors.grey)),
                if (_gstinController.text.isNotEmpty)
                  Text('GSTIN: ${_gstinController.text}', style: const TextStyle(color: Colors.grey)),
                if (_customerAddressController.text.isNotEmpty)
                  Text(_customerAddressController.text, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
              ],
              
              // Items Table
              const Text(
                'Items:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('GST%', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    // Items
                    for (int i = 0; i < _invoiceItems.length; i++)
                      if (_invoiceItems[i].isValid())
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text(_invoiceItems[i].description)),
                              Expanded(child: Text(_invoiceItems[i].quantity.toString())),
                              Expanded(child: Text('₹${_invoiceItems[i].rate.toStringAsFixed(2)}')),
                              Expanded(child: Text('${_invoiceItems[i].gstRate}%')),
                              Expanded(child: Text('₹${((_invoiceItems[i].quantity * _invoiceItems[i].rate) + ((_invoiceItems[i].quantity * _invoiceItems[i].rate * _invoiceItems[i].gstRate) / 100)).toStringAsFixed(2)}')),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Totals
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildTotalRow('Subtotal:', _subtotal),
                    const SizedBox(height: 8),
                    _buildTotalRow('Total GST:', _totalGst),
                    const SizedBox(height: 12),
                    const Divider(thickness: 2),
                    const SizedBox(height: 12),
                    _buildTotalRow('Grand Total:', _grandTotal, isGrandTotal: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InvoiceItem {
  String description = '';
  double quantity = 0.0;
  double rate = 0.0;
  double gstRate = 0.0;
  
  bool isValid() {
    return description.isNotEmpty && quantity > 0 && rate > 0;
  }
}
