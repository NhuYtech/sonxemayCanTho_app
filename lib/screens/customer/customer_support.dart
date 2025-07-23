import 'package:flutter/material.dart';

class ManagerCustomerSupport extends StatefulWidget {
  final String name;
  const ManagerCustomerSupport({super.key, required this.name});

  @override
  State<ManagerCustomerSupport> createState() => _ManagerCustomerSupportState();
}

class _ManagerCustomerSupportState extends State<ManagerCustomerSupport> {
  final List<Map<String, dynamic>> _messages = [
    {
      'text':
          'Sơn xe máy Cần Thơ xin kính chào quý khách, chúng tôi có thể giúp gì được cho bạn?',
      'isMe': true,
    },
    {
      'text':
          'Tôi muốn sơn nguyên chiếc xe Vespa sprint 125 từ màu xanh lá thành màu hồng trắng. Shop có báo giá cho tôi được không?',
      'isMe': false,
    },
    {
      'text':
          'Vui lòng chờ đợi trong giây lát, tin nhắn của bạn sẽ được trả lời sau khoảng 5-10 phút...',
      'isMe': true,
    },
  ];

  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({'text': text, 'isMe': true});
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300, // Background for the chat area
      body: SafeArea(
        child: Column(
          children: [
            // Header (Red, rectangular, NO rounded corners)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFC1473B), // Red color
                // *** IMPORTANT: There is NO 'borderRadius' property here. ***
                // This ensures the container is a perfect rectangle at the bottom.
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: AssetImage('assets/logo/logo1.png'),
                    radius: 30,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Xin chào,\n${widget.name}', // Reverted to "Xin chào," + name
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18, // Adjusted font size to fit "Xin chào,\n"
                      ),
                    ),
                  ),
                  const Icon(Icons.notifications, color: Colors.yellow),
                ],
              ),
            ),

            // Nội dung tin nhắn
            Expanded(
              child: Container(
                color: Colors.grey.shade300, // Background for chat messages
                child: ListView.builder(
                  reverse: true, // Show latest messages at the bottom
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return Align(
                      alignment: msg['isMe']
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: msg['isMe']
                              ? Colors.lightBlueAccent
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg['text'],
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Ô nhập tin nhắn
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Tin nhắn...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontFamily: 'Itim'),
                      ),
                      onSubmitted: (_) =>
                          _sendMessage(), // Allows sending with enter key
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.red),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
