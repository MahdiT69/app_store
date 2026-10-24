import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app_store/controllers/auth_session.dart';
import 'package:app_store/controllers/supplier_controller.dart';
import 'package:app_store/models/purchase_invoice.dart';
import 'package:app_store/utils/toast.dart';

const kDark = Color(0xFF16161A);
const kCard = Color(0xFF1E1E23);
const kBorder = Color(0xFF2C2C33);
const kGold = Color(0xFFD4A94D);
const kTextMuted = Color(0xFF9A9AA5);

class SupplierHomeView extends StatefulWidget {
  const SupplierHomeView({super.key});

  @override
  State<SupplierHomeView> createState() => _SupplierHomeViewState();
}

class _SupplierHomeViewState extends State<SupplierHomeView> {
  final SupplierController _controller = SupplierController();

  List<PurchaseInvoice> _invoices = [];
  Map<String, dynamic> _stats = {
    "pending": 0,
    "confirmed": 0,
    "shipped": 0,
    "total": 0,
  };

  bool _isLoading = true;
  String _selectedStatus = "all";

  static const List<String> _statusFilters = [
    "all",
    "pending",
    "confirmed",
    "shipped",
    "completed",
    "rejected",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String get _supplierId => AuthSession.instance.currentUser?['id_user'] ?? 'fachraf';

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final statsFuture = _controller.fetchStats(_supplierId);
    final invoicesFuture = _controller.fetchInvoices(
      supplierId: _supplierId,
      status: _selectedStatus,
    );

    final results = await Future.wait([statsFuture, invoicesFuture]);

    if (mounted) {
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _invoices = results[1] as List<PurchaseInvoice>;
        _isLoading = false;
      });
    }
  }

  void _onStatusFilterSelected(String status) {
    if (_selectedStatus != status) {
      setState(() {
        _selectedStatus = status;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      body: Column(
        children: [
          _buildNavbar(),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDashboardStrip(),
                        const SizedBox(height: 28),
                        _buildHeaderAndFilterRow(),
                        const SizedBox(height: 16),
                        _isLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 60),
                                child: Center(
                                  child: CircularProgressIndicator(color: kGold),
                                ),
                              )
                            : _buildInvoicesTable(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavbar() {
    final pendingCount = _stats['pending'] ?? 0;

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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kGold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_shipping_outlined, color: kDark, size: 22),
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
                    color: kGold,
                  ),
                ),
                const SizedBox(width: 32),
                Text(
                  "Supplier portal",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),

                // Notification Bell
                Stack(
                  children: [
                    IconButton(
                      tooltip: "New orders",
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _onStatusFilterSelected("pending");
                      },
                    ),
                    if (pendingCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            "$pendingCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // User Popup Menu
                PopupMenuButton<String>(
                  color: kCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: kBorder),
                  ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: kCard,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, color: kGold, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardStrip() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: "Pending Orders",
            count: _stats['pending'] ?? 0,
            icon: Icons.hourglass_top_rounded,
            color: kGold,
            isGlowing: (_stats['pending'] ?? 0) > 0,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            title: "Awaiting Shipment",
            count: _stats['confirmed'] ?? 0,
            icon: Icons.assignment_turned_in_outlined,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            title: "Shipped Orders",
            count: _stats['shipped'] ?? 0,
            icon: Icons.local_shipping_outlined,
            color: Colors.greenAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            title: "Total Orders",
            count: _stats['total'] ?? 0,
            icon: Icons.receipt_long_outlined,
            color: kTextMuted,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    bool isGlowing = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGlowing ? color : kBorder,
          width: isGlowing ? 1.5 : 1,
        ),
        boxShadow: isGlowing
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$count",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: kTextMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAndFilterRow() {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Incoming Purchase Orders",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Manage requests sent by store employees",
              style: TextStyle(color: kTextMuted, fontSize: 13),
            ),
          ],
        ),
        const Spacer(),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _statusFilters.map((st) {
              final isSelected = _selectedStatus == st;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(
                    st[0].toUpperCase() + st.substring(1),
                    style: TextStyle(
                      color: isSelected ? kDark : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: kGold,
                  backgroundColor: kCard,
                  side: BorderSide(
                    color: isSelected ? kGold : kBorder,
                  ),
                  onSelected: (val) {
                    if (val) _onStatusFilterSelected(st);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoicesTable() {
    if (_invoices.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, color: kTextMuted, size: 48),
              SizedBox(height: 12),
              Text(
                "No purchase orders found.",
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              SizedBox(height: 4),
              Text(
                "There are no orders matching the selected status.",
                style: TextStyle(color: kTextMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double tableWidth =
            constraints.maxWidth < 900 ? 900 : constraints.maxWidth;

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
                  ...List.generate(_invoices.length, (i) {
                    final inv = _invoices[i];
                    return Column(
                      children: [
                        _invoiceRow(inv),
                        if (i < _invoices.length - 1)
                          const Divider(color: kBorder, height: 1),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tableHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: const [
          Expanded(
            flex: 2,
            child: Text(
              "Invoice ID",
              style: TextStyle(
                color: kTextMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Date",
              style: TextStyle(
                color: kTextMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "Requested By",
              style: TextStyle(
                color: kTextMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Products",
              style: TextStyle(
                color: kTextMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Total Qty",
              style: TextStyle(
                color: kTextMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Status",
              style: TextStyle(
                color: kTextMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 140),
        ],
      ),
    );
  }

  Widget _invoiceRow(PurchaseInvoice inv) {
    final isPending = inv.status == 'pending';
    final dateStr = inv.createdAt != null
        ? "${inv.createdAt!.day}/${inv.createdAt!.month}/${inv.createdAt!.year}"
        : "-";

    return Container(
      color: isPending ? kGold.withValues(alpha: 0.04) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              inv.formattedId,
              style: TextStyle(
                color: isPending ? kGold : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              dateStr,
              style: const TextStyle(color: kTextMuted, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: kTextMuted),
                const SizedBox(width: 6),
                Text(
                  inv.employeeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "${inv.productsCount} item(s)",
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "${inv.totalQty} pcs",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _statusBadge(inv.status),
          ),
          SizedBox(
            width: 140,
            child: _actionButton(inv),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label = status.toUpperCase();

    switch (status) {
      case 'pending':
        bg = kGold.withValues(alpha: 0.18);
        fg = kGold;
        break;
      case 'confirmed':
        bg = Colors.blue.withValues(alpha: 0.18);
        fg = Colors.lightBlueAccent;
        break;
      case 'shipped':
        bg = Colors.purple.withValues(alpha: 0.18);
        fg = Colors.purpleAccent;
        break;
      case 'completed':
        bg = Colors.green.withValues(alpha: 0.18);
        fg = Colors.greenAccent;
        break;
      case 'rejected':
        bg = Colors.red.withValues(alpha: 0.18);
        fg = Colors.redAccent;
        break;
      default:
        bg = kBorder;
        fg = Colors.white;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _actionButton(PurchaseInvoice inv) {
    if (inv.status == 'pending') {
      return ElevatedButton(
        onPressed: () => _openOrderDetail(inv),
        style: ElevatedButton.styleFrom(
          backgroundColor: kGold,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text(
          "Review order",
          style: TextStyle(
            color: kDark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else if (inv.status == 'confirmed') {
      return OutlinedButton.icon(
        onPressed: () => _openUploadReceiptDialog(inv),
        icon: const Icon(Icons.upload_file, size: 14, color: Colors.lightBlueAccent),
        label: const Text(
          "Upload receipt",
          style: TextStyle(color: Colors.lightBlueAccent, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.lightBlueAccent),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else {
      return OutlinedButton(
        onPressed: () => _openOrderDetail(inv),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: kBorder),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          "View details",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }

  Future<void> _openOrderDetail(PurchaseInvoice inv) async {
    final updated = await _SupplierOrderDetailDialog.show(context, invoiceId: inv.id);
    if (updated == true) {
      _loadData();
    }
  }

  Future<void> _openUploadReceiptDialog(PurchaseInvoice inv) async {
    final updated = await _UploadDeliveryReceiptDialog.show(context, invoice: inv);
    if (updated == true) {
      _loadData();
    }
  }
}

// ==========================================
// 1. ORDER DETAIL DIALOG OVERLAY
// ==========================================
class _SupplierOrderDetailDialog {
  static Future<bool?> show(BuildContext context, {required int invoiceId}) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Order Details",
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => _SupplierOrderDetailForm(invoiceId: invoiceId),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8 * anim.value, sigmaY: 8 * anim.value),
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

class _SupplierOrderDetailForm extends StatefulWidget {
  final int invoiceId;
  const _SupplierOrderDetailForm({required this.invoiceId});

  @override
  State<_SupplierOrderDetailForm> createState() => _SupplierOrderDetailFormState();
}

class _SupplierOrderDetailFormState extends State<_SupplierOrderDetailForm> {
  final SupplierController _controller = SupplierController();
  PurchaseInvoice? _invoice;
  bool _isLoading = true;
  bool _isSubmitting = false;

  final Map<int, TextEditingController> _confirmedQtyControllers = {};

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    for (var c in _confirmedQtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final detail = await _controller.fetchInvoiceDetail(widget.invoiceId);
    if (mounted) {
      setState(() {
        _invoice = detail;
        _isLoading = false;
        if (detail != null) {
          for (var item in detail.items) {
            final initial = item.qtyConfirmed ?? item.qtyRequested;
            _confirmedQtyControllers[item.id] = TextEditingController(
              text: initial.toString(),
            );
          }
        }
      });
    }
  }

  Future<void> _confirmAll() async {
    if (_invoice == null) return;
    setState(() => _isSubmitting = true);

    final itemsToConfirm = _invoice!.items.map((item) {
      return {
        "id": item.id,
        "qty_confirmed": item.qtyRequested,
      };
    }).toList();

    final res = await _controller.confirmInvoice(
      invoiceId: _invoice!.id,
      items: itemsToConfirm,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res['success'] == true) {
        AppToast.show(context, message: "Order confirmed successfully!");
        Navigator.of(context).pop(true);
      } else {
        AppToast.show(context, message: res['message'] ?? "Confirmation failed", type: ToastType.error);
      }
    }
  }

  Future<void> _partialConfirm() async {
    if (_invoice == null) return;

    List<Map<String, dynamic>> itemsToConfirm = [];
    for (var item in _invoice!.items) {
      final ctrl = _confirmedQtyControllers[item.id];
      final val = int.tryParse(ctrl?.text.trim() ?? '');
      if (val == null || val < 0) {
        AppToast.show(
          context,
          message: "Please enter valid quantities for all items.",
          type: ToastType.error,
        );
        return;
      }
      itemsToConfirm.add({
        "id": item.id,
        "qty_confirmed": val,
      });
    }

    setState(() => _isSubmitting = true);

    final res = await _controller.confirmInvoice(
      invoiceId: _invoice!.id,
      items: itemsToConfirm,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res['success'] == true) {
        AppToast.show(context, message: "Partial confirmation saved successfully!");
        Navigator.of(context).pop(true);
      } else {
        AppToast.show(context, message: res['message'] ?? "Confirmation failed", type: ToastType.error);
      }
    }
  }

  Future<void> _rejectOrder() async {
    final reason = await _RejectInvoiceDialog.show(context);
    if (reason != null && _invoice != null) {
      setState(() => _isSubmitting = true);
      final res = await _controller.rejectInvoice(
        invoiceId: _invoice!.id,
        reason: reason,
      );
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (res['success'] == true) {
          AppToast.show(context, message: "Order rejected.");
          Navigator.of(context).pop(true);
        } else {
          AppToast.show(context, message: res['message'] ?? "Rejection failed", type: ToastType.error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 720,
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
          child: _isLoading
              ? const SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(color: kGold),
                  ),
                )
              : _invoice == null
                  ? const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          "Failed to load order details.",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Dialog Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: kGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: kGold,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Purchase Order ${_invoice!.formattedId}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Requested by ${_invoice!.employeeName}",
                                    style: const TextStyle(
                                      color: kTextMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close, color: kTextMuted),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Rejection Reason Alert if rejected
                          if (_invoice!.status == 'rejected' &&
                              _invoice!.rejectionReason != null &&
                              _invoice!.rejectionReason!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Rejection Reason: ${_invoice!.rejectionReason}",
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Items Table
                          Container(
                            decoration: BoxDecoration(
                              color: kDark,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kBorder),
                            ),
                            child: Column(
                              children: [
                                // Table Header
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: const [
                                      SizedBox(width: 44),
                                      SizedBox(width: 12),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          "Product",
                                          style: TextStyle(
                                            color: kTextMuted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "Qty Requested",
                                          style: TextStyle(
                                            color: kTextMuted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "Can Supply",
                                          style: TextStyle(
                                            color: kGold,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(color: kBorder, height: 1),

                                // Rows
                                ...List.generate(_invoice!.items.length, (i) {
                                  final item = _invoice!.items[i];
                                  final ctrl = _confirmedQtyControllers[item.id];
                                  final isPending = _invoice!.status == 'pending';

                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            // Image
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: SizedBox(
                                                width: 44,
                                                height: 44,
                                                child: item.imageUrl.isNotEmpty
                                                    ? Image.network(
                                                        item.imageUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) =>
                                                            Container(
                                                          color: kBorder,
                                                          child: const Icon(
                                                            Icons.inventory_2_outlined,
                                                            color: kTextMuted,
                                                            size: 18,
                                                          ),
                                                        ),
                                                      )
                                                    : Container(
                                                        color: kBorder,
                                                        child: const Icon(
                                                          Icons.inventory_2_outlined,
                                                          color: kTextMuted,
                                                          size: 18,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Name & Category
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.productName,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Text(
                                                    item.category,
                                                    style: const TextStyle(
                                                      color: kTextMuted,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Qty Requested
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                "${item.qtyRequested} pcs",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),

                                            // Qty Can Supply
                                            Expanded(
                                              flex: 2,
                                              child: isPending && ctrl != null
                                                  ? SizedBox(
                                                      height: 38,
                                                      child: TextField(
                                                        controller: ctrl,
                                                        keyboardType: TextInputType.number,
                                                        style: const TextStyle(
                                                          color: kGold,
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 13,
                                                        ),
                                                        decoration: InputDecoration(
                                                          filled: true,
                                                          fillColor: kCard,
                                                          contentPadding: const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 8,
                                                          ),
                                                          border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: const BorderSide(color: kGold),
                                                          ),
                                                          enabledBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: const BorderSide(color: kGold),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : Text(
                                                      "${item.qtyConfirmed ?? item.qtyRequested} pcs",
                                                      style: TextStyle(
                                                        color: (item.qtyConfirmed != null && item.qtyConfirmed! < item.qtyRequested)
                                                            ? Colors.orangeAccent
                                                            : Colors.greenAccent,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (i < _invoice!.items.length - 1)
                                        const Divider(color: kBorder, height: 1),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Footer Actions for Pending Orders
                          if (_invoice!.status == 'pending') ...[
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _isSubmitting ? null : _rejectOrder,
                                  icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
                                  label: const Text(
                                    "Reject order",
                                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.redAccent),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                const Spacer(),
                                OutlinedButton(
                                  onPressed: _isSubmitting ? null : _partialConfirm,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: kGold),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text(
                                    "Confirm partial",
                                    style: TextStyle(color: kGold, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _isSubmitting ? null : _confirmAll,
                                  icon: const Icon(Icons.check_circle_outline, color: kDark, size: 18),
                                  label: const Text(
                                    "Confirm all",
                                    style: TextStyle(color: kDark, fontWeight: FontWeight.w700),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kGold,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
        ),

        
      ),
    );
  }
}

// ==========================================
// 2. UPLOAD DELIVERY RECEIPT OVERLAY
// ==========================================
class _UploadDeliveryReceiptDialog {
  static Future<bool?> show(BuildContext context, {required PurchaseInvoice invoice}) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Upload Receipt",
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => _UploadDeliveryReceiptForm(invoice: invoice),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8 * anim.value, sigmaY: 8 * anim.value),
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

class _UploadDeliveryReceiptForm extends StatefulWidget {
  final PurchaseInvoice invoice;
  const _UploadDeliveryReceiptForm({required this.invoice});

  @override
  State<_UploadDeliveryReceiptForm> createState() => _UploadDeliveryReceiptFormState();
}

class _UploadDeliveryReceiptFormState extends State<_UploadDeliveryReceiptForm> {
  final SupplierController _controller = SupplierController();

  PlatformFile? _pickedFile;
  int _fileSizeBytes = 0;
  final _noteController = TextEditingController();
  final DateTime _deliveryDate = DateTime.now();
  bool _isUploading = false;

  Future<void> _pickPDF() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (files.isNotEmpty) {
        final picked = files.first;
        final size = await picked.length();
        setState(() {
          _pickedFile = picked;
          _fileSizeBytes = size ?? 0;
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: "File picker error: $e", type: ToastType.error);
      }
    }
  }

  Future<void> _submit() async {
    setState(() => _isUploading = true);

    List<int>? fileBytes;
    if (_pickedFile != null) {
      fileBytes = await _pickedFile!.readAsBytes();
    }

    final res = await _controller.uploadDelivery(
      invoiceId: widget.invoice.id,
      fileBytes: fileBytes,
      fileName: _pickedFile?.name,
      deliveryDate: _deliveryDate.toIso8601String(),
      note: _noteController.text.trim(),
    );

    if (mounted) {
      setState(() => _isUploading = false);
      if (res['success'] == true) {
        AppToast.show(context, message: "Delivery receipt uploaded! Status updated to Shipped.");
        Navigator.of(context).pop(true);
      } else {
        AppToast.show(context, message: res['message'] ?? "Upload failed", type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 500,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.upload_file, color: Colors.lightBlueAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Upload Delivery Receipt",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        "Order ${widget.invoice.formattedId}",
                        style: const TextStyle(color: kTextMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: kTextMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Employee", style: TextStyle(color: kTextMuted, fontSize: 11)),
                        Text(widget.invoice.employeeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Items & Qty", style: TextStyle(color: kTextMuted, fontSize: 11)),
                        Text("${widget.invoice.productsCount} items / ${widget.invoice.totalQty} pcs", style: const TextStyle(color: kGold, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // File Picker Box
              InkWell(
                onTap: _pickPDF,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _pickedFile != null ? kGold : kBorder,
                      width: _pickedFile != null ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _pickedFile != null ? Icons.picture_as_pdf : Icons.cloud_upload_outlined,
                        color: _pickedFile != null ? Colors.redAccent : kGold,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pickedFile != null ? _pickedFile!.name : "Click to select PDF receipt",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _pickedFile != null
                            ? "${(_fileSizeBytes / 1024).toStringAsFixed(1)} KB"
                            : "Supports .pdf files",
                        style: const TextStyle(color: kTextMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Note Input
              TextField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Delivery note / Tracking info (optional)",
                  labelStyle: const TextStyle(color: kTextMuted, fontSize: 12),
                  filled: true,
                  fillColor: kDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGold)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isUploading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kDark))
                      : const Text("Submit & Mark as Shipped", style: TextStyle(color: kDark, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. REJECT INVOICE DIALOG OVERLAY
// ==========================================
class _RejectInvoiceDialog {
  static Future<String?> show(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: kBorder)),
        title: const Text("Reject Order", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Provide an optional reason for rejecting this order:",
              style: TextStyle(color: kTextMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "e.g. Item out of stock for 2 weeks",
                hintStyle: const TextStyle(color: kTextMuted, fontSize: 12),
                filled: true,
                fillColor: kDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel", style: TextStyle(color: kTextMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Reject", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
