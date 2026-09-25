import 'package:flutter/material.dart';

class ReceiptCard extends StatelessWidget {
  const ReceiptCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: const Text('Item Name: Laptop Asus'),
        subtitle: const Text('Store: Tokopedia'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Lunas',
            style: TextStyle(color: Colors.green),
          ),
        ),
      ),
    );
  }
}
