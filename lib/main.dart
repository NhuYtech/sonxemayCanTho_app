import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login.dart';
import 'screens/customer_home.dart';
import 'screens/staff_home.dart';
import 'screens/manager_home.dart';
import 'firebase_options.dart';
import 'service/auth_service.dart';
import 'service/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sơn Xe Máy Cần Thơ',
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
            return FutureBuilder<String>(
              future: UserService().getCurrentUserRole(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final role = roleSnapshot.data ?? 'customer';
                final name = snapshot.data?.displayName ?? 'Người dùng';

                switch (role) {
                  case 'manager':
                    return ManagerHome(name: name);
                  case 'staff':
                    return StaffHome(name: name);
                  default:
                    return CustomerHome(name: name);
                }
              },
            );
          }

          return const Login();
        },
      ),
    );
  }
}
