import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/admin_provider.dart';

class AdminProductForm extends ConsumerStatefulWidget {
  const AdminProductForm({super.key});

  @override
  ConsumerState<AdminProductForm> createState() => _AdminProductFormState();
}

class _AdminProductFormState extends ConsumerState<AdminProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _sizePriceControllers = <String, TextEditingController>{};
  final _sizeStockControllers = <String, TextEditingController>{};
  String _selectedCategory = 'all';
  bool _saving = false;

  static const _categories = [
    'all',
    'jersey',
    'trainers',
    'accessories',
    'socks',
  ];

  static const _sizeLabels = ['S', 'M', 'L'];

  @override
  void initState() {
    super.initState();
    for (final label in _sizeLabels) {
      _sizePriceControllers[label] = TextEditingController();
      _sizeStockControllers[label] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    for (final controller in _sizePriceControllers.values) {
      controller.dispose();
    }
    for (final controller in _sizeStockControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final imageUrl = _imageUrlController.text.trim();
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a product image path or URL.'),
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final sizes = <String, Map<String, Object>>{};

    for (final label in _sizeLabels) {
      final priceText = _sizePriceControllers[label]!.text.trim();
      final stockText = _sizeStockControllers[label]!.text.trim();
      final price = int.tryParse(priceText);
      final stock = int.tryParse(stockText);

      if (price == null || price < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enter a valid price for size $label.')),
        );
        return;
      }
      if (stock == null || stock < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enter a valid stock for size $label.')),
        );
        return;
      }

      sizes[label] = {'price': price, 'stock': stock};
    }

    setState(() => _saving = true);
    try {
      final productData = <String, Object>{
        'name': name,
        'category': _selectedCategory,
        'description': description,
        'imagePath': imageUrl,
        'images': [imageUrl],
        'sizes': sizes,
        'isActive': true,
      };

      await ref.read(adminServiceProvider).addProduct(productData);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Product created.')));
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving product: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: AppColors.deepBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.trim().isEmpty == true ? 'Name is required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.toUpperCase()),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim().isEmpty == true
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Image URL',
                  style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _imageUrlController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'Image path or URL',
                    hintText: 'assets/images/product.png or https://...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final imageUrl = value?.trim() ?? '';
                    if (imageUrl.isEmpty) {
                      return 'Image path or URL is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Sizes',
                  style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.sm),
                ..._sizeLabels.map(_buildSizeRow),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _saving ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSizeRow(String size) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(size, style: AppTextStyles.label)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextFormField(
              controller: _sizePriceControllers[size],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextFormField(
              controller: _sizeStockControllers[size],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
