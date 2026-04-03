class PrinterService {
  Future<void> printReceipt(String text) async {
    // integrate ESC/POS later
    print("Printing: $text");
  }
}
