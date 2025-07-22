import 'package:flutter/material.dart';
import 'create_repair_order.dart';

class StaffHome extends StatelessWidget {
  final String name;
  const StaffHome({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Xin chào, $name')),
      body: const Center(child: Text('Trang chủ nhân viên')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateRepairOrderScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
