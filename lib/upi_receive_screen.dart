import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'services/upi_handle_service.dart';

class UPIReceiveScreen extends StatefulWidget {
  const UPIReceiveScreen({super.key});

  @override
  State<UPIReceiveScreen> createState() => _UPIReceiveScreenState();
}

class _UPIReceiveScreenState extends State<UPIReceiveScreen> {
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();
  
  String _currentUPIType = '';

  Future<void> _checkUPIType(String upiId) async {
    if (upiId.contains('@') && upiId.length > 3) {
      try {
        String upiType = await UPIHandleService.checkUPIType(upiId);
        setState(() {
          _currentUPIType = upiType;
        });
      } catch (e) {
        setState(() {
          _currentUPIType = '';
        });
      }
    } else {
      setState(() {
        _currentUPIType = '';
      });
    }
  }

  String _generateReceiveQR() {
    if (_upiIdController.text.isEmpty || _nameController.text.isEmpty) {
      return '';
    }
    
    String upiUrl = 'upi://pay?pa=${_upiIdController.text}&pn=${_nameController.text}&cu=INR';
    
    if (_amountController.text.isNotEmpty) {
      upiUrl += '&am=${_amountController.text}';
    }
    
    if (_noteController.text.isNotEmpty) {
      upiUrl += '&tn=${_noteController.text}';
    }
    
    return upiUrl;
  }

  void _copyToClipboard() {
    final upiUrl = _generateReceiveQR();
    if (upiUrl.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: upiUrl));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('UPI link copied to clipboard!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Save QR code image to device gallery
  Future<void> _saveQRImage() async {
    try {
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Get directory to save
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final fileName = 'QR_${_nameController.text.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
        final imagePath = '${directory.path}/$fileName';
        
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(pngBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR code saved to: $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save QR code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Share payment details with QR code image
  Future<void> _sharePaymentDetailsWithQR() async {
    try {
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/payment_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      
      // Write image to file
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      String shareText = '💳 Pay ${_nameController.text} via UPI\n\n';
      shareText += '📱 UPI ID: ${_upiIdController.text}\n';
      
      // Add UPI type warning to shared content
      String warningMessage = _getUPIWarningMessage();
      if (warningMessage.isNotEmpty) {
        shareText += '\n⚠️ WARNING: $warningMessage\n';
      }
      
      if (_amountController.text.isNotEmpty) {
        shareText += '💰 Amount: ₹${_amountController.text}\n';
      }
      
      if (_noteController.text.isNotEmpty) {
        shareText += '📝 Note: ${_noteController.text}\n';
      }
      
      shareText += '\n🔗 UPI Link: ${_generateReceiveQR()}\n\n';
      shareText += 'Scan the QR code in the image or click the UPI link to pay instantly!';

      // Share image with text
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: shareText,
        subject: 'Payment Request - ${_nameController.text}',
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share payment details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sharePaymentDetails() {
    if (_upiIdController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter UPI ID and name first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Call the new method that includes QR image
    _sharePaymentDetailsWithQR();
  }

  // Capture QR code as image and share
  Future<void> _captureAndShareQR() async {
    try {
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      
      // Write image to file
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      // Create share text
      String shareText = '💳 Payment QR Code - ${_nameController.text}\n\n';
      shareText += '📱 UPI ID: ${_upiIdController.text}\n';
      
      // Add UPI type warning to shared content
      String warningMessage = _getUPIWarningMessage();
      if (warningMessage.isNotEmpty) {
        shareText += '\n⚠️ WARNING: $warningMessage\n';
      }
      
      if (_amountController.text.isNotEmpty) {
        shareText += '💰 Amount: ₹${_amountController.text}\n';
      }
      
      if (_noteController.text.isNotEmpty) {
        shareText += '📝 Note: ${_noteController.text}\n';
      }
      
      shareText += '\n🔗 UPI Link: ${_generateReceiveQR()}\n\n';
      shareText += 'Scan the QR code above or click the UPI link to pay instantly!';

      // Share image with text
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: shareText,
        subject: 'Payment QR Code - ${_nameController.text}',
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share QR code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareQRCodeOnly() {
    if (_upiIdController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter UPI ID and name first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Call the new capture and share method
    _captureAndShareQR();
  }

  String _getUPIWarningMessage() {
    switch (_currentUPIType.toLowerCase()) {
      case 'wallet':
        return 'Wallet detected might be fraud';
      case 'unknown':
        return 'Unverified or new handle';
      default:
        return '';
    }
  }

  Widget _buildUPITypeWarning() {
    String warningText = '';
    Color warningColor = Colors.transparent;
    IconData warningIcon = Icons.info_outline;

    switch (_currentUPIType.toLowerCase()) {
      case 'wallet':
        warningText = 'Wallet detected might be fraud';
        warningColor = Colors.red;
        warningIcon = Icons.warning;
        break;
      case 'unknown':
        warningText = 'Unverified or new handle';
        warningColor = Colors.orange;
        warningIcon = Icons.help_outline;
        break;
      case 'bank':
        return const SizedBox.shrink(); // No warning for bank UPIs
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: warningColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            warningIcon,
            color: warningColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              warningText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: warningColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _upiIdController,
                      decoration: const InputDecoration(
                        labelText: 'Your UPI ID',
                        hintText: 'yourname@upi',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      onChanged: (value) {
                        setState(() {});
                        _checkUPIType(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        hintText: 'Enter your name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹) - Optional',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        hintText: 'Payment description',
                        prefixIcon: Icon(Icons.note),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_upiIdController.text.isNotEmpty && _nameController.text.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Your Payment QR Code',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onLongPress: _saveQRImage,
                        child: RepaintBoundary(
                          key: _qrKey,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                QrImageView(
                                  data: _generateReceiveQR(),
                                  version: QrVersions.auto,
                                  size: 200.0,
                                  backgroundColor: Colors.white,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _nameController.text,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_amountController.text.isNotEmpty)
                                  Text(
                                    '₹${_amountController.text}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                
                                // Add warning below QR in the image
                                if (_getUPIWarningMessage().isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _currentUPIType.toLowerCase() == 'wallet' 
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: _currentUPIType.toLowerCase() == 'wallet' 
                                          ? Colors.red 
                                          : Colors.orange,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _currentUPIType.toLowerCase() == 'wallet' 
                                            ? Icons.warning
                                            : Icons.info_outline,
                                          size: 14,
                                          color: _currentUPIType.toLowerCase() == 'wallet' 
                                            ? Colors.red 
                                            : Colors.orange,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getUPIWarningMessage(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _currentUPIType.toLowerCase() == 'wallet' 
                                              ? Colors.red 
                                              : Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Warning widget based on UPI type
                      if (_currentUPIType.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: _buildUPITypeWarning(),
                        ),
                      
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          Text(
                            'Share this QR code for others to pay you',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Long press QR code to save image',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_amountController.text.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text(
                            'Amount: ₹${_amountController.text}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _copyToClipboard,
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy Link'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _shareQRCodeOnly,
                              icon: const Icon(Icons.qr_code),
                              label: const Text('Share QR Image'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _sharePaymentDetails,
                              icon: const Icon(Icons.share),
                              label: const Text('Share Details + QR'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
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
            if (_upiIdController.text.isEmpty || _nameController.text.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter your UPI ID and name to generate QR code',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
