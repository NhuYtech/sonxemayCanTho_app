import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewProfileScreen extends StatefulWidget {
  const ViewProfileScreen({super.key});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Dữ liệu người dùng
  String _name = 'Đang tải...';
  String _email = 'Đang tải...';
  String _phone = 'Đang tải...';
  String _role = 'Đang tải...';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Lấy thông tin user hiện tại từ Firebase Auth
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Không tìm thấy user đăng nhập');
        return;
      }

      // Lấy thêm thông tin từ Firestore
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _name = userData['name'] ?? 'Chưa cập nhật';
          _email = currentUser.email ?? 'Chưa cập nhật';
          _phone = userData['phone'] ?? 'Chưa cập nhật';
          _role = userData['role'] ?? 'Chưa xác định';
          _avatarUrl = userData['avatarUrl'];
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi tải thông tin: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFC1473B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _avatarUrl != null
                        ? NetworkImage(_avatarUrl!)
                        : null,
                    child: _avatarUrl == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Thông tin cá nhân
            _buildInfoCard(
              icon: Icons.person,
              label: 'Họ và tên',
              value: _name,
            ),
            const SizedBox(height: 16),

            _buildInfoCard(icon: Icons.email, label: 'Email', value: _email),
            const SizedBox(height: 16),

            _buildInfoCard(
              icon: Icons.phone,
              label: 'Số điện thoại',
              value: _phone,
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              icon: Icons.badge,
              label: 'Vai trò',
              value: _role == 'admin'
                  ? 'Quản trị viên'
                  : _role == 'staff'
                  ? 'Nhân viên'
                  : 'Khách hàng',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFC1473B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFC1473B), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
