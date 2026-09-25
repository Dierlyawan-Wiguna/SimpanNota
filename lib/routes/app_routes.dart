import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/add_receipt_screen.dart';
import '../screens/detail_screen.dart';

class AppRoutes {
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String addReceiptRoute = '/add_receipt';
  static const String detailRoute = '/detail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case dashboardRoute:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case addReceiptRoute:
        return MaterialPageRoute(builder: (_) => const AddReceiptScreen());
      case detailRoute:
        return MaterialPageRoute(builder: (_) => const DetailScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
