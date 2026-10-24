import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app_store/models/manager_dashboard.dart';
import 'package:app_store/widgets/manager/manager_components.dart';

class ManagerCharts extends StatelessWidget {
  final ManagerDashboard dashboard;
  final ValueChanged<String> onStatusSelected;
  const ManagerCharts({
    super.key,
    required this.dashboard,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final invoices = _InvoiceChart(
        statuses: dashboard.invoiceStatuses,
        onSelected: onStatusSelected,
      );
      final categories = <String, int>{};
      for (final product in dashboard.products) {
        final category = product.category.trim().isEmpty
            ? 'Uncategorized'
            : product.category.trim();
        categories[category] =
            (categories[category] ?? 0) + math.max(0, product.stock);
      }
      final stock = _CategoryChart(categories: categories);
      return constraints.maxWidth >= 850
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: invoices),
                const SizedBox(width: 16),
                Expanded(child: stock),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [invoices, const SizedBox(height: 16), stock],
            );
    },
  );
}

class _ChartCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: ManagerColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ManagerColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: ManagerColors.muted)),
        const SizedBox(height: 24),
        child,
      ],
    ),
  );
}

const _statusColors = <String, Color>{
  'pending': ManagerColors.gold,
  'confirmed': Colors.purpleAccent,
  'shipped': Colors.lightBlueAccent,
  'completed': Colors.greenAccent,
  'rejected': Colors.redAccent,
};

class _InvoiceChart extends StatelessWidget {
  final Map<String, int> statuses;
  final ValueChanged<String> onSelected;
  const _InvoiceChart({required this.statuses, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final entries = statuses.entries.where((entry) => entry.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0, (sum, entry) => sum + entry.value);
    final donut = Semantics(
      label: '$total purchase invoices by status',
      child: SizedBox(
        width: 176,
        height: 176,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DonutPainter(
                  entries.map((entry) => entry.value).toList(),
                  entries
                      .map(
                        (entry) => _statusColors[entry.key] ?? Colors.blueGrey,
                      )
                      .toList(),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Invoices',
                  style: TextStyle(color: ManagerColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    final legend = Column(
      mainAxisSize: MainAxisSize.min,
      children: entries.map((entry) {
        final percent = entry.value / total * 100;
        return Tooltip(
          message: 'View ${entry.key} invoices',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSelected(entry.key),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _statusColors[entry.key] ?? Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(entry.key, overflow: TextOverflow.ellipsis),
                  ),
                  Text(
                    '${entry.value}  (${percent.toStringAsFixed(0)}%)',
                    style: const TextStyle(color: ManagerColors.muted),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
    return _ChartCard(
      title: 'Invoices by status',
      subtitle: 'Select a status to view its invoices.',
      child: total == 0
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  'No invoices yet.',
                  style: TextStyle(color: ManagerColors.muted),
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth >= 420
                  ? Row(
                      children: [
                        donut,
                        const SizedBox(width: 24),
                        Expanded(child: legend),
                      ],
                    )
                  : Column(
                      children: [
                        Center(child: donut),
                        const SizedBox(height: 16),
                        legend,
                      ],
                    ),
            ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<int> values;
  final List<Color> colors;
  _DonutPainter(this.values, this.colors);
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 22.0;
    final bounds = Offset.zero & size;
    final rect = bounds.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawOval(rect, paint..color = ManagerColors.border);
    final total = values.fold(0, (sum, value) => sum + value);
    if (total == 0) return;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      final gap = values.length == 1 ? 0.0 : math.min(.045, sweep / 4);
      canvas.drawArc(
        rect,
        start + gap / 2,
        sweep - gap,
        false,
        paint..color = colors[i],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

class _CategoryChart extends StatelessWidget {
  final Map<String, int> categories;
  const _CategoryChart({required this.categories});
  @override
  Widget build(BuildContext context) {
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visible = sorted.take(5).toList();
    if (sorted.length > 5) {
      visible.add(
        MapEntry(
          'Remaining categories',
          sorted.skip(5).fold(0, (sum, entry) => sum + entry.value),
        ),
      );
    }
    final maximum = visible.fold(
      0,
      (largest, entry) => math.max(largest, entry.value),
    );
    return _ChartCard(
      title: 'Stock by category',
      subtitle: 'Available units across active products.',
      child: maximum == 0
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  'No stock available.',
                  style: TextStyle(color: ManagerColors.muted),
                ),
              ),
            )
          : Column(
              children: visible
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Semantics(
                        label: '${entry.key}: ${entry.value} units',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${entry.value} units',
                                  style: const TextStyle(
                                    color: ManagerColors.muted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Tooltip(
                              message: '${entry.key}: ${entry.value} units',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: entry.value / maximum,
                                  minHeight: 16,
                                  backgroundColor: ManagerColors.border,
                                  color: ManagerColors.gold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
