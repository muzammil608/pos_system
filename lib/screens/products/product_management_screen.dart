import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  Product? _editingProduct;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final service = Provider.of<ProductProvider>(context, listen: false);
      final name = _nameController.text.trim();
      final price = double.tryParse(_priceController.text) ?? 0;
      final category = _categoryController.text.trim();

      String? result;
      if (_editingProduct != null) {
        result = await service.updateProduct(
          id: _editingProduct!.id,
          name: name,
          price: price,
          category: category,
        );
      } else {
        result = await service.createProduct(
          name: name,
          price: price,
          category: category,
        );
      }

      if (result != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result)));
      }

      _clearForm();
    }
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _categoryController.clear();
    _editingProduct = null;
    _formKey.currentState?.reset();
  }

  void _deleteProduct(Product product) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await Provider.of<ProductProvider>(context, listen: false)
        .deleteProduct(product.id);

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(content: Text(result ?? 'Unable to delete product')),
    );

    if (_editingProduct?.id == product.id) {
      _clearForm();
    }
  }

  void _editProduct(Product product) {
    setState(() {
      _editingProduct = product;
      _nameController.text = product.name;
      _priceController.text = product.price.toString();
      _categoryController.text = product.category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          )
        ],
      ),
      body: Column(
        children: [
          // Add/Edit Form
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price (Rs)',
                        border: OutlineInputBorder(),
                        prefixText: 'Rs ',
                      ),
                      validator: (value) => double.tryParse(value ?? '') == null
                          ? 'Valid price'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(_editingProduct != null
                                ? Icons.edit
                                : Icons.add),
                            label: Text(_editingProduct != null
                                ? 'Update'
                                : 'Add Product'),
                            onPressed: _saveProduct,
                          ),
                        ),
                        if (_editingProduct != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.cancel),
                              label: const Text('Cancel'),
                              onPressed: _clearForm,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: Provider.of<ProductProvider>(context).productsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No products. Add some!'));
                }

                final products = snapshot.data!;
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: product.imageUrl != null
                            ? Image.network(product.imageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_not_supported))
                            : const Icon(Icons.fastfood, size: 50),
                        title: Text(product.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rs ${product.price.toStringAsFixed(0)}'),
                            Text(product.category,
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editProduct(product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduct(product),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _clearForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
