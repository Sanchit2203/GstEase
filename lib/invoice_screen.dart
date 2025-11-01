import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
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
    
    // Generate default invoice number
    final now = DateTime.now();
    _invoiceNumberController.text = 'INV-${now.millisecondsSinceEpoch.toString().substring(8)}';
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _invoiceNumberController.dispose();
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
        subtotal += item.actualBaseAmount;
        totalGst += item.actualGstAmount;
      }
    }
    
    setState(() {
      _subtotal = subtotal;
      _totalGst = totalGst;
      _grandTotal = subtotal + totalGst;
    });
  }

  // Generate PDF document
  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final invoiceNumber = _invoiceNumberController.text.isNotEmpty 
        ? _invoiceNumberController.text 
        : 'INV-${now.millisecondsSinceEpoch.toString().substring(8)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue600,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Invoice #: $invoiceNumber',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'GSTEase',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Date: ${now.day}/${now.month}/${now.year}',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 30),
            
            // Bill To Section
            if (_customerNameController.text.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BILL TO:',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      _customerNameController.text,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (_customerEmailController.text.isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Email: ${_customerEmailController.text}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                    if (_gstinController.text.isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'GSTIN: ${_gstinController.text}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                    if (_customerAddressController.text.isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Address: ${_customerAddressController.text}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
            ],
            
            // Items Table
            pw.Text(
              'ITEMS & SERVICES',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 15),
            
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Description',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Qty',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Rate (₹)',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'GST%',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Total (₹)',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                // Items
                for (var item in _invoiceItems)
                  if (item.isValid())
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(item.description),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            item.quantity.toString(),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            item.rate.toStringAsFixed(2),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${item.gstRate}%',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            ((item.quantity * item.rate) + ((item.quantity * item.rate * item.gstRate) / 100)).toStringAsFixed(2),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
              ],
            ),
            
            pw.SizedBox(height: 30),
            
            // Totals Section
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 14)),
                      pw.Text('₹ ${_subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total GST:', style: const pw.TextStyle(fontSize: 14)),
                      pw.Text('₹ ${_totalGst.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
                    ],
                  ),
                  pw.SizedBox(height: 15),
                  pw.Container(
                    width: double.infinity,
                    height: 2,
                    color: PdfColors.blue600,
                  ),
                  pw.SizedBox(height: 15),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'GRAND TOTAL:',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.Text(
                        '₹ ${_grandTotal.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 30),
            
            // Footer
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Terms & Conditions:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '• Payment is due within 30 days of invoice date',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Late payments may incur additional charges',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• All prices are inclusive of applicable GST',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue600,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  // Generate and preview PDF
  Future<void> _generateAndPreviewPDF() async {
    if (!_validateInvoiceData()) return;
    
    try {
      final pdf = await _generatePDF();
      
      // Show PDF preview with print/share options
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Invoice_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      _showErrorDialog('Failed to generate PDF: $e');
    }
  }

  // Generate and save PDF to device
  Future<void> _generateAndSavePDF() async {
    if (!_validateInvoiceData()) return;
    
    try {
      // Request storage permission for Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showErrorDialog('Storage permission is required to save PDF files');
          return;
        }
      }
      
      final pdf = await _generatePDF();
      final bytes = await pdf.save();
      
      // Get appropriate directory for saving
      Directory? directory;
      String locationDescription;
      
      if (Platform.isAndroid) {
        // Try to use Downloads folder first
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to external storage directory
          directory = await getExternalStorageDirectory();
          directory = directory != null ? Directory('${directory.path}/Download') : null;
          if (directory != null && !await directory.exists()) {
            await directory.create(recursive: true);
          }
        }
        locationDescription = 'Downloads folder';
      } else {
        directory = await getApplicationDocumentsDirectory();
        locationDescription = 'Documents folder';
      }
      
      if (directory != null) {
        final fileName = 'Invoice_${_invoiceNumberController.text.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final filePath = '${directory.path}/$fileName';
        
        // Write PDF to file
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        // Show success message with file location
        _showSuccessDialog(
          'PDF Saved Successfully!', 
          'File saved to $locationDescription:\n\n$fileName\n\nYou can find it in your device\'s file manager.'
        );
      } else {
        _showErrorDialog('Could not access storage directory');
      }
      
    } catch (e) {
      _showErrorDialog('Failed to save PDF: ${e.toString()}');
    }
  }

  // Generate and share PDF
  Future<void> _generateAndSharePDF() async {
    if (!_validateInvoiceData()) return;
    
    try {
      final pdf = await _generatePDF();
      final bytes = await pdf.save();
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final fileName = 'Invoice_${_invoiceNumberController.text}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      
      // Write PDF to file
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      // Share the PDF file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Invoice from GSTEase',
        subject: 'Invoice - ${_customerNameController.text.isNotEmpty ? _customerNameController.text : 'Customer'}',
      );
      
    } catch (e) {
      _showErrorDialog('Failed to share PDF: $e');
    }
  }

  // Validate invoice data before PDF generation
  bool _validateInvoiceData() {
    if (_invoiceNumberController.text.isEmpty) {
      _showErrorDialog('Please enter invoice number before generating PDF');
      _tabController.animateTo(0); // Switch to customer tab
      return false;
    }
    
    if (_customerNameController.text.isEmpty) {
      _showErrorDialog('Please enter customer name before generating PDF');
      _tabController.animateTo(0); // Switch to customer tab
      return false;
    }
    
    if (_invoiceItems.isEmpty || !_invoiceItems.any((item) => item.isValid())) {
      _showErrorDialog('Please add at least one valid item before generating PDF');
      _tabController.animateTo(1); // Switch to items tab
      return false;
    }
    
    return true;
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show success dialog
  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.folder_open, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Open your file manager to view the saved PDF.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            tooltip: 'PDF Options',
            onSelected: (String value) {
              switch (value) {
                case 'preview':
                  _generateAndPreviewPDF();
                  break;
                case 'save':
                  _generateAndSavePDF();
                  break;
                case 'share':
                  _generateAndSharePDF();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'preview',
                child: Row(
                  children: [
                    Icon(Icons.preview, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Preview PDF'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.save_alt, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Save PDF'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Share PDF'),
                  ],
                ),
              ),
            ],
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
                      controller: _invoiceNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Invoice Number',
                        prefixIcon: Icon(Icons.receipt_long),
                        hintText: 'Enter invoice number',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Invoice number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
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
          
          // GST Inclusion Switch
          if (item.gstRate > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.includeGst 
                        ? 'Rate includes GST (GST will be extracted from rate)'
                        : 'Rate excludes GST (GST will be added to rate)',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: item.includeGst,
                    onChanged: (value) {
                      setState(() {
                        item.includeGst = value;
                        _calculateTotals();
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
          ],
          
          if (item.isValid()) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Base Amount:'),
                      Text(
                        '₹ ${item.actualBaseAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (item.gstRate > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('GST (${item.gstRate.toStringAsFixed(0)}%):'),
                        Text(
                          '₹ ${item.actualGstAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const Divider(height: 12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Item Total:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹ ${item.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
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
                        if (_invoiceNumberController.text.isNotEmpty)
                          Text(
                            'Invoice #: ${_invoiceNumberController.text}',
                            style: const TextStyle(color: Colors.white70),
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
              
              const SizedBox(height: 30),
              
              // PDF Action Buttons
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _generateAndPreviewPDF,
                          icon: const Icon(Icons.preview),
                          label: const Text('Preview PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _generateAndSavePDF,
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Save PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generateAndSharePDF,
                      icon: const Icon(Icons.share),
                      label: const Text('Share PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
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
  bool includeGst = false; // New field for GST inclusion
  
  bool isValid() {
    return description.isNotEmpty && quantity > 0 && rate > 0;
  }
  
  // Get the base amount without GST
  double get baseAmount => quantity * rate;
  
  // Get the GST amount
  double get gstAmount => includeGst ? 0.0 : (baseAmount * gstRate) / 100;
  
  // Get the total amount (rate is inclusive or exclusive based on includeGst)
  double get totalAmount {
    if (includeGst) {
      // Rate includes GST, so total is the entered rate
      return baseAmount;
    } else {
      // Rate is exclusive of GST, add GST to it
      return baseAmount + gstAmount;
    }
  }
  
  // Get the actual base amount for calculations
  double get actualBaseAmount {
    if (includeGst) {
      return baseAmount / (1 + (gstRate / 100));
    } else {
      return baseAmount;
    }
  }
  
  // Get the actual GST amount for calculations
  double get actualGstAmount {
    if (includeGst) {
      return baseAmount - actualBaseAmount;
    } else {
      return gstAmount;
    }
  }
}
