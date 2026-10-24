import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:app_store/controllers/employee_controller.dart';
import 'package:app_store/controllers/auth_session.dart';
import 'package:app_store/models/product.dart';
import 'package:app_store/models/supplier.dart';
import 'package:app_store/utils/toast.dart';

const kDark = Color(0xFF16161A);
const kCard = Color(0xFF1E1E23);
const kBorder = Color(0xFF2C2C33);
const kGold = Color(0xFFD4A94D);
const kTextMuted = Color(0xFF9A9AA5);

class OrderQtyDialog {
  static Future<bool?> show(BuildContext context, {required Product product}) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Order quantity",
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => _OrderQtyForm(product: product),
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

class _OrderQtyForm extends StatefulWidget {
  final Product product;
  const _OrderQtyForm({required this.product});

  @override
  State<_OrderQtyForm> createState() => _OrderQtyFormState();
}

class _OrderQtyFormState extends State<_OrderQtyForm> {
  final EmployeeController _controller = EmployeeController();
  final _qtyController = TextEditingController();

  List<Supplier> _suppliers = [];
  Supplier? _selectedSupplier;
  bool _isLoadingSuppliers = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    final suppliers = await _controller.fetchSuppliers();
    setState(() {
      _suppliers = suppliers;
      _isLoadingSuppliers = false;
      if (suppliers.isNotEmpty) _selectedSupplier = suppliers.first;
    });
  }

  Future<void> _submit() async {
    final qty = int.tryParse(_qtyController.text.trim());
    if (_selectedSupplier == null) {
      AppToast.show(
        context,
        message: "Select a supplier.",
        type: ToastType.error,
      );
      return;
    }
    if (qty == null || qty <= 0) {
      AppToast.show(
        context,
        message: "Enter a valid quantity.",
        type: ToastType.error,
      );
      return;
    }

    final employeeId = AuthSession.instance.currentUser?['id_user'];
    if (employeeId == null) {
      AppToast.show(
        context,
        message: "Session error, please re-login.",
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await _controller.createInvoice(
      supplierId: _selectedSupplier!.id,
      createdBy: employeeId,
      items: [
        {"product_id": widget.product.id, "qty_requested": qty},
      ],
    );
    setState(() => _isSubmitting = false);

    if (mounted) {
      if (result['success'] == true) {
        Navigator.of(context).pop(true);
      } else {
        AppToast.show(
          context,
          message: result['message'] ?? "Failed to send order",
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Order more — ${widget.product.name}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: kTextMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Current stock: ${widget.product.stock}",
                style: const TextStyle(color: kTextMuted, fontSize: 12),
              ),
              const SizedBox(height: 20),

              const Text(
                "Supplier",
                style: TextStyle(
                  color: kTextMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _isLoadingSuppliers
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(
                        color: kGold,
                        backgroundColor: kBorder,
                      ),
                    )
                  : _suppliers.isEmpty
                  ? const Text(
                      "No suppliers found.",
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: kDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Supplier>(
                          value: _selectedSupplier,
                          isExpanded: true,
                          dropdownColor: kCard,
                          style: const TextStyle(color: Colors.white),
                          iconEnabledColor: kTextMuted,
                          onChanged: (s) =>
                              setState(() => _selectedSupplier = s),
                          items: _suppliers
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.fullName),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),

              const SizedBox(height: 18),
              const Text(
                "Quantity needed",
                style: TextStyle(
                  color: kTextMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "e.g. 50",
                  hintStyle: const TextStyle(color: kTextMuted),
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
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 14,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kDark,
                          ),
                        )
                      : const Text(
                          "Send order to supplier",
                          style: TextStyle(
                            color: kDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
