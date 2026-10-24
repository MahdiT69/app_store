import 'package:app_store/widgets/login_form.dart';
import 'package:flutter/material.dart';

import 'package:app_store/controllers/cart_controller.dart';
import 'package:app_store/controllers/auth_session.dart';

import 'success_dialog.dart';

import 'package:app_store/utils/toast.dart';

const kCard = Color(0xFF1E1E23);
const kBorder = Color(0xFF2C2C33);
const kGold = Color(0xFFD4A94D);
const kTextMuted = Color(0xFF9A9AA5);

class CartPanel {
  static void open(BuildContext context, VoidCallback onChanged) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,

        barrierColor: Colors.black.withValues(alpha: 0.5),

        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),

        pageBuilder: (context, animation, secondaryAnimation) {
          return _CartPanelContent(onChanged: onChanged);
        },

        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          final slideAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation);

          final fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(curvedAnimation);

          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
      ),
    );
  }
}

class _CartPanelContent extends StatefulWidget {
  final VoidCallback onChanged;
  const _CartPanelContent({required this.onChanged});

  @override
  State<_CartPanelContent> createState() => _CartPanelContentState();
}

class _CartPanelContentState extends State<_CartPanelContent> {
  bool _isProcessing = false;

  void _handleCheckout() async {
    if (!AuthSession.instance.isLoggedIn) {
      AppToast.show(
        context,
        message: "Please sign in to checkout.",
        type: ToastType.error,
      );
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) LoginDialog.show(context);
      return;
    }

    setState(() => _isProcessing = true);

    // TODO: call your /orders API here with CartController.instance.lines
    await Future.delayed(const Duration(milliseconds: 600)); // simulate request

    if (!mounted) return;
    setState(() => _isProcessing = false);

    CartController.instance.clear();
    widget.onChanged();
    Navigator.of(context).pop();

    if (mounted) {
      SuccessDialog.show(
        context,
        title: "Order placed!",
        message: "Your order is confirmed. Expect delivery within 24 hours.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = CartController.instance.lines;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: kCard,
        child: SizedBox(
          width: 400,
          height: double.infinity,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Text(
                        "Your cart",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: kTextMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: kBorder, height: 1),
                Expanded(
                  child: lines.isEmpty
                      ? const Center(
                          child: Text(
                            "Your cart is empty.",
                            style: TextStyle(color: kTextMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: lines.length,
                          separatorBuilder: (context, index) =>
                              const Divider(color: kBorder),
                          itemBuilder: (context, index) {
                            final line = lines[index];
                            return Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        line.product.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "\$${line.product.price.toStringAsFixed(2)} each",
                                        style: const TextStyle(
                                          color: kTextMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          CartController.instance.setQuantity(
                                            line.product.id,
                                            line.quantity - 1,
                                          );
                                          setState(() {});
                                          widget.onChanged();
                                        },
                                      ),
                                      Text(
                                        "${line.quantity}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          CartController.instance.setQuantity(
                                            line.product.id,
                                            line.quantity + 1,
                                          );
                                          setState(() {});
                                          widget.onChanged();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: kTextMuted,
                                  ),
                                  onPressed: () {
                                    CartController.instance.remove(
                                      line.product.id,
                                    );
                                    setState(() {});
                                    widget.onChanged();
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: kBorder)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            "\$${CartController.instance.total.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: kGold,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: lines.isEmpty || _isProcessing
                            ? null
                            : _handleCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGold,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF16161A),
                                ),
                              )
                            : const Text(
                                "Checkout",
                                style: TextStyle(
                                  color: Color(0xFF16161A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ],
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
