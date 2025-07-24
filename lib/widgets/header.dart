// header.dart
import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final String name;

  final Color backgroundColor;

  /// Creates a [Header] widget.
  ///
  /// The [name] parameter is required and used to personalize the greeting.
  /// The [backgroundColor] parameter allows setting a custom background color for the header.
  const Header({
    super.key,
    required this.name,
    this.backgroundColor = const Color(0xFFC1473B),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundImage: AssetImage('assets/logo/logo1.png'),
                radius: 20,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  'Xin chào,\n$name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Notification icon
              const Icon(Icons.notifications, color: Colors.yellow, size: 28),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 16),
          // Search input field
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.grey,
              ), // Search icon
              suffixIcon: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () {
                  // TODO: Clear search text controller if implemented
                  print('Clear search tapped!');
                },
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                // Border when enabled
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                // Border when focused
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Colors.blue,
                  width: 2,
                ), // Highlight when focused
              ),
            ),
            onChanged: (value) {
              // TODO: Implement search logic here
              print('Search query: $value');
            },
          ),
        ],
      ),
    );
  }
}
