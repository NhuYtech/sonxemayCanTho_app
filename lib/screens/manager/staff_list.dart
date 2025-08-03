// lib/screens/staff_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffList extends StatefulWidget {
  const StaffList({super.key});

  @override
  State<StaffList> createState() => _StaffListState();
}

class _StaffListState extends State<StaffList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _staffs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchStaffs();
  }

  Future<void> _fetchStaffs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy tất cả người dùng từ collection 'users'
      final snapshot = await _firestore.collection('users').get();

      // Lọc ra danh sách nhân viên (ví dụ: dựa trên trường 'role')
      // Bạn cần thay thế logic này bằng cách kiểm tra vai trò cụ thể
      final staffList = snapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        _staffs = staffList;
      });
    } catch (e) {
      print('Error fetching staff list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách nhân viên: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Danh sách Nhân viên',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFC1473B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC1473B)),
            )
          : _staffs.isEmpty
          ? const Center(child: Text('Không có nhân viên nào được tìm thấy.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _staffs.length,
              itemBuilder: (context, index) {
                final staff = _staffs[index];
                return _buildStaffCard(staff);
              },
            ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  staff['avatarURL'] != null &&
                      staff['avatarURL'].toString().isNotEmpty
                  ? NetworkImage(staff['avatarURL'])
                  : null,
              child:
                  (staff['avatarURL'] == null ||
                      staff['avatarURL'].toString().isEmpty)
                  ? const Icon(Icons.person, size: 30, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff['fullName'] ?? 'Chưa cập nhật',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC1473B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Email: ${staff['emailAlias'] ?? staff['email'] ?? 'Chưa cập nhật'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Số điện thoại: ${staff['phoneNumber'] ?? 'Chưa cập nhật'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Địa chỉ: ${staff['address'] ?? 'Chưa cập nhật'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Bạn có thể thêm các widget khác như nút gọi, nhắn tin, ... tại đây
          ],
        ),
      ),
    );
  }
}
