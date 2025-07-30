import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/firebase_options.dart';
import 'screens/customer/customer_home.dart';
import 'screens/staff/staff_home.dart';
import 'screens/manager/manager_home.dart';
import 'screens/role.dart';
import 'services/auth_service.dart';
import 'services/user.dart';
import 'services/account.dart';

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
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            final currentUser = snapshot.data!;
            final uid = currentUser.uid;

            return FutureBuilder<String>(
              future: determineUserRole(uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final role = roleSnapshot.data ?? 'customer';
                final name = currentUser.displayName ?? 'Người dùng';

                switch (role.toLowerCase()) {
                  case 'manager':
                    return ManagerHome(name: name);
                  case 'staff':
                    return StaffHome(name: name);
                  case 'customer':
                  default:
                    return CustomerHome(name: name);
                }
              },
            );
          }

          return const RoleSelection();
        },
      ),
    );
  }

  /// Kiểm tra vai trò dựa vào UID:
  /// - Nếu có trong `Account` -> trả về `role` (manager/staff)
  /// - Nếu có trong `User` -> trả về `customer`
  Future<String> determineUserRole(String uid) async {
    final account = await AccountService().getAccountById(uid);
    if (account != null) return account['role'];

    final user = await UserService().getUserById(uid);
    if (user != null) return 'customer';

    return 'customer'; // Mặc định
  }
}
