import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/firebase_options.dart';
import 'screens/role.dart';
import 'screens/view_profile.dart'; // Import màn hình profile

// HÀM CHÍNH KHỞI TẠO ỨNG DỤNG
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // ✅ KHÔNG ĐĂNG XUẤT TỰ ĐỘNG
    // Dòng này đã được xóa: await FirebaseAuth.instance.signOut();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sơn Xe Máy Cần Thơ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Itim',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC54141)),
        useMaterial3: true,
      ),
      // ✅ SỬ DỤNG AuthWrapper để kiểm tra trạng thái đăng nhập
      home: const AuthWrapper(),
    );
  }
}

// Widget để xử lý trạng thái xác thực
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // Nếu đã đăng nhập, chuyển đến màn hình hồ sơ
          return const ViewProfileScreen();
        } else {
          // Nếu chưa đăng nhập, chuyển đến màn hình chọn vai trò
          return const RoleSelection();
        }
      },
    );
  }
}
