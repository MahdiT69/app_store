import 'package:app_store/views/customer/home_view.dart';
import 'package:flutter/material.dart';
import 'package:app_store/controllers/auth_session.dart';
import 'package:app_store/controllers/manager_controller.dart';
import 'package:app_store/models/manager_dashboard.dart';
import 'package:app_store/utils/toast.dart';
import 'package:app_store/widgets/manager/create_manager_user_dialog.dart';
import 'package:app_store/widgets/manager/manager_components.dart';
import 'package:app_store/widgets/manager/manager_charts.dart';
import 'package:app_store/widgets/manager/manager_invoice_dialog.dart';

class ManagerHomeView extends StatefulWidget {
  final ManagerController? controller;
  const ManagerHomeView({super.key, this.controller});
  @override
  State<ManagerHomeView> createState() => _ManagerHomeViewState();
}

class _ManagerHomeViewState extends State<ManagerHomeView> {
  late final _controller = widget.controller ?? ManagerController();
  final _searchController = TextEditingController();
  ManagerDashboard? _data;
  bool _loading = true;
  String? _error;
  int _tab = 0;
  String _search = '', _status = 'all', _role = 'all', _stock = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _controller.fetchDashboard();
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _createUser() async {
    final created = await CreateManagerUserDialog.show(
      context,
      _controller,
      role: _role == 'supplier' ? 'supplier' : 'employee',
    );
    if (created == true && mounted) {
      AppToast.show(context, message: 'Account created successfully.');
      await _load();
    }
  }

  bool _matches(String value) => value.toLowerCase().contains(_search);

  void _selectTab(int value) => setState(() {
    _tab = value;
    _search = '';
    _searchController.clear();
  });

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: ManagerColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ManagerColors.gold,
        brightness: Brightness.dark,
        primary: ManagerColors.gold,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: ManagerColors.card,
        border: OutlineInputBorder(),
        isDense: true,
      ),
    ),
    child: Scaffold(
      appBar: AppBar(
        backgroundColor: ManagerColors.background,
        title: const Text(
          'SHOPYME · Manager',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
                tooltip: "Preview website",
                icon: const Icon(Icons.visibility_outlined),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const HomeView(isPreview: true)));
                },
              ),
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (_) => AuthSession.instance.logout(),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  '${AuthSession.instance.prenom} ${AuthSession.instance.nom}',
                ),
              ),
              const PopupMenuItem(value: 'logout', child: Text('Disconnect')),
            ],
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Overview'),
                    icon: Icon(Icons.dashboard_outlined),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Products'),
                    icon: Icon(Icons.inventory_2_outlined),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('Invoices'),
                    icon: Icon(Icons.receipt_long_outlined),
                  ),
                  ButtonSegment(
                    value: 3,
                    label: Text('Team & suppliers'),
                    icon: Icon(Icons.people_outline),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (values) => _selectTab(values.first),
              ),
            ),
          ),
          Expanded(
            child: _data == null
                ? Center(
                    child: _loading
                        ? const CircularProgressIndicator()
                        : _errorPanel(),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_error != null) _errorPanel(),
                              if (_tab == 0)
                                _overview(_data!)
                              else ...[
                                _toolbar(),
                                const SizedBox(height: 20),
                                switch (_tab) {
                                  1 => _products(_data!),
                                  2 => _invoices(
                                    _data!.invoices
                                        .where(
                                          (entry) =>
                                              (_status == 'all' ||
                                                  entry.invoice.status ==
                                                      _status) &&
                                              _matches(
                                                '${entry.invoice.formattedId} ${entry.supplier} ${entry.invoice.employeeName}',
                                              ),
                                        )
                                        .toList(),
                                  ),
                                  _ => _users(_data!),
                                },
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );

  Widget _errorPanel() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Could not refresh the dashboard. ${_error ?? ''}',
          style: const TextStyle(color: Colors.redAccent),
        ),
        TextButton.icon(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );

  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: ManagerColors.muted)),
      ],
    ),
  );

  Widget _overview(ManagerDashboard data) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(
        'Store overview',
        'Inventory, purchasing and the people keeping your store running.',
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 4
              : constraints.maxWidth >= 550
              ? 2
              : 1;
          final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
          final cards = [
            ManagerStatCard(
              label: 'Active products',
              value: '${data.count('products')}',
              icon: Icons.inventory_2_outlined,
            ),
            ManagerStatCard(
              label: 'Stock value · TND',
              value: data.stockValue.toStringAsFixed(2),
              icon: Icons.payments_outlined,
            ),
            ManagerStatCard(
              label: 'Low stock · 10 units or fewer',
              value: '${data.count('low_stock')}',
              icon: Icons.warning_amber_rounded,
              color: Colors.orangeAccent,
            ),
            ManagerStatCard(
              label: 'Purchase invoices',
              value: '${data.count('invoices')}',
              icon: Icons.receipt_long_outlined,
            ),
            ManagerStatCard(
              label: 'Units in stock',
              value: '${data.count('stock_units')}',
              icon: Icons.warehouse_outlined,
            ),
            ManagerStatCard(
              label: 'Pending invoices',
              value: '${data.invoiceStatuses['pending'] ?? 0}',
              icon: Icons.hourglass_top,
            ),
            ManagerStatCard(
              label: 'Employees',
              value: '${data.count('employees')}',
              icon: Icons.badge_outlined,
            ),
            ManagerStatCard(
              label: 'Suppliers',
              value: '${data.count('suppliers')}',
              icon: Icons.local_shipping_outlined,
            ),
          ];
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: cards
                .map((card) => SizedBox(width: width, child: card))
                .toList(),
          );
        },
      ),
      const SizedBox(height: 28),
      ManagerCharts(
        dashboard: data,
        onStatusSelected: (status) => setState(() {
          _status = status;
          _tab = 2;
          _search = '';
          _searchController.clear();
        }),
      ),
      const SizedBox(height: 28),
      const Text(
        'Invoice activity',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: ['pending', 'confirmed', 'shipped', 'completed', 'rejected']
            .map(
              (status) => ActionChip(
                label: Text('$status · ${data.invoiceStatuses[status] ?? 0}'),
                onPressed: () => setState(() {
                  _status = status;
                  _tab = 2;
                  _search = '';
                  _searchController.clear();
                }),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 28),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Recent purchase invoices',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () {
              _status = 'all';
              _selectTab(2);
            },
            child: const Text('View all'),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _invoices(data.invoices.take(5).toList()),
      const SizedBox(height: 28),
      const Text(
        'Stock alerts',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 14),
      ManagerTable(
        columns: const ['Product', 'Category', 'Stock', 'Status'],
        emptyMessage: 'All products are above the low-stock threshold.',
        rows:
            (data.products.where((p) => p.stock <= 10).toList()
                  ..sort((a, b) => a.stock.compareTo(b.stock)))
                .take(10)
                .map(
                  (p) => DataRow(
                    cells: [
                      DataCell(Text(p.name)),
                      DataCell(Text(p.category)),
                      DataCell(Text('${p.stock}')),
                      DataCell(
                        ManagerStatusBadge(
                          p.stock <= 0 ? 'out of stock' : 'low stock',
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
      ),
    ],
  );

  Widget _filter(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> onChanged,
  ) => SizedBox(
    width: 190,
    child: DropdownButtonFormField<String>(
      isExpanded: true,
      key: ValueKey('$label-$value'),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    ),
  );

  Widget _toolbar() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(
        ['Overview', 'Products', 'Purchase invoices', 'Team & suppliers'][_tab],
        [
          'Overview',
          'Track active inventory, prices and stock levels.',
          'Follow orders from request through delivery.',
          'Create and find employee and supplier accounts.',
        ][_tab],
      ),
      Wrap(
        spacing: 14,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _search = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: _tab == 1
                    ? 'Search products or categories'
                    : _tab == 2
                    ? 'Search invoice, supplier or employee'
                    : 'Search name, username, CIN or phone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => setState(() {
                          _search = '';
                          _searchController.clear();
                        }),
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          if (_tab == 1)
            _filter('Stock', _stock, [
              'all',
              'in stock',
              'low stock',
              'out of stock',
            ], (value) => setState(() => _stock = value)),
          if (_tab == 2)
            _filter('Status', _status, [
              'all',
              'pending',
              'confirmed',
              'shipped',
              'completed',
              'rejected',
            ], (value) => setState(() => _status = value)),
          if (_tab == 3) ...[
            _filter('Role', _role, [
              'all',
              'employee',
              'supplier',
            ], (value) => setState(() => _role = value)),
            FilledButton.icon(
              onPressed: _loading ? null : _createUser,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Create account'),
            ),
          ],
        ],
      ),
    ],
  );

  Widget _products(ManagerDashboard data) {
    final products = data.products.where(
      (p) =>
          _matches('${p.name} ${p.category}') &&
          switch (_stock) {
            'in stock' => p.stock > 10,
            'low stock' => p.stock > 0 && p.stock <= 10,
            'out of stock' => p.stock <= 0,
            _ => true,
          },
    );
    return ManagerTable(
      columns: const [
        'Product',
        'Category',
        'Price · TND',
        'Stock',
        'Stock value · TND',
        'Status',
      ],
      rows: products
          .map(
            (p) => DataRow(
              cells: [
                DataCell(Text(p.name)),
                DataCell(Text(p.category)),
                DataCell(Text(p.price.toStringAsFixed(2))),
                DataCell(Text('${p.stock}')),
                DataCell(Text((p.price * p.stock).toStringAsFixed(2))),
                DataCell(
                  ManagerStatusBadge(
                    p.stock <= 0
                        ? 'out of stock'
                        : p.stock <= 10
                        ? 'low stock'
                        : 'in stock',
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _invoices(List<ManagerInvoice> invoices) => ManagerTable(
    columns: const [
      'Invoice',
      'Supplier',
      'Employee',
      'Date',
      'Items',
      'Quantity',
      'Status',
      '',
    ],
    rows: invoices.map((entry) {
      final invoice = entry.invoice;
      final date = invoice.createdAt;
      return DataRow(
        cells: [
          DataCell(Text(invoice.formattedId)),
          DataCell(Text(entry.supplier)),
          DataCell(Text(invoice.employeeName)),
          DataCell(
            Text(date == null ? '-' : '${date.day}/${date.month}/${date.year}'),
          ),
          DataCell(Text('${invoice.productsCount}')),
          DataCell(Text('${invoice.totalQty}')),
          DataCell(ManagerStatusBadge(invoice.status)),
          DataCell(
            IconButton(
              tooltip: 'View invoice',
              icon: const Icon(Icons.open_in_new, size: 18),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ManagerInvoiceDialog(
                  controller: _controller,
                  invoiceId: invoice.id,
                  supplier: entry.supplier,
                ),
              ),
            ),
          ),
        ],
      );
    }).toList(),
  );

  Widget _users(ManagerDashboard data) => ManagerTable(
    columns: const ['Name', 'Username', 'Role', 'CIN', 'Phone'],
    rows: data.users
        .where(
          (u) =>
              (_role == 'all' || u.role == _role) &&
              _matches('${u.name} ${u.id} ${u.cin} ${u.phone}'),
        )
        .map(
          (u) => DataRow(
            cells: [
              DataCell(Text(u.name)),
              DataCell(Text(u.id)),
              DataCell(ManagerStatusBadge(u.role)),
              DataCell(Text(u.cin)),
              DataCell(Text(u.phone.isEmpty ? '-' : u.phone)),
            ],
          ),
        )
        .toList(),
  );
}
