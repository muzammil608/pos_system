import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/firebase/order_service.dart';
import '../../widgets/app_navigation.dart';
import 'product_list_bottom_sheet.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderService _orderService = OrderService();

  String _orderType = 'takeaway';
  String? _tableNumber;
  String _customerName = '';
  String _paymentMethod = 'cash';
  double _tenderedAmount = 0.0;
  bool _isSubmitting = false;
  late FocusNode _cashFocus = FocusNode();

  Future<void> _showEditItemDialog(
    BuildContext context,
    CartProvider cart,
    Map<String, dynamic> item,
  ) async {
    TextEditingController? qtyController;
    await showDialog<bool?>(
      context: context,
      builder: (dialogContext) {
        qtyController = TextEditingController(
          text: ((item['qty'] as num?)?.toInt() ?? 1).toString(),
        );
        return AlertDialog(
          title: Text('Edit ${item['name']}'),
          content: TextField(
            controller: qtyController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newQty = int.tryParse(qtyController!.text.trim());
                if (newQty == null || newQty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid quantity greater than 0.'),
                    ),
                  );
                  Navigator.pop(dialogContext, false);
                  return;
                }
                cart.updateItemQuantity(item['cartDocId'] as String, newQty);
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    qtyController?.dispose();
  }

  @override
  void dispose() {
    _cashFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, auth, child) {
      if (!auth.isAdmin && !auth.isCashier) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/pos');
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final userEmail = auth.user?.email ?? 'No Email';
      final userName = auth.user?.displayName ?? userEmail.split('@').first;
      final photoUrl = auth.user?.photoURL;

      return Scaffold(
        drawer: AppNavigationDrawer(auth: auth, currentRoute: '/checkout'),
        appBar: AppBar(
          title: const Text('Checkout'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            AppDrawerAvatarButton(
              photoUrl: photoUrl,
              userName: userName,
            ),
          ],
        ),
        body: Consumer<CartProvider>(
          builder: (context, cart, child) {
            final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
            final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

            final topForm = Container(
              color: AppTheme.surface,
              padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardOpen ? 8 : 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _orderType,
                          decoration: const InputDecoration(
                            labelText: 'Order Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'takeaway', child: Text('Takeaway')),
                            DropdownMenuItem(
                                value: 'dine_in', child: Text('Dine In')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _orderType = value ?? 'takeaway';
                              if (_orderType != 'dine_in') _tableNumber = null;
                            });
                          },
                        ),
                      ),
                      if (_orderType == 'dine_in') ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _tableNumber,
                            decoration: const InputDecoration(
                              labelText: 'Table',
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('Select Table'),
                            items: List.generate(
                              20,
                              (i) => DropdownMenuItem(
                                value: '${i + 1}',
                                child: Text('Table ${i + 1}'),
                              ),
                            ),
                            onChanged: (value) =>
                                setState(() => _tableNumber = value),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) => _customerName = value,
                          decoration: const InputDecoration(
                            labelText: 'Customer Name',
                            border: OutlineInputBorder(),
                            hintText: 'Enter name',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Payment',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'cash', child: Text('Cash')),
                            DropdownMenuItem(
                                value: 'card', child: Text('Card')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _paymentMethod = value ?? 'cash';
                              if (value != 'cash') _tenderedAmount = 0.0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_paymentMethod == 'cash') ...[
                    const SizedBox(height: 12),
                    TextField(
                      focusNode: _cashFocus,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) => setState(() {
                        _tenderedAmount = double.tryParse(value) ?? 0.0;
                      }),
                      decoration: const InputDecoration(
                        labelText: 'Cash Tendered',
                        border: OutlineInputBorder(),
                        prefixText: 'Rs ',
                      ),
                    ),
                    if (_cashFocus.hasFocus && _tenderedAmount < cart.total)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4.0),
                        child: Text(
                          'Please! Enter Full Amount',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Change Due:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            'Rs ${(_tenderedAmount - cart.total).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: (_tenderedAmount >= cart.total)
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );

            final cartSection = cart.items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Text('Cart is empty\nAdd products first'),
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.items.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, i) {
                      final item = cart.items[i];
                      final cartDocId = item['cartDocId'] as String? ?? '';
                      final price =
                          ((item['unitPrice'] ?? item['price']) as num?) ?? 0;
                      final qty = (item['qty'] as num?)?.toInt() ?? 1;
                      final lineTotal =
                          ((item['lineTotal']) as num?)?.toDouble() ??
                              (price.toDouble() * qty);

                      return Card(
                        child: ListTile(
                          title: Text(
                            item['name'].toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Qty: $qty  •  Rs ${price.toStringAsFixed(0)}  •  Total: Rs ${lineTotal.toStringAsFixed(0)}',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add,
                                    color: AppTheme.primary),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) =>
                                        const ProductListBottomSheet(),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: AppTheme.secondary),
                                onPressed: () => _showEditItemDialog(
                                  context,
                                  cart,
                                  item,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: AppTheme.danger),
                                onPressed: cartDocId.isNotEmpty
                                    ? () => cart.removeItem(cartDocId)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(
                      bottom: keyboardOpen ? keyboardInset + 12 : 12,
                    ),
                    children: [
                      topForm,
                      cartSection,
                    ],
                  ),
                ),
                if (!keyboardOpen)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondary.withValues(alpha: 0.16),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Rs ${cart.total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: cart.items.isEmpty ||
                                    (_paymentMethod == 'cash' &&
                                        _tenderedAmount < cart.total) ||
                                    _isSubmitting
                                ? null
                                : () async {
                                    if (_orderType == 'dine_in' &&
                                        (_tableNumber == null ||
                                            _tableNumber!.isEmpty)) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Please select a table for dine in orders.'),
                                        ),
                                      );
                                      return;
                                    }

                                    final changeAmount =
                                        _paymentMethod == 'cash'
                                            ? _tenderedAmount - cart.total
                                            : 0.0;

                                    setState(() => _isSubmitting = true);

                                    try {
                                      final cartSnapshot =
                                          cart.items.map((item) {
                                        final qty =
                                            (item['qty'] as num?)?.toInt() ??
                                                (item['quantity'] as num?)
                                                    ?.toInt() ??
                                                1;
                                        final price = (item['price'] as num?)
                                                ?.toDouble() ??
                                            0.0;
                                        return <String, dynamic>{
                                          'name': item['name'] ?? 'Unknown',
                                          'qty': qty,
                                          'quantity': qty,
                                          'price': price,
                                          'unitPrice': price,
                                          'lineTotal': price * qty,
                                          if (item['productId'] != null)
                                            'productId': item['productId'],
                                        };
                                      }).toList();

                                      await _orderService.createOrder(
                                        items: cartSnapshot,
                                        total: cart.total,
                                        orderType: _orderType,
                                        tableNumber: _tableNumber,
                                        customerName: _customerName,
                                        paymentMethod: _paymentMethod,
                                        tenderedAmount: _paymentMethod == 'cash'
                                            ? _tenderedAmount
                                            : 0.0,
                                        change: changeAmount,
                                      );

                                      if (!context.mounted) return;

                                      cart.clear();

                                      // Navigate to POS after placing order (NO receipt here)
                                      Navigator.pushNamedAndRemoveUntil(
                                          context, '/pos', (route) => false);
                                    } catch (e) {
                                      if (!context.mounted) return;

                                      final errorMsg = e
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains('network') ||
                                              e
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains('internet') ||
                                              e
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains('connect') ||
                                              e
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains('timeout') ||
                                              e
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains('unavailable')
                                          ? 'No internet connection. Please check your connection and try again.'
                                          : 'Error: $e';

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text(errorMsg)),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() => _isSubmitting = false);
                                      }
                                    }
                                  },
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: Text(
                              _isSubmitting
                                  ? 'Placing Order...'
                                  : 'Place Order',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      );
    });
  }
}
