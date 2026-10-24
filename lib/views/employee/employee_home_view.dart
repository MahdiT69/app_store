import 'package:flutter/material.dart';
import 'package:app_store/controllers/employee_controller.dart';
import 'package:app_store/controllers/auth_session.dart';
import 'package:app_store/models/product.dart';
import 'package:app_store/utils/constants.dart';
import 'package:app_store/utils/toast.dart';
import 'package:app_store/views/customer/home_view.dart';
import 'package:app_store/widgets/add_product_dialog.dart';
import 'package:app_store/widgets/order_qty_dialog.dart';

const kDark = Color(0xFF16161A);
const kCard = Color(0xFF1E1E23);
const kBorder = Color(0xFF2C2C33);
const kGold = Color(0xFFD4A94D);
const kTextMuted = Color(0xFF9A9AA5);

class EmployeeHomeView extends StatefulWidget {
  const EmployeeHomeView({super.key});

  @override
  State<EmployeeHomeView> createState() => _EmployeeHomeViewState();
}

class _EmployeeHomeViewState extends State<EmployeeHomeView>
    with SingleTickerProviderStateMixin {
  final EmployeeController _controller = EmployeeController();
  List<Product> _products = [];
  bool _isLoading = true;

  late TabController _tabController;

  // Purchase Orders state
  List<Map<String, dynamic>> _invoices = [];
  bool _invoicesLoading = false;
  String _invoiceStatusFilter = "all";

  static const int lowStockThreshold = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        if (_invoices.isEmpty && !_invoicesLoading) _loadInvoices();
      }
    });
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final result = await _controller.fetchProducts();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) _products = result['products'];
      });
    }
  }

  Future<void> _loadInvoices() async {
    setState(() => _invoicesLoading = true);
    final result = await _controller.getInvoices(status: _invoiceStatusFilter);
    if (mounted) {
      setState(() {
        _invoicesLoading = false;
        if (result['success'] == true) {
          _invoices = List<Map<String, dynamic>>.from(result['invoices']);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      body: Column(
        children: [
          _buildNavbar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildPurchaseOrdersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: kDark,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TabBar(
              controller: _tabController,
              labelColor: kGold,
              unselectedLabelColor: kTextMuted,
              indicatorColor: kGold,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: "Products & Stock"),
                Tab(text: "Purchase Orders"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────── PRODUCTS TAB ───────────────────────

  Widget _buildProductsTab() {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text(
                      "Product & Stock Management",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final added = await AddProductDialog.show(context);
                        if (added == true) _loadProducts();
                      },
                      icon: const Icon(Icons.add, color: kDark, size: 18),
                      label: const Text(
                        "Add product",
                        style: TextStyle(
                          color: kDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGold,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                            child: CircularProgressIndicator(color: kGold)),
                      )
                    : _buildProductTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductTable() {
    return LayoutBuilder(builder: (context, constraints) {
      final double tableWidth =
          constraints.maxWidth < 800 ? 800 : constraints.maxWidth;
      return Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                _tableHeaderRow(),
                const Divider(color: kBorder, height: 1),
                ...List.generate(_products.length, (i) {
                  final product = _products[i];
                  return Column(children: [
                    _productRow(product),
                    if (i < _products.length - 1)
                      const Divider(color: kBorder, height: 1),
                  ]);
                }),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _tableHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: const [
        SizedBox(width: 56),
        Expanded(
            flex: 3,
            child: Text("Product",
                style: TextStyle(
                    color: kTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700))),
        Expanded(
            flex: 2,
            child: Text("Category",
                style: TextStyle(
                    color: kTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700))),
        Expanded(
            flex: 1,
            child: Text("Price",
                style: TextStyle(
                    color: kTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700))),
        Expanded(
            flex: 1,
            child: Text("Stock",
                style: TextStyle(
                    color: kTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700))),
        SizedBox(width: 140),
      ]),
    );
  }

  Widget _productRow(Product product) {
    final lowStock = product.stock < lowStockThreshold;
    final imageUrl = Constants.resolveImage(product.imageUrl);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 44,
            height: 44,
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                        color: kBorder,
                        child: const Icon(Icons.inventory_2_outlined,
                            color: kTextMuted, size: 18)))
                : Container(
                    color: kBorder,
                    child: const Icon(Icons.inventory_2_outlined,
                        color: kTextMuted, size: 18)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
            flex: 3,
            child: Text(product.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13))),
        Expanded(
            flex: 2,
            child: Text(product.category,
                style: const TextStyle(color: kTextMuted, fontSize: 13))),
        Expanded(
            flex: 1,
            child: Text("\$${product.price.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white, fontSize: 13))),
        Expanded(
          flex: 1,
          child: Row(children: [
            if (lowStock)
              Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.redAccent, shape: BoxShape.circle)),
            Text("${product.stock}",
                style: TextStyle(
                    color: lowStock ? Colors.redAccent : Colors.white,
                    fontWeight:
                        lowStock ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 13)),
          ]),
        ),
        SizedBox(
          width: 140,
          child: OutlinedButton(
            onPressed: () async {
              final ordered =
                  await OrderQtyDialog.show(context, product: product);
              if (mounted && ordered == true) {
                AppToast.show(context, message: "Order sent to supplier.");
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kGold),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Order more",
                style: TextStyle(
                    color: kGold, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────── PURCHASE ORDERS TAB ───────────────────────

  Widget _buildPurchaseOrdersTab() {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const Text("Purchase Orders",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                      tooltip: "Refresh",
                      onPressed: _loadInvoices,
                      icon: const Icon(Icons.refresh, color: kTextMuted)),
                ]),
                const SizedBox(height: 16),
                // Status filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final s in [
                        "all",
                        "pending",
                        "confirmed",
                        "shipped",
                        "completed",
                        "rejected"
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _statusChip(s),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _invoicesLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                            child: CircularProgressIndicator(color: kGold)),
                      )
                    : _invoices.isEmpty
                        ? _buildEmptyInvoices()
                        : _buildInvoicesTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final isSelected = _invoiceStatusFilter == status;
    final labels = {
      "all": "All",
      "pending": "Pending",
      "confirmed": "Confirmed",
      "shipped": "Shipped",
      "completed": "Completed",
      "rejected": "Rejected"
    };
    return GestureDetector(
      onTap: () {
        setState(() => _invoiceStatusFilter = status);
        _loadInvoices();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? kGold : kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? kGold : kBorder),
        ),
        child: Text(labels[status] ?? status,
            style: TextStyle(
                color: isSelected ? kDark : kTextMuted,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
      ),
    );
  }

  Widget _buildEmptyInvoices() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder)),
      child: Column(children: [
        Icon(Icons.receipt_long_outlined,
            color: kTextMuted.withValues(alpha: 0.4), size: 48),
        const SizedBox(height: 16),
        const Text("No purchase orders found",
            style: TextStyle(color: kTextMuted, fontSize: 14)),
        const SizedBox(height: 8),
        TextButton(
            onPressed: _loadInvoices,
            child: const Text("Load orders",
                style: TextStyle(color: kGold))),
      ]),
    );
  }

  Widget _buildInvoicesTable() {
    return Container(
      decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder)),
      child: Column(children: [
        // Header row
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: const [
            Expanded(
                flex: 1,
                child: Text("Invoice #",
                    style: TextStyle(
                        color: kTextMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700))),
            Expanded(
                flex: 2,
                child: Text("Supplier",
                    style: TextStyle(
                        color: kTextMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700))),
            Expanded(
                flex: 2,
                child: Text("Created by",
                    style: TextStyle(
                        color: kTextMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700))),
            Expanded(
                flex: 1,
                child: Text("Products",
                    style: TextStyle(
                        color: kTextMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700))),
            Expanded(
                flex: 1,
                child: Text("Total Qty",
                    style: TextStyle(
                        color: kTextMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700))),
            Expanded(
                flex: 1,
                child: Text("Status",
                    style: TextStyle(
                        color: kTextMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700))),
            SizedBox(width: 140),
          ]),
        ),
        const Divider(color: kBorder, height: 1),
        ...List.generate(_invoices.length, (i) {
          final inv = _invoices[i];
          return Column(children: [
            _invoiceRow(inv),
            if (i < _invoices.length - 1)
              const Divider(color: kBorder, height: 1),
          ]);
        }),
      ]),
    );
  }

  Widget _invoiceRow(Map<String, dynamic> inv) {
    final status = (inv['status'] ?? 'pending').toString().toLowerCase();
    final isShipped =
        status == 'shipped' || status == 'confirmed';
    final isCompleted = status == 'completed';
    final rowBg = isShipped
        ? kGold.withValues(alpha: 0.04)
        : Colors.transparent;

    return Container(
      color: rowBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Expanded(
            flex: 1,
            child: Text("#${inv['id']}",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13))),
        Expanded(
            flex: 2,
            child: Text(
                inv['supplier_name'] ?? inv['supplier_id'] ?? '—',
                style:
                    const TextStyle(color: Colors.white, fontSize: 13))),
        Expanded(
            flex: 2,
            child: Text(
                inv['employee_name'] ?? inv['created_by'] ?? '—',
                style:
                    const TextStyle(color: kTextMuted, fontSize: 13))),
        Expanded(
            flex: 1,
            child: Text("${inv['products_count'] ?? 0}",
                style:
                    const TextStyle(color: kTextMuted, fontSize: 13))),
        Expanded(
            flex: 1,
            child: Text("${inv['total_qty'] ?? 0}",
                style:
                    const TextStyle(color: kTextMuted, fontSize: 13))),
        Expanded(flex: 1, child: _statusBadge(status)),
        SizedBox(
          width: 140,
          child: isCompleted
              ? const Text("Completed \u2713",
                  style: TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 12,
                      fontWeight: FontWeight.w600))
              : isShipped
                  ? OutlinedButton.icon(
                      onPressed: () => _openOcrInspection(inv),
                      icon: const Icon(
                          Icons.document_scanner_outlined,
                          size: 14,
                          color: kGold),
                      label: const Text("Check Qty",
                          style: TextStyle(
                              color: kGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kGold),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  : const SizedBox.shrink(),
        ),
      ]),
    );
  }

  Widget _statusBadge(String status) {
    final configs = {
      'pending': (const Color(0xFFFEF3C7), const Color(0xFF92400E), 'Pending'),
      'confirmed': (const Color(0xFFDEFCE9), const Color(0xFF166534), 'Confirmed'),
      'shipped': (const Color(0xFFE0F2FE), const Color(0xFF0369A1), 'Shipped'),
      'completed': (const Color(0xFFF0FDF4), const Color(0xFF166534), 'Completed'),
      'rejected': (const Color(0xFFFEE2E2), const Color(0xFF991B1B), 'Rejected'),
    };
    final cfg = configs[status] ?? (kBorder, kTextMuted, status);
    final bg = cfg.$1;
    final fg = cfg.$2;
    final label = cfg.$3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  void _openOcrInspection(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _OcrInspectionDialog(
        invoice: invoice,
        controller: _controller,
        onReconciled: () {
          _loadInvoices();
          _loadProducts();
        },
      ),
    );
  }

  // ─────────────────────── NAVBAR ───────────────────────

  Widget _buildNavbar() {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: kDark,
        border: Border(
            bottom:
                BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1740),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: kGold,
                    borderRadius: BorderRadius.circular(10)),
                child:
                    const Icon(Icons.storefront, color: kDark, size: 22),
              ),
              const SizedBox(width: 12),
              const Text("SHOPYME",
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: 1.4,
                      color: Colors.white)),
              const Text(".",
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 25,
                      color: kGold)),
              const SizedBox(width: 32),
              Text("Employee dashboard",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              IconButton(
                tooltip: "Preview website",
                icon: const Icon(Icons.visibility_outlined,
                    color: Colors.white),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const HomeView(isPreview: true)));
                },
              ),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                color: kCard,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: kBorder)),
                onSelected: (v) {
                  if (v == "disconnect") AuthSession.instance.logout();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                        "${AuthSession.instance.nom} ${AuthSession.instance.prenom}",
                        style: const TextStyle(
                            color: kTextMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: "disconnect",
                    child: Row(children: [
                      Icon(Icons.logout, size: 18, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Text("Disconnect",
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: kCard,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person, color: kGold, size: 20),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  OCR INSPECTION DIALOG
// ══════════════════════════════════════════════════════════════

class _OcrInspectionDialog extends StatefulWidget {
  final Map<String, dynamic> invoice;
  final EmployeeController controller;
  final VoidCallback onReconciled;

  const _OcrInspectionDialog({
    required this.invoice,
    required this.controller,
    required this.onReconciled,
  });

  @override
  State<_OcrInspectionDialog> createState() => _OcrInspectionDialogState();
}

class _OcrInspectionDialogState extends State<_OcrInspectionDialog> {
  bool _isLoading = true;
  bool _isReconciling = false;
  Map<String, dynamic>? _ocrData;
  String? _error;
  final Map<int, int> _editedQty = {};

  @override
  void initState() {
    super.initState();
    _runOcr();
  }

  Future<void> _runOcr() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final invoiceId = widget.invoice['id'] as int;
    final result = await widget.controller.verifyOcr(invoiceId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _ocrData = result['ocr'] as Map<String, dynamic>;
          final items = (_ocrData!['items'] as List?) ?? [];
          for (int i = 0; i < items.length; i++) {
            final item = items[i] as Map<String, dynamic>;
            _editedQty[i] =
                (item['qty_ocr_detected'] ?? item['qty_ordered']) as int;
          }
        } else {
          _error = result['message'] ?? "OCR failed";
        }
      });
    }
  }

  Future<void> _reconcile() async {
    if (_ocrData == null) return;
    setState(() => _isReconciling = true);

    final items = (_ocrData!['items'] as List?) ?? [];
    final payload = <Map<String, dynamic>>[];
    for (int i = 0; i < items.length; i++) {
      final item = items[i] as Map<String, dynamic>;
      final prodId = item['product_id'];
      final qtyReceived =
          _editedQty[i] ?? (item['qty_ocr_detected'] as int? ?? 0);
      if (prodId != null) {
        payload.add({'product_id': prodId, 'qty_received': qtyReceived});
      }
    }

    final invoiceId = widget.invoice['id'] as int;
    final result = await widget.controller.reconcileStock(invoiceId, payload);

    if (mounted) {
      setState(() => _isReconciling = false);
      if (result['success'] == true) {
        Navigator.of(context).pop();
        widget.onReconciled();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text("Stock reconciled & invoice marked as Completed \u2713"),
          backgroundColor: Color(0xFF166534),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? "Reconciliation failed"),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final dialogW = screenW > 1000 ? 920.0 : screenW * 0.92;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogW,
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 20)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(color: kBorder, height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: kGold),
                          SizedBox(height: 16),
                          Text("Running OCR analysis on delivery receipt\u2026",
                              style: TextStyle(color: kTextMuted)),
                        ],
                      ),
                    )
                  : _error != null
                      ? _buildError()
                      : _buildContent(),
            ),
            if (!_isLoading && _error == null) ...[
              const Divider(color: kBorder, height: 1),
              _buildFooter(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final invoiceId = widget.invoice['id'];
    final supplierName =
        widget.invoice['supplier_name'] ?? widget.invoice['supplier_id'] ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: kGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.document_scanner_outlined,
              color: kGold, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("OCR Quantity Inspection \u2014 Invoice #$invoiceId",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 2),
              Text("Supplier: $supplierName",
                  style:
                      const TextStyle(color: kTextMuted, fontSize: 12)),
            ],
          ),
        ),
        if (_ocrData != null && _ocrData!['has_discrepancy'] == true)
          _headerBadge(Icons.warning_amber_rounded, "Discrepancies Found",
              Colors.redAccent)
        else if (_ocrData != null)
          _headerBadge(Icons.check_circle_outline, "All Quantities Match",
              const Color(0xFF4ADE80)),
        const SizedBox(width: 12),
        IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: kTextMuted)),
      ]),
    );
  }

  Widget _headerBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
        const SizedBox(height: 12),
        Text(_error ?? "Unknown error",
            style: const TextStyle(color: kTextMuted)),
        const SizedBox(height: 20),
        TextButton(
            onPressed: _runOcr,
            child: const Text("Retry", style: TextStyle(color: kGold))),
      ]),
    );
  }

  Widget _buildContent() {
    final items = (_ocrData!['items'] as List?) ?? [];
    final receiptNo = _ocrData!['receipt_no'] ?? '';
    final invoiceRef = _ocrData!['invoice_ref'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Meta chips
          Row(children: [
            _metaChip(Icons.receipt_outlined, "Receipt No.", receiptNo),
            const SizedBox(width: 12),
            _metaChip(Icons.tag, "Invoice Ref", invoiceRef),
            const SizedBox(width: 12),
            _metaChip(Icons.picture_as_pdf_outlined, "Source",
                "Delivery Receipt PDF"),
          ]),
          const SizedBox(height: 24),
          // Table header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: kDark,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(children: const [
              SizedBox(width: 44),
              Expanded(
                  flex: 3,
                  child: Text("Product",
                      style: TextStyle(
                          color: kTextMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700))),
              SizedBox(
                  width: 90,
                  child: Text("Ordered",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: kTextMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700))),
              SizedBox(
                  width: 90,
                  child: Text("Confirmed",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: kTextMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700))),
              SizedBox(
                  width: 110,
                  child: Text("OCR Detected",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: kTextMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700))),
              SizedBox(
                  width: 100,
                  child: Text("Discrepancy",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: kTextMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700))),
              SizedBox(
                  width: 90,
                  child: Text("To Receive",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: kTextMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700))),
            ]),
          ),
          // Table rows
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: kBorder),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(10)),
            ),
            child: Column(
              children: List.generate(items.length, (i) {
                final item = items[i] as Map<String, dynamic>;
                final qOrd = (item['qty_ordered'] ?? 0) as int;
                final qConf = (item['qty_confirmed'] ?? qOrd) as int;
                final qOcr = (item['qty_ocr_detected'] ?? qConf) as int;
                final disc = (item['discrepancy'] ?? 0) as int;
                final hasDis = item['has_discrepancy'] == true;
                final imgUrl =
                    Constants.resolveImage(item['image_url'] ?? '');

                return Column(children: [
                  Container(
                    color: hasDis
                        ? Colors.redAccent.withValues(alpha: 0.04)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(children: [
                      // Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: imgUrl.isNotEmpty
                              ? Image.network(imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, _e) => Container(
                                      color: kBorder,
                                      child: const Icon(
                                          Icons.inventory_2_outlined,
                                          color: kTextMuted,
                                          size: 14)))
                              : Container(
                                  color: kBorder,
                                  child: const Icon(
                                      Icons.inventory_2_outlined,
                                      color: kTextMuted,
                                      size: 14)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['product_name'] ?? '—',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                            if ((item['note'] ?? '')
                                .toString()
                                .isNotEmpty)
                              Text(item['note'],
                                  style: const TextStyle(
                                      color: kTextMuted, fontSize: 10)),
                          ],
                        ),
                      ),
                      // Ordered
                      SizedBox(
                          width: 90,
                          child: Text("$qOrd",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13))),
                      // Confirmed
                      SizedBox(
                          width: 90,
                          child: Text("$qConf",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: qConf < qOrd
                                      ? Colors.orangeAccent
                                      : Colors.white,
                                  fontSize: 13))),
                      // OCR Detected
                      SizedBox(
                          width: 110,
                          child: Text("$qOcr",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: hasDis
                                      ? Colors.redAccent
                                      : const Color(0xFF4ADE80),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13))),
                      // Discrepancy
                      SizedBox(
                        width: 100,
                        child: Center(
                          child: hasDis
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.redAccent
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: Text("$disc",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12)),
                                )
                              : const Text("OK",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Color(0xFF4ADE80),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                        ),
                      ),
                      // Editable To Receive field
                      SizedBox(
                        width: 90,
                        child: Center(
                          child: SizedBox(
                            width: 68,
                            height: 32,
                            child: TextFormField(
                              initialValue:
                                  "${_editedQty[i] ?? qOcr}",
                              keyboardType:
                                  TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                                filled: true,
                                fillColor: hasDis
                                    ? Colors.redAccent
                                        .withValues(alpha: 0.1)
                                    : kDark,
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                        color: hasDis
                                            ? Colors.redAccent
                                                .withValues(alpha: 0.5)
                                            : kBorder)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                        color: hasDis
                                            ? Colors.redAccent
                                                .withValues(alpha: 0.5)
                                            : kBorder)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                        color: kGold)),
                              ),
                              onChanged: (v) {
                                final parsed = int.tryParse(v);
                                if (parsed != null) {
                                  setState(
                                      () => _editedQty[i] = parsed);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  if (i < items.length - 1)
                    const Divider(color: kBorder, height: 1),
                ]);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: kDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder)),
      child: Row(children: [
        Icon(icon, size: 14, color: kTextMuted),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: kTextMuted, fontSize: 9)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ]),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel",
                  style: TextStyle(color: kTextMuted))),
          const SizedBox(width: 12),
          TextButton.icon(
              onPressed: _runOcr,
              icon:
                  const Icon(Icons.refresh, size: 16, color: kTextMuted),
              label: const Text("Re-scan PDF",
                  style: TextStyle(color: kTextMuted))),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isReconciling ? null : _reconcile,
            icon: _isReconciling
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        color: kDark, strokeWidth: 2))
                : const Icon(Icons.check_circle_outline,
                    size: 16, color: kDark),
            label: Text(
                _isReconciling
                    ? "Reconciling\u2026"
                    : "Reconcile Stock & Complete",
                style: const TextStyle(
                    color: kDark, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kGold,
              disabledBackgroundColor: kGold.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
