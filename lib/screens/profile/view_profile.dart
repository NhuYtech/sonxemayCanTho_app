// lib/screens/profile/view_profile.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:sonxemaycantho/screens/profile/edit_profile.dart';

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
  String _storeName = 'Đang tải...'; // Thêm trường mới
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
        _storeName =
            data['storeName'] ?? 'Chưa cập nhật'; // Lấy dữ liệu tên cửa hàng
        _createdAt = data['createdAt'] != null
            ? dateFormat.format((data['createdAt'] as Timestamp).toDate())
            : 'Chưa có';
        _updatedAt = data['updatedAt'] != null
            ? dateFormat.format((data['updatedAt'] as Timestamp).toDate())
            : 'Chưa có';
        _avatarUrl = data['avatarUrl'];
        _isActive = data['isActive'] ?? true;
      });
    } catch (e) {
      _showError('Lỗi khi tải hồ sơ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _uploadAvatar() async {
    // Giữ nguyên phần logic này
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;
      setState(() => _isLoading = true);
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_avatars')
          .child('${currentUser.uid}.jpg');
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      await _firestore.collection('users').doc(currentUser.uid).update({
        'avatarUrl': downloadUrl,
      });
      setState(() {
        _avatarUrl = downloadUrl;
        _isLoading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ảnh đại diện đã được cập nhật.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError('Lỗi khi tải ảnh đại diện: $e');
        setState(() => _isLoading = false);
      }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  )
                  .then((_) {
                    _loadUserProfile();
                  });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _avatarUrl != null
                              ? NetworkImage(_avatarUrl!)
                              : null,
                          child: _avatarUrl == null
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
                          child: GestureDetector(
                            onTap: _uploadAvatar,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFC1473B),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.person, color: Color(0xFFC1473B)),
                    title: const Text('Họ và tên'),
                    subtitle: Text(_fullName),
                  ),
                  const Divider(),
                  // Thêm ListTile để hiển thị tên cửa hàng
                  ListTile(
                    leading: const Icon(Icons.store, color: Color(0xFFC1473B)),
                    title: const Text('Tên cửa hàng'),
                    subtitle: Text(_storeName),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.email, color: Color(0xFFC1473B)),
                    title: const Text('Email'),
                    subtitle: Text(_email),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.phone, color: Color(0xFFC1473B)),
                    title: const Text('Số điện thoại'),
                    subtitle: Text(_phone),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.location_on,
                      color: Color(0xFFC1473B),
                    ),
                    title: const Text('Địa chỉ'),
                    subtitle: Text(_address),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.access_time,
                      color: Color(0xFFC1473B),
                    ),
                    title: const Text('Ngày tạo'),
                    subtitle: Text(_createdAt),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.update, color: Color(0xFFC1473B)),
                    title: const Text('Cập nhật gần nhất'),
                    subtitle: Text(_updatedAt),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFFC1473B),
                    ),
                    title: const Text('Trạng thái hoạt động'),
                    subtitle: Text(_isActive ? 'Hoạt động' : 'Tạm khóa'),
                  ),
                  const Divider(),
                ],
              ),
            ),
    );
  }
}
