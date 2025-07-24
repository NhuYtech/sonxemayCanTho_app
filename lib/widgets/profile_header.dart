// lib/widgets/profile_header.dart
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String name;

  final String role;

  const ProfileHeader({super.key, required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),

      decoration: const BoxDecoration(color: Color(0xFFC1473B)),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundImage: AssetImage('assets/logo/logo1.png'),
            radius: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Icon(Icons.notifications, color: Colors.yellow),
        ],
      ),
    );
  }
}
