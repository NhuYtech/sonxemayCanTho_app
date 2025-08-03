import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:sonxemaycantho/screens/edit_profile.dart';

class ViewProfileScreen extends StatefulWidget {
  const ViewProfileScreen({super.key});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  String _fullName = 'Đang tải...';
  String _email = 'Đang tải...';
  String _phone = 'Đang tải...';
  String _address = 'Đang tải...';
  String _createdAt = 'Đang tải...';
  String _updatedAt = 'Đang tải...';
  String? _avatarUrl;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showError('Không tìm thấy người dùng. Vui lòng đăng nhập lại.');
        return;
      }

      print('Current User UID: ${currentUser.uid}');

      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!doc.exists) {
        _showError('Dữ liệu hồ sơ không tồn tại.');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

      setState(() {
        _fullName = data['fullName'] ?? 'Chưa cập nhật';
        _email = data['emailAlias'] ?? currentUser.email ?? 'Chưa cập nhật';
        _phone = data['phoneNumber'] ?? 'Chưa cập nhật';
        _address = data['address'] ?? 'Chưa cập nhật';
        _isActive = data['isActive'] ?? true;
        _createdAt = data['createdAt'] != null
            ? dateFormat.format((data['createdAt'] as Timestamp).toDate())
            : 'Chưa cập nhật';
        _updatedAt = data['updatedAt'] != null
            ? dateFormat.format((data['updatedAt'] as Timestamp).toDate())
            : 'Chưa cập nhật';
        _avatarUrl = data['avatarURL']?.toString().trim();
      });
    } catch (e) {
      print('Error: $e');
      _showError('Lỗi khi tải hồ sơ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showError('Không tìm thấy người dùng.');
        return;
      }

      final storageRef = FirebaseStorage.instance.ref('avatars/${user.uid}');
      await storageRef.putFile(File(picked.path));
      final downloadUrl = await storageRef.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).update({
        'avatarURL': downloadUrl,
      });

      setState(() => _avatarUrl = downloadUrl);
      _showMessage('Tải ảnh đại diện thành công!');
    } catch (e) {
      _showError('Lỗi khi tải ảnh đại diện: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _fullName = _email = _phone = _address = _createdAt = _updatedAt =
            'Không có dữ liệu';
        _isActive = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
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
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editProfile),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC1473B)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            _avatarUrl != null && _avatarUrl!.isNotEmpty
                            ? NetworkImage(_avatarUrl!)
                            : null,
                        child: _avatarUrl == null || _avatarUrl!.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFC1473B),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _pickAndUploadAvatar,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard(Icons.person, 'Họ và tên', _fullName),
                  const SizedBox(height: 16),
                  _buildInfoCard(Icons.email, 'Email', _email),
                  const SizedBox(height: 16),
                  _buildInfoCard(Icons.phone, 'Số điện thoại', _phone),
                  const SizedBox(height: 16),
                  _buildInfoCard(Icons.location_on, 'Địa chỉ', _address),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    Icons.check_circle,
                    'Trạng thái',
                    _isActive ? 'Đang hoạt động' : 'Không hoạt động',
                    color: _isActive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(Icons.calendar_today, 'Ngày tạo', _createdAt),
                  const SizedBox(height: 16),
                  _buildInfoCard(Icons.update, 'Cập nhật lần cuối', _updatedAt),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? const Color(0xFFC1473B)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color ?? const Color(0xFFC1473B)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
