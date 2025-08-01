import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/firebase_options.dart';
import 'screens/role.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // ✅ Đăng xuất người dùng mỗi lần mở app
    await FirebaseAuth.instance.signOut();
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
      // ✅ Mỗi lần mở app là vào màn hình chọn vai trò
      home: const RoleSelection(),
    );
  }
}
