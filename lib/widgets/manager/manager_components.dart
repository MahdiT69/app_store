import 'package:flutter/material.dart';

class ManagerColors {
  static const background = Color(0xFF16161A);
  static const card = Color(0xFF1E1E23);
  static const border = Color(0xFF2C2C33);
  static const gold = Color(0xFFD4A94D);
  static const muted = Color(0xFF9A9AA5);
}

class ManagerStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const ManagerStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = ManagerColors.gold,
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
        Icon(icon, color: color),
        const SizedBox(height: 14),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: ManagerColors.muted)),
      ],
    ),
  );
}

class ManagerStatusBadge extends StatelessWidget {
  final String status;
  const ManagerStatusBadge(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' || 'in stock' => Colors.greenAccent,
      'shipped' || 'confirmed' => Colors.lightBlueAccent,
      'rejected' || 'out of stock' => Colors.redAccent,
      _ => ManagerColors.gold,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

class ManagerTable extends StatelessWidget {
  final List<String> columns;
  final List<DataRow> rows;
  final String emptyMessage;
  const ManagerTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyMessage = 'No results found.',
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: ManagerColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ManagerColors.border),
    ),
    child: rows.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ManagerColors.muted),
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingTextStyle: const TextStyle(
                    color: ManagerColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                  dataTextStyle: const TextStyle(color: Colors.white),
                  dividerThickness: .4,
                  columns: columns
                      .map((c) => DataColumn(label: Text(c)))
                      .toList(),
                  rows: rows,
                ),
              ),
            ),
          ),
  );
}
