import 'package:app_store/controllers/auth_session.dart';
import 'package:app_store/utils/toast.dart';
import 'package:app_store/widgets/account_dialog.dart';
import 'package:app_store/widgets/cart_panel.dart';
import 'package:app_store/widgets/login_form.dart';
import 'package:flutter/material.dart';

import 'package:app_store/controllers/product_controller.dart';
import 'package:app_store/controllers/cart_controller.dart';
import 'package:app_store/models/product.dart';
import 'package:app_store/utils/constants.dart';

import 'package:dropdown_button2/dropdown_button2.dart';

// ---------- LUXURY PALETTE ----------
const kDark = Color(0xFF16161A); // page background - near black
const kCard = Color(0xFF1E1E23); // card background - slightly lighter
const kBorder = Color(0xFF2C2C33); // subtle borders
const kGold = Color(0xFFD4A94D);
const kTextMuted = Color(0xFF9A9AA5);

class HomeView extends StatefulWidget {
  final bool isPreview;
  const HomeView({super.key, this.isPreview = false});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ProductController _productController = ProductController();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  List<String> _categories = ["all"];
  int _total = 0;
  int _page = 1;
  final int _pageSize = 6;
  String _selectedCategory = "all";
  String _selectedSort = "recent";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  Future<void> _loadCategories() async {
    final cats = await _productController.fetchCategories();
    setState(() => _categories = ["all", ...cats]);
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final result = await _productController.fetchProducts(
      search: _searchController.text.trim(),
      category: _selectedCategory,
      page: _page,
      pageSize: _pageSize,
      sort: _selectedSort,
    );
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _products = result['products'];
        _total = result['total'];
      }
    });
  }

  int get _pageCount => (_total / _pageSize).ceil().clamp(1, 9999);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      body: Stack(
        children: [
          // Background ambient gradients
          Positioned(
            top: -250,
            left: -250,
            child: Container(
              width: 700,
              height: 700,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF263A4A).withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            top: -250,
            right: -250,
            child: Container(
              width: 700,
              height: 700,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4A3A28).withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Actual page content
          Column(
            children: [
              if (widget.isPreview) _buildPreviewBanner(),
              _buildNavbar(),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeroHeader(),

                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1740),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFiltersBar(),
                                const SizedBox(height: 20),

                                _isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 60,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: kGold,
                                          ),
                                        ),
                                      )
                                    : _products.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 60,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "No products match your filters.",
                                          ),
                                        ),
                                      )
                                    : _buildProductGrid(),

                                const SizedBox(height: 24),

                                if (!_isLoading && _products.isNotEmpty)
                                  _buildPagination(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- PREVIEW BANNER ----------
  Widget _buildPreviewBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2215),
        border: Border(
          bottom: BorderSide(
            color: kGold.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1740),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kGold.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_outlined, color: kGold, size: 15),
                    SizedBox(width: 6),
                    Text(
                      "PREVIEW MODE",
                      style: TextStyle(
                        color: kGold,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                "You are previewing the customer storefront in read-only mode.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 16, color: kDark),
                label: const Text(
                  "Exit preview",
                  style: TextStyle(
                    color: kDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGold,
                  foregroundColor: kDark,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- NAVBAR ----------
  Widget _buildNavbar() {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: kDark,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1740),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ListenableBuilder(
              listenable: AuthSession.instance,
              builder: (context, _) {
                final loggedIn = AuthSession.instance.isLoggedIn;

                return Row(
                  children: [
                    // Brand
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          _page = 1;
                          _searchController.clear();
                          _selectedCategory = "all";
                          _loadProducts();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kGold,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.storefront,
                                color: kDark,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "SHOPYME",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                letterSpacing: 1.4,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              ".",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 25,
                                letterSpacing: 1.4,
                                color: kGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),

                    // Nav links — "Shop" replaced by "My account" when logged in
                    if (loggedIn && !widget.isPreview)
                      _navLink(
                        "My account",
                        isSelected: true,
                        onTap: () => AccountDialog.show(context),
                      )
                    else
                      _navLink(
                        "Shop",
                        isSelected: true,
                        onTap: () {
                          _page = 1;
                          _loadProducts();
                        },
                      ),
                    const SizedBox(width: 24),
                    _navLink(
                      "My orders",
                      onTap: () {
                        if (widget.isPreview) {
                          AppToast.show(
                            context,
                            message: "Preview mode: Orders view is disabled.",
                          );
                          return;
                        }
                        if (!loggedIn) {
                          AppToast.show(
                            context,
                            message: "Please sign in to view your orders.",
                            type: ToastType.error,
                          );
                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (mounted) LoginDialog.show(context);
                          });
                        } else {
                          // TODO: navigate to orders page
                        }
                      },
                    ),

                    const Spacer(),

                    // Cart
                    Container(
                      decoration: BoxDecoration(
                        color: kCard,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _CartButton(
                        onChanged: () => setState(() {}),
                        isPreview: widget.isPreview,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Sign in button OR account menu
                    if (widget.isPreview)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.remove_red_eye, color: kGold, size: 16),
                            SizedBox(width: 8),
                            Text(
                              "Customer view",
                              style: TextStyle(
                                color: kTextMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (loggedIn)
                      _buildAccountMenu()
                    else
                      _buildSignInButton(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return ElevatedButton(
      onPressed: () => LoginDialog.show(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: kGold,
        foregroundColor: kDark,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: const Text(
        "Sign in",
        style: TextStyle(
          color: kDark,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildAccountMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      color: kCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kBorder),
      ),
      onSelected: (value) {
        if (value == "disconnect") {
          AuthSession.instance.logout();
          AppToast.show(context, message: "You have been signed out.");
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            "${AuthSession.instance.nom} ${AuthSession.instance.prenom}",
            style: const TextStyle(
              color: kTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: "disconnect",
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              Text(
                "Disconnect",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kCard,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: kGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: kDark, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navLink(
    String label, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: isSelected
              ? BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.75),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ---------- HERO ----------
  Widget _buildHeroHeader() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1740),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 54),
          decoration: BoxDecoration(
            color: const Color(0xFF191D23),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF303640), width: 1),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B2027), Color(0xFF181B21)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "IN STOCK TODAY",
                style: TextStyle(
                  color: Color(0xFF91A0B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),

              const SizedBox(height: 16),

              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                  children: [
                    TextSpan(
                      text: "Gear that keeps the floor\n",
                      style: TextStyle(color: Color(0xFFE8EBF0)),
                    ),
                    TextSpan(
                      text: "moving",
                      style: TextStyle(color: kGold),
                    ),
                    TextSpan(
                      text: ".",
                      style: TextStyle(color: Color(0xFFE8EBF0)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: 650,
                child: Text(
                  "Peripherals, displays and storage — priced for teams, restocked automatically through our supplier network.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.60),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- FILTERS ----------
  Widget _buildFiltersBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) {
              _page = 1;
              _loadProducts();
            },
            decoration: InputDecoration(
              hintText: "Search products...",
              hintStyle: const TextStyle(color: kTextMuted),
              prefixIcon: const Icon(Icons.search, color: kTextMuted),
              filled: true,
              fillColor: kCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kGold, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        _dropdown(
          value: _selectedCategory,
          items: _categories,
          onChanged: (v) {
            setState(() => _selectedCategory = v!);
            _page = 1;
            _loadProducts();
          },
          labelBuilder: (v) => v == "all" ? "All categories" : v,
        ),
        const SizedBox(width: 12),
        _dropdown(
          value: _selectedSort,
          items: const ["recent", "price-asc", "price-desc", "name"],
          onChanged: (v) {
            setState(() => _selectedSort = v!);
            _loadProducts();
          },
          labelBuilder: (v) {
            switch (v) {
              case "price-asc":
                return "Price: low to high";
              case "price-desc":
                return "Price: high to low";
              case "name":
                return "Name A-Z";
              default:
                return "Newest";
            }
          },
        ),
      ],
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String Function(String) labelBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          valueListenable: ValueNotifier<String?>(value),
          onChanged: onChanged,
          items: items
              .map(
                (item) => DropdownItem<String>(
                  value: item,
                  height: 44,
                  child: Text(
                    labelBuilder(item),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.symmetric(vertical: 4),
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kGold.withValues(alpha: 0.7)),
            ),

            offset: const Offset(0, -4),

            openInterval: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(Icons.keyboard_arrow_down, color: kTextMuted),
          ),
        ),
      ),
    );
  }

  // ---------- GRID ----------
  Widget _buildProductGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3;
        if (constraints.maxWidth < 1000) crossAxisCount = 2;
        if (constraints.maxWidth < 650) crossAxisCount = 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            return _ProductCard(
              product: _products[index],
              onCartChanged: () => setState(() {}),
              isPreview: widget.isPreview,
            );
          },
        );
      },
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$_total product${_total == 1 ? '' : 's'} · page $_page of $_pageCount",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: _page > 1
                  ? () {
                      setState(() => _page--);
                      _loadProducts();
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kDark),
              ),
              child: const Text("Previous", style: TextStyle(color: kDark)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _page < _pageCount
                  ? () {
                      setState(() => _page++);
                      _loadProducts();
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kDark),
              ),
              child: const Text("Next", style: TextStyle(color: kDark)),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onCartChanged;
  final bool isPreview;
  const _ProductCard({
    required this.product,
    required this.onCartChanged,
    this.isPreview = false,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  int qty = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final out = product.isOutOfStock;
    final imageUrl = Constants.resolveImage(product.imageUrl);

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: kBorder,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: kTextMuted,
                        size: 36,
                      ),
                    ),
                  )
                : Container(
                    color: kBorder,
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: kTextMuted,
                      size: 36,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: kBorder,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: kTextMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  product.description,
                  style: const TextStyle(fontSize: 12, color: kTextMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "\$${product.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kGold,
                      ),
                    ),
                    Text(
                      out ? "Out of stock" : "${product.stock} in stock",
                      style: TextStyle(
                        fontSize: 11,
                        color: out ? Colors.redAccent : kTextMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: kBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove,
                              size: 16,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (qty > 1) setState(() => qty--);
                            },
                          ),
                          Text(
                            "$qty",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (qty < product.stock) setState(() => qty++);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: out
                            ? null
                            : () {
                                if (widget.isPreview) {
                                  AppToast.show(
                                    context,
                                    message:
                                        "Preview mode: Add to cart is disabled.",
                                  );
                                  return;
                                }
                                CartController.instance.add(product, qty);
                                widget.onCartChanged();
                                AppToast.show(
                                  context,
                                  message: "${product.name} added to cart",
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGold,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Add to cart",
                          style: TextStyle(
                            color: kDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  final VoidCallback onChanged;
  final bool isPreview;
  const _CartButton({required this.onChanged, this.isPreview = false});

  @override
  Widget build(BuildContext context) {
    final count = CartController.instance.count;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          onPressed: () {
            if (isPreview) {
              AppToast.show(
                context,
                message: "Preview mode: Cart is read-only.",
              );
              return;
            }
            CartPanel.open(context, onChanged);
          },
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: kGold,
                shape: BoxShape.circle,
              ),
              child: Text(
                "$count",
                style: const TextStyle(
                  color: kDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
