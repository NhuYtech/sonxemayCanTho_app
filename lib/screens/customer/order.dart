import 'package:flutter/material.dart';
// XÓA DÒNG NÀY: Vì Header đã được cung cấp bởi AppBar của ManagerHome
// import '../../widgets/header.dart';
// import '../../widgets/search_field.dart'; // Giữ lại nếu bạn định dùng SearchField sau này
import 'order_content.dart';

class ManagerOrder extends StatelessWidget {
  final String name;
  const ManagerOrder({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // XÓA DÒNG NÀY: Header đã có ở ManagerHome
          // Header(name: name),

          // Bạn có thể bỏ comment và sử dụng SearchField ở đây nếu cần,
          // vì nó là một phần của nội dung, không phải thanh tiêu đề chính.
          // SearchField(
          //   hintText: 'Tìm kiếm đơn hàng...',
          //   onSearch: (query) {
          //     // TODO: Triển khai chức năng tìm kiếm
          //     print('Đang tìm kiếm: $query');
          //   },
          // ),

          // Nội dung chính của màn hình Đơn hàng
          const OrderContent(),
        ],
      ),
    );
  }
}
