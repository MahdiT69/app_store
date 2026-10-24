import 'package:flutter/material.dart';

import '../controllers/auth_session.dart';

import 'package:app_store/views/employee/employee_home_view.dart';
import 'package:app_store/views/supplier/supplier_home_view.dart';
import 'package:app_store/views/manager/manager_home_view.dart';
import 'package:app_store/views/customer/home_view.dart';

class RoleRouter {
  static Widget resolveHome() {
    final role = AuthSession.instance.currentUser?['role'];

    switch (role) {
      case 'employee':
        return const EmployeeHomeView();
      case 'supplier':
        return const SupplierHomeView();
      case 'manager':
        return const ManagerHomeView();
      case 'customer':
      default:
        return const HomeView();
    }
  }
}
