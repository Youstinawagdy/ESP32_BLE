import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reading.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.3:3000';

  static Future<Reading?> sendReading({
    required String deviceId,
    required double temperature,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/readings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': deviceId,
          'temperature': temperature,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Reading.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to send reading: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error sending reading: $e');
      return null;
    }
  }

  static Future<Reading?> getLatestReading(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/readings/$deviceId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['message'] != null) {
          return null;
        }
        return Reading.fromJson(data);
      } else {
        print('Failed to get reading: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting reading: $e');
      return null;
    }
  }

  static Future<List<Reading>> getAllReadings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/readings'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Reading.fromJson(json)).toList();
      } else {
        print('Failed to get readings: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting readings: $e');
      return [];
    }
  }
}
