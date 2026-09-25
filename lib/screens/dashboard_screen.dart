import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../widgets/receipt_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SimpanNota'),
      ),
      body: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.detailRoute);
            },
            child: const ReceiptCard(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addReceiptRoute);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
