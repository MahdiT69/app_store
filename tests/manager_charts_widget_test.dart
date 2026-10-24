import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_store/models/manager_dashboard.dart';
import 'package:app_store/widgets/manager/manager_charts.dart';

import 'manager_dashboard_widget_test.dart' show FakeManagerApi;

void main() {
  testWidgets('charts show real totals and status selection on both layouts', (
    tester,
  ) async {
    final data = await FakeManagerApi().dashboard();
    data['stats']['invoice_statuses'] = {'pending': 3, 'completed': 1};
    final dashboard = ManagerDashboard.fromJson(data);
    String? selected;
    for (final width in [1200.0, 350.0]) {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ManagerCharts(
                dashboard: dashboard,
                onStatusSelected: (value) => selected = value,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3  (75%)'), findsOneWidget);
      expect(find.text('1  (25%)'), findsOneWidget);
      expect(find.text('20 units'), findsOneWidget);
      expect(find.text('5 units'), findsOneWidget);
      await tester.tap(find.text('completed'));
      expect(selected, 'completed');
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('empty charts show clear empty states', (tester) async {
    final dashboard = ManagerDashboard.fromJson({
      'stats': {'invoice_statuses': {}},
      'products': [],
      'invoices': [],
      'users': [],
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ManagerCharts(
              dashboard: dashboard,
              onStatusSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('No invoices yet.'), findsOneWidget);
    expect(find.text('No stock available.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('extra categories are grouped without dropping stock', (
    tester,
  ) async {
    final data = await FakeManagerApi().dashboard();
    data['products'] = List.generate(
      7,
      (i) => {
        'id': i,
        'name': 'Product $i',
        'price': 1,
        'stock': i + 1,
        'category': 'Category $i',
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ManagerCharts(
              dashboard: ManagerDashboard.fromJson(data),
              onStatusSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Remaining categories'), findsOneWidget);
    expect(find.text('7 units'), findsOneWidget);
    expect(
      find.text('3 units'),
      findsNWidgets(2),
    ); // Category 2 plus categories 0 and 1 combined.
    expect(tester.takeException(), isNull);
  });
}
