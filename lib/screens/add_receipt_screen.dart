import 'package:flutter/material.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class AddReceiptScreen extends StatefulWidget {
  const AddReceiptScreen({super.key});

  @override
  State<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends State<AddReceiptScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _storeController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    _storeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Nota')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              labelText: 'Nama Barang',
              controller: _itemController,
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: 'Nama Toko',
              controller: _storeController,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Simpan',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
