// lib/widgets/bottom_navbar.dart
import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.selectedIndex,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.black,
      onTap: widget.onItemTapped,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Trang chủ',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'Đơn hàng',
        ),

        BottomNavigationBarItem(
          icon: StreamBuilder<int>(
            stream: _chatService.getTotalUnreadCountStream(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return Stack(
                children: [
                  const Icon(Icons.chat),
                  if (unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.yellow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          label: 'CSKH',
        ),

        const BottomNavigationBarItem(
          icon: Icon(Icons.local_fire_department_outlined),
          activeIcon: Icon(Icons.local_fire_department, color: Colors.red),
          label: 'Cảnh báo',
        ),

        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Cá nhân',
        ),
      ],
    );
  }
}
