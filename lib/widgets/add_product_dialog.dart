import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_store/controllers/employee_controller.dart';
import 'package:app_store/utils/api_provider.dart';
import 'package:app_store/utils/constants.dart';
import 'package:app_store/utils/toast.dart';

const kDark = Color(0xFF16161A);
const kCard = Color(0xFF1E1E23);
const kBorder = Color(0xFF2C2C33);
const kGold = Color(0xFFD4A94D);
const kTextMuted = Color(0xFF9A9AA5);

class AddProductDialog {
  static Future<bool?> show(BuildContext context) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Add product",
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const _AddProductForm(),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8 * anim.value,
            sigmaY: 8 * anim.value,
          ),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _AddProductForm extends StatefulWidget {
  const _AddProductForm();

  @override
  State<_AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<_AddProductForm> {
  final EmployeeController _controller = EmployeeController();
  final ApiProvider _apiProvider = ApiProvider();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageController = TextEditingController();

  List<String> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;

  static const List<Map<String, String>> _presetImages = [
    {"label": "Webcam", "url": "/static/products/webcam.jpg"},
    {"label": "Keyboard", "url": "/static/products/keyboard.jpg"},
    {"label": "Monitor", "url": "/static/products/monitor.jpg"},
    {"label": "Mouse", "url": "/static/products/mouse.jpg"},
    {"label": "Headset", "url": "/static/products/headset.jpg"},
    {"label": "Hub", "url": "/static/products/hub.png"},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _imageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final list = await _apiProvider.getCategories();
    if (mounted) {
      setState(() {
        _categories = list;
        _isLoadingCategories = false;
        if (_categories.isNotEmpty && _categoryController.text.isEmpty) {
          _categoryController.text = _categories.first;
        }
      });
    }
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kTextMuted, fontSize: 13),
      floatingLabelStyle: const TextStyle(color: kGold, fontSize: 13),
      prefixIcon: Icon(icon, color: kTextMuted, size: 20),
      filled: true,
      fillColor: kDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kGold, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final stockText = _stockController.text.trim();

    if (name.isEmpty) {
      AppToast.show(
        context,
        message: "Product name is required.",
        type: ToastType.error,
      );
      return;
    }

    if (priceText.isEmpty || stockText.isEmpty) {
      AppToast.show(
        context,
        message: "Price and stock are required.",
        type: ToastType.error,
      );
      return;
    }

    final price = double.tryParse(priceText);
    final stock = int.tryParse(stockText);

    if (price == null || price < 0) {
      AppToast.show(
        context,
        message: "Please enter a valid non-negative price.",
        type: ToastType.error,
      );
      return;
    }

    if (stock == null || stock < 0) {
      AppToast.show(
        context,
        message: "Please enter a valid non-negative stock quantity.",
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isSaving = true);

    final category = _categoryController.text.trim().isEmpty
        ? "General"
        : _categoryController.text.trim();

    final result = await _controller.addProduct(
      name: name,
      description: _descController.text.trim(),
      category: category,
      price: price,
      stock: stock,
      imageUrl: _imageController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (result['success'] == true) {
        AppToast.show(context, message: "Product added successfully!");
        Navigator.of(context).pop(true);
      } else {
        AppToast.show(
          context,
          message: result['message'] ?? "Failed to add product",
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = Constants.resolveImage(_imageController.text.trim());

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 520,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_shopping_cart,
                        color: kGold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Add new product",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: kTextMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec("Product name *", Icons.inventory_2_outlined),
                ),
                const SizedBox(height: 14),

                // Description
                TextField(
                  controller: _descController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: _dec("Description", Icons.notes_outlined),
                ),
                const SizedBox(height: 14),

                // Category Input & Chips
                TextField(
                  controller: _categoryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec("Category", Icons.category_outlined),
                ),
                if (!_isLoadingCategories && _categories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _categories.map((cat) {
                      final selected =
                          _categoryController.text.trim().toLowerCase() ==
                          cat.toLowerCase();
                      return ChoiceChip(
                        label: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected ? kDark : Colors.white70,
                          ),
                        ),
                        selected: selected,
                        selectedColor: kGold,
                        backgroundColor: kDark,
                        side: BorderSide(
                          color: selected ? kGold : kBorder,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _categoryController.text = cat);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 14),

                // Price & Stock
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _dec("Price (\$) *", Icons.attach_money),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _stockController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: _dec("Initial Stock *", Icons.numbers),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Image URL
                TextField(
                  controller: _imageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec(
                    "Image URL / Path (optional)",
                    Icons.image_outlined,
                  ),
                ),
                const SizedBox(height: 8),

                // Preset Image Chips
                Row(
                  children: [
                    const Text(
                      "Presets: ",
                      style: TextStyle(color: kTextMuted, fontSize: 11),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _presetImages.map((img) {
                            final selected =
                                _imageController.text.trim() == img["url"];
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(
                                  img["label"]!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: selected ? kDark : kGold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor:
                                    selected ? kGold : kGold.withValues(alpha: 0.1),
                                side: BorderSide(
                                  color: selected ? kGold : kGold.withValues(alpha: 0.3),
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    _imageController.text = img["url"]!;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),

                // Preview Thumbnail
                if (currentImage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: kDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 74,
                            height: 74,
                            child: Image.network(
                              currentImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: kCard,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.redAccent,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Image Preview",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Thumbnail resolves properly.",
                                style: TextStyle(
                                  color: kTextMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: kDark,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: kDark, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Add product",
                                style: TextStyle(
                                  color: kDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}