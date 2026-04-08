import 'package:flutter/material.dart';

class ReceiptDialog extends StatelessWidget {
  final String orderId;
  final String receiptText;

  const ReceiptDialog({
    super.key,
    required this.orderId,
    required this.receiptText,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 380,
        height: 550,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Logo
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SelectableText(
                    receiptText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontFamilyFallback: ['Courier'],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
