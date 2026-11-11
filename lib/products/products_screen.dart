import 'package:flutter/services.dart';
import '../utils/validation_utils.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../utils/format_utils.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const Color primary = Color(0xFF087F73);
  static const Color darkText = Color(0xFF14213D);
  static const Color mutedText = Color(0xFF7A869A);
  static const Color background = Color(0xFFF8FAFA);

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Cattle Feed',
    'Supplements',
    'Equipment',
    'Healthcare',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    ApiService.dataChangeNotifier.addListener(_loadProducts);
  }

  @override
  void dispose() {
    ApiService.dataChangeNotifier.removeListener(_loadProducts);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final list = await ApiService.getProducts();
    if (mounted) {
      setState(() {
        _products = list;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _products.where((p) {
      final matchesCategory = _selectedCategory == 'All' || p['category'] == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          (p['name']?.toString().toLowerCase().contains(query) ?? false) ||
          (p['description']?.toString().toLowerCase().contains(query) ?? false);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'Bag');
    final descCtrl = TextEditingController();
    String category = 'Cattle Feed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add New Product'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  inputFormatters: ValidationUtils.lettersOnlyFormatter,
                  decoration: _inputDecoration('Product Name (Letters only)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: _inputDecoration('Category'),
                  items: _categories
                      .where((c) => c != 'All')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => category = val);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: ValidationUtils.decimalNumberFormatter,
                        decoration: _inputDecoration('Price (₹)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: ValidationUtils.digitsOnlyFormatter,
                        decoration: _inputDecoration('Initial Stock (Numbers only)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: unitCtrl,
                  inputFormatters: ValidationUtils.lettersOnlyFormatter,
                  decoration: _inputDecoration('Unit (Bag, Packet, Can, Piece)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: _inputDecoration('Description / Specifications'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                      final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;
                      final unit = unitCtrl.text.trim().isEmpty ? 'Unit' : unitCtrl.text.trim();
                      final desc = descCtrl.text.trim();

                      final nameErr = ValidationUtils.validateName(name, fieldName: "Product Name");
                      if (nameErr != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(nameErr), backgroundColor: Colors.red.shade700));
                        return;
                      }
                      if (price <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Price must be greater than 0"), backgroundColor: Colors.red.shade700));
                        return;
                      }

                      await ApiService.addProduct({
                        'name': name,
                        'category': category,
                        'price': price,
                        'stock': stock,
                        'unit': unit,
                        'description': desc,
                      });

                      if (mounted) {
                        Navigator.pop(ctx);
                        _loadProducts();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name added successfully!'.tr),
                            backgroundColor: primary,
                          ),
                        );
                      }
                    },
                    child: Text('Save Product'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _adjustStock(Map<String, dynamic> product, int delta) async {
    final success = await ApiService.updateProductStock(product['id'], delta);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot reduce stock below zero')),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: mutedText),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE2E7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE2E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;
    final totalInventoryVal = _products.fold<double>(
      0.0,
      (sum, p) => sum + ((p['price'] as num?)?.toDouble() ?? 0) * ((p['stock'] as num?)?.toInt() ?? 0),
    );
    final lowStockCount = _products.where((p) => ((p['stock'] as num?)?.toInt() ?? 0) < 20).length;

    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguageNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: darkText),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Products Master Catalog'.tr,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: darkText),
                ),
                Text(
                  'Cattle Feed, Supplements & Dairy Supplies'.tr,
                  style: const TextStyle(fontSize: 10, color: mutedText),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: primary, size: 26),
                tooltip: 'Add Product'.tr,
                onPressed: _showAddProductDialog,
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: primary))
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Cards
                        Row(
                          children: [
                            Expanded(
                              child: _summaryCard(
                                icon: Icons.inventory_2_outlined,
                                label: 'Total Products'.tr,
                                value: '${_products.length}',
                                color: primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _summaryCard(
                                icon: Icons.warning_amber_rounded,
                                label: 'Low Stock'.tr,
                                value: '$lowStockCount Items',
                                color: const Color(0xFFF57C00),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _summaryCard(
                                icon: Icons.currency_rupee_rounded,
                                label: 'Stock Value'.tr,
                                value: FormatUtils.formatCurrency(totalInventoryVal),
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Search Bar
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search feed, tonic, minerals, equipment...'.tr,
                            hintStyle: const TextStyle(fontSize: 13, color: mutedText),
                            prefixIcon: const Icon(Icons.search_rounded, color: primary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E9EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E9EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primary),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Categories Horizontal Filter
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((cat) {
                              final isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(cat.tr),
                                  selected: isSelected,
                                  onSelected: (_) => setState(() => _selectedCategory = cat),
                                  selectedColor: primary,
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : darkText,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: isSelected ? primary : const Color(0xFFDDE2E7),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Products List
                        if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.inventory_rounded, size: 48, color: mutedText.withValues(alpha: 0.5)),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No products match your search'.tr,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: mutedText),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...filtered.map((prod) => _buildProductCard(prod)),
                      ],
                    ),
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddProductDialog,
            backgroundColor: primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text('New Product'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        );
      },
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: mutedText),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> prod) {
    final stock = (prod['stock'] as num?)?.toInt() ?? 0;
    final price = (prod['price'] as num?)?.toDouble() ?? 0.0;
    final isLow = stock < 20;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(prod['category']),
                  color: primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prod['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF2F7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (prod['category'] ?? '').toString().tr,
                            style: const TextStyle(fontSize: 10, color: mutedText, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${prod['unit'] ?? 'Unit'}',
                          style: const TextStyle(fontSize: 10, color: mutedText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLow ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isLow ? 'Low: $stock left'.tr : 'Stock: $stock'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isLow ? const Color(0xFFF57C00) : const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          if ((prod['description'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              prod['description'],
              style: const TextStyle(fontSize: 11, color: mutedText, height: 1.3),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF0F3F5)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Price per unit', style: TextStyle(fontSize: 10, color: mutedText)),
                  Text(
                    FormatUtils.formatCurrency(price),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primary),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF0F3F5),
                      foregroundColor: darkText,
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(32, 32),
                    ),
                    icon: const Icon(Icons.remove, size: 16),
                    tooltip: 'Reduce Stock'.tr,
                    onPressed: () => _adjustStock(prod, -1),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$stock',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: darkText),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: primary.withValues(alpha: 0.1),
                      foregroundColor: primary,
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(32, 32),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    tooltip: 'Increase Stock'.tr,
                    onPressed: () => _adjustStock(prod, 1),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(dynamic category) {
    switch (category?.toString()) {
      case 'Cattle Feed':
        return Icons.agriculture_rounded;
      case 'Supplements':
        return Icons.medication_liquid_rounded;
      case 'Equipment':
        return Icons.precision_manufacturing_rounded;
      case 'Healthcare':
        return Icons.medical_services_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }
}
