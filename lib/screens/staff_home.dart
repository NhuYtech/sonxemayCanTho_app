import 'package:flutter/material.dart';

class StaffHome extends StatelessWidget {
  const StaffHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Home')),
      body: const Center(child: Text('Trang nhân viên')),
    );
  }
}
