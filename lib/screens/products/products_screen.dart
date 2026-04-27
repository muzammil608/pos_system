import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductForm(BuildContext context, {Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(
      text: product != null ? product.price.toStringAsFixed(0) : '',
    );
    final categoryController =
        TextEditingController(text: product?.category ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = product != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEdit ? 'Edit Product' : 'Add Product',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name
                  TextFormField(
                    controller: nameController,
                    autofocus: !isEdit,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Price
                  TextFormField(
                    controller: priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: 'Rs ',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Price is required';
                      if (double.tryParse(v.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Category
                  TextFormField(
                    controller: categoryController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category_outlined),
                      hintText: 'e.g. Drinks, Food, Snacks',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Category is required'
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Consumer<ProductProvider>(
                      builder: (context, provider, _) {
                        return ElevatedButton.icon(
                          onPressed: provider.isLoading
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;

                                  final name = nameController.text.trim();
                                  final price =
                                      double.parse(priceController.text.trim());
                                  final category =
                                      categoryController.text.trim();

                                  String? error;

                                  if (isEdit) {
                                    error = await provider.updateProduct(
                                      id: product!.id,
                                      name: name,
                                      price: price,
                                      category: category,
                                    );
                                  } else {
                                    error = await provider.createProduct(
                                      name: name,
                                      price: price,
                                      category: category,
                                    );
                                  }

                                  if (!sheetContext.mounted) return;
                                  Navigator.pop(sheetContext);

                                  if (error != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isEdit
                                            ? 'Product updated'
                                            : 'Product added'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                          icon: provider.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(isEdit ? Icons.save : Icons.add),
                          label: Text(
                            provider.isLoading
                                ? (isEdit ? 'Saving...' : 'Adding...')
                                : (isEdit ? 'Save Changes' : 'Add Product'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Delete confirmation ───────────────────────────────────────────────────
  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
            'Are you sure you want to delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final error = await context
                  .read<ProductProvider>()
                  .deleteProduct(product.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error ?? 'Product deleted'),
                  backgroundColor: error != null ? Colors.red : Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
            onPressed: () => _showProductForm(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Product list ─────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: context.read<ProductProvider>().productsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final allProducts = snapshot.data ?? [];

                // Filter by search
                final filtered = allProducts.where((p) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      p.name.toLowerCase().contains(_searchQuery) ||
                      p.category.toLowerCase().contains(_searchQuery);
                  final matchesCategory = _selectedCategory == 'All' ||
                      p.category == _selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                // Build category chips from live data
                final categories = [
                  'All',
                  ...{...allProducts.map((p) => p.category)},
                ];

                if (allProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No products yet',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showProductForm(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add your first product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Category filter chips
                    if (categories.length > 1)
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final cat = categories[i];
                            final selected = _selectedCategory == cat;
                            return FilterChip(
                              label: Text(cat),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _selectedCategory = cat),
                              selectedColor: AppTheme.primary.withOpacity(0.2),
                              checkmarkColor: AppTheme.primary,
                              labelStyle: TextStyle(
                                color: selected
                                    ? AppTheme.primary
                                    : Colors.black87,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 4),

                    // Count label
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '${filtered.length} product${filtered.length == 1 ? '' : 's'}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    // List
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No products match "$_searchQuery"',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 100),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final product = filtered[i];
                                return Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          AppTheme.primary.withOpacity(0.12),
                                      child: Text(
                                        product.name[0].toUpperCase(),
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      product.category,
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Rs ${product.price.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue, size: 20),
                                          onPressed: () => _showProductForm(
                                              context,
                                              product: product),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red, size: 20),
                                          onPressed: () =>
                                              _confirmDelete(context, product),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
