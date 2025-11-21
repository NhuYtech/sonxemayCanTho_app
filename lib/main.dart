import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sonxemaycantho/screens/auth/role.dart';
import 'widgets/firebase_options.dart';

import 'screens/customer/customer_home.dart';
import 'screens/manager/manager_home.dart';
import 'screens/staff/staff_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(message: 'Đang tải...');
        }

        if (snapshot.hasData) {
          return FutureBuilder<Widget>(
            future: _determineHomeScreen(snapshot.data!),
            builder: (context, homeSnapshot) {
              if (homeSnapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingScreen(message: 'Đang xác thực...');
              }

              if (homeSnapshot.hasError) {
                debugPrint(
                  'Error determining home screen: ${homeSnapshot.error}',
                );
                FirebaseAuth.instance.signOut();
                return const RoleSelection();
              }

              return homeSnapshot.data ?? const RoleSelection();
            },
          );
        } else {
          return const RoleSelection();
        }
      },
    );
  }

  Future<Widget> _determineHomeScreen(User user) async {
    try {
      // Kiểm tra trong collection 'accounts' (Nhân viên/Quản lý)
      final accountDoc = await FirebaseFirestore.instance
          .collection('accounts')
          .doc(user.uid)
          .get();

      Map<String, dynamic>? userData;
      if (accountDoc.exists) {
        userData = accountDoc.data();
      } else {
        // Nếu không tìm thấy trong 'accounts', kiểm tra trong 'users' (Khách hàng)
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          debugPrint(
            'User document does not exist in both collections, signing out...',
          );
          await FirebaseAuth.instance.signOut();
          return const RoleSelection();
        }

        userData = userDoc.data();
      }

      if (userData == null) {
        debugPrint('User data is null, signing out...');
        await FirebaseAuth.instance.signOut();
        return const RoleSelection();
      }

      final String role = userData['role'] ?? 'customer';
      final String fullName =
          userData['fullName'] ?? user.displayName ?? 'Người dùng';
      final bool isActive = userData['isActive'] ?? true;

      if (!isActive) {
        debugPrint('User account is inactive, signing out...');
        await FirebaseAuth.instance.signOut();
        return const _ErrorScreen(
          message:
              'Tài khoản của bạn đã bị vô hiệu hóa.\nVui lòng liên hệ quản trị viên.',
        );
      }

      switch (role.toLowerCase()) {
        case 'manager':
          debugPrint('Redirecting to ManagerHome for user: $fullName');
          return ManagerHome(name: fullName);

        case 'staff':
          debugPrint('Redirecting to StaffHome for user: $fullName');
          return StaffHome(name: fullName);

        case 'customer':
        default:
          debugPrint('Redirecting to CustomerHome for user: $fullName');
          return CustomerHome(name: fullName);
      }
    } catch (e) {
      debugPrint('Error determining home screen: $e');
      await FirebaseAuth.instance.signOut();
      return const RoleSelection();
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  final String message;
  const _LoadingScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo tròn với viền vàng
            Container(
              width: 220,
              height: 220,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC1473B),
                border: Border.all(color: const Color(0xFFFFD700), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo/logoapp.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC1473B)),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFFC1473B),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC1473B),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.white),
                const SizedBox(height: 30),
                const Text(
                  'Thông báo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const RoleSelection()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFC1473B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Quay lại',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
