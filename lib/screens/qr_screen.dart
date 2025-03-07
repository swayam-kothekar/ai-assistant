import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScannerScreen extends StatefulWidget {
  final Function(String) onScanComplete;

  const QRCodeScannerScreen({super.key, required this.onScanComplete});

  @override
  // ignore: library_private_types_in_public_api
  _QRCodeScannerScreenState createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool isScanning = true;
  bool isTorchOn = false;
  
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: Icon(
              isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: isTorchOn ? Colors.yellow : Colors.grey,
            ),
            onPressed: () async {
              await controller.toggleTorch();
              setState(() {
                isTorchOn = !isTorchOn;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && isScanning) {
                  final String? code = barcodes.first.rawValue;
                  if (code != null) {
                    isScanning = false; // Prevent multiple callbacks
                    widget.onScanComplete(code);
                    Navigator.of(context).pop(); // Close the scanner screen
                  }
                }
              },
            ),
          ),
          const Expanded(
            flex: 1,
            child: Center(
              child: Text('Scan a UPI QR code to proceed with payment.'),
            ),
          ),
        ],
      ),
    );
  }
}