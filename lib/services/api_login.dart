import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"phoneNumber": phoneNumber, "password": password}),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String phoneNumber,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": name,
        "phoneNumber": phoneNumber,
        "password": password,
        "role": "customer",
      }),
    );

    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    return {"status": response.statusCode, "data": data};
  }
}
