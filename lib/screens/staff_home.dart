import 'package:flutter/material.dart';

class StaffHome extends StatelessWidget {
  final String name;
  const StaffHome({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Xin chào nhân viên: $name')));
  }
}
