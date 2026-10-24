import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_store/controllers/manager_controller.dart';
import 'package:app_store/utils/manager_api_provider.dart';
import 'package:app_store/views/manager/manager_home_view.dart';
import 'package:app_store/widgets/manager/create_manager_user_dialog.dart';

class FakeManagerApi extends ManagerApiProvider {
  Map<String, dynamic>? created;
  bool fail = false;
  @override
  Future<Map<String, dynamic>> dashboard() async {
    if (fail) throw Exception('Offline');
    return {
      'stats': {
        'products': 2,
        'stock_value': 200.0,
        'low_stock': 1,
        'invoices': 1,
        'stock_units': 25,
        'employees': 1,
        'suppliers': 1,
        'invoice_statuses': {'pending': 1},
      },
      'products': [
        {
          'id': 1,
          'name': 'Keyboard',
          'price': '10',
          'stock': 5,
          'category': 'Electronics',
        },
        {
          'id': 2,
          'name': 'Desk',
          'price': '20',
          'stock': 20,
          'category': 'Furniture',
        },
      ],
      'invoices': [
        {
          'id': 1,
          'supplier_id': 'supplier1',
          'supplier_name': 'Supplier One',
          'employee_name': 'Employee One',
          'status': 'pending',
          'created_at': '2026-10-24T12:00:00Z',
          'products_count': 1,
          'total_qty': 3,
        },
      ],
      'users': [
        {
          'id_user': 'employee1',
          'nom': 'One',
          'prenom': 'Employee',
          'cin': 1234567,
          'teleph': '12345678',
          'role': 'employee',
        },
      ],
    };
  }

  @override
  Future<void> createUser(Map<String, dynamic> user) async {
    created = user;
  }

  @override
  Future<Map<String, dynamic>> invoice(int id) async => {
    'invoice': {
      'id': id,
      'employee_name': 'Employee One',
      'status': 'pending',
      'items': [
        {
          'id': 1,
          'product_id': 1,
          'product_name': 'Keyboard',
          'qty_requested': 3,
        },
      ],
    },
  };
}

void main() {
  Future<void> mount(
    WidgetTester tester,
    FakeManagerApi api, {
    Size size = const Size(1440, 1000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: ManagerHomeView(controller: ManagerController(api: api)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('dashboard, search, invoice details and directory', (
    tester,
  ) async {
    await mount(tester, FakeManagerApi());
    expect(find.text('Store overview'), findsOneWidget);
    expect(find.text('200.00'), findsOneWidget);
    await tester.tap(find.text('Products').first);
    await tester.pumpAndSettle();
    expect(find.text('Desk'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'keyboard');
    await tester.pumpAndSettle();
    expect(find.text('Desk'), findsNothing);
    expect(find.text('Keyboard'), findsOneWidget);
    await tester.tap(find.text('Invoices').first);
    await tester.pumpAndSettle();
    expect(find.text('24/10/2026'), findsOneWidget);
    await tester.tap(find.byTooltip('View invoice'));
    await tester.pumpAndSettle();
    expect(find.text('Purchase order #INV-0001'), findsOneWidget);
    expect(find.text('Keyboard'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team & suppliers').first);
    await tester.pumpAndSettle();
    expect(find.text('01234567'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account form validates and submits supplier credentials', (
    tester,
  ) async {
    final api = FakeManagerApi();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => CreateManagerUserDialog.show(
                context,
                ManagerController(api: api),
                role: 'supplier',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(api.created, isNull);
    final values = [
      'supplier2',
      'First',
      'Last',
      '01234567',
      '12345678',
      'secret',
    ];
    for (var i = 0; i < values.length; i++) {
      await tester.ensureVisible(find.byType(TextFormField).at(i));
      await tester.enterText(find.byType(TextFormField).at(i), values[i]);
    }
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(api.created?['role'], 'supplier');
    expect(api.created?['cin'], '01234567');
    expect(api.created?['pw_user'], 'secret');
    expect(find.text('Create team account'), findsNothing);
  });

  testWidgets('narrow dashboard and error retry render without overflow', (
    tester,
  ) async {
    final api = FakeManagerApi()..fail = true;
    await mount(tester, api, size: const Size(390, 844));
    expect(find.textContaining('Offline'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Store overview'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
