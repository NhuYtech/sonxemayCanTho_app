import 'package:flutter/material.dart';

class CustomerHome extends StatelessWidget {
  final String name;
  const CustomerHome({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Xin chào khách hàng: $name')));
  }
}
