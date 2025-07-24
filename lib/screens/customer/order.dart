import 'package:flutter/material.dart';
import '../../widgets/header.dart';
// import '../../widgets/search_field.dart';
import 'order_content.dart';

class ManagerOrder extends StatelessWidget {
  final String name;
  const ManagerOrder({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Header(name: name),

          // Search Field
          // SearchField(
          //   hintText: 'Tìm kiếm đơn hàng...',
          //   onSearch: (query) {
          //     // TODO: Implement search functionality
          //     print('Searching for: $query');
          //   },
          // ),

          // Main Content
          const OrderContent(),
        ],
      ),
    );
  }
}
