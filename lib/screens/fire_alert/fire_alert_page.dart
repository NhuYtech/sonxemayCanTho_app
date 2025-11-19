import 'package:flutter/material.dart';

class FireAlert extends StatelessWidget {
  const FireAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 🔹 AppBar chỉnh lại: nền trắng, chữ sát trái
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // bỏ đổ bóng
        title: const Text(
          "Cảnh báo cháy IoT",
          style: TextStyle(
            color: Color(0xFFC1473B), // đỏ chủ đạo app
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false, // sát trái
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // --- 🔥 Trạng thái hiện tại ---
            _buildStatusCard(
              status: "Phát hiện cháy!",
              color: Colors.red.shade100,
              icon: Icons.local_fire_department,
              time: "17:47",
              area: "Khu vực: Kho A",
            ),
            const SizedBox(height: 16),

            // --- 🌡️ Thông tin cảm biến ---
            _buildSensorDataCard(
              temperature: "45.3°C",
              humidity: "56%",
              smoke: "220 ppm",
              flame: "Có phát hiện",
              gas: "Cảnh báo cao",
            ),
            const SizedBox(height: 16),

            // --- 🕓 Lịch sử cảnh báo ---
            const Text(
              "Lịch sử cảnh báo",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildLogCard(
              time: "17:47",
              message: "🔥 Phát hiện khói và nhiệt độ cao tại khu A",
              color: Colors.redAccent,
            ),
            _buildLogCard(
              time: "18:02",
              message: "✅ Đã xử lý cảnh báo, hệ thống trở lại bình thường",
              color: Colors.green,
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.volume_off),
        label: const Text("Tắt còi báo"),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã gửi lệnh tắt còi báo!"),
              backgroundColor: Colors.redAccent,
            ),
          );
        },
      ),
    );
  }

  // ----- Widget con -----

  Widget _buildStatusCard({
    required String status,
    required Color color,
    required IconData icon,
    required String time,
    required String area,
  }) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.red),
        title: Text(
          status,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text("$area\nThời gian: $time"),
        trailing: const Icon(Icons.warning_amber, color: Colors.redAccent),
      ),
    );
  }

  Widget _buildSensorDataCard({
    required String temperature,
    required String humidity,
    required String smoke,
    required String flame,
    required String gas,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dữ liệu cảm biến",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("🌡️ Nhiệt độ: $temperature"),
            Text("💧 Độ ẩm: $humidity"),
            Text("💨 Khói: $smoke"),
            Text("🔥 Lửa: $flame"),
            Text("🧪 Gas: $gas"),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard({
    required String time,
    required String message,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: Icon(Icons.access_time, color: color),
        title: Text(message),
        subtitle: Text("Thời gian: $time"),
      ),
    );
  }
}
