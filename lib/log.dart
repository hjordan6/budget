import 'dart:convert';
import 'package:http/http.dart' as http;

class AppLogger {
  static Future<void> log({
    required String level,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse(
              "https://us-central1-budget-21dbe.cloudfunctions.net/logClient",
            ),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "level": level,
              "message": message,
              "metadata": metadata ?? {},
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('logClient failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      // Don’t rethrow if you want logging to be “best effort”.
      // But do print so you can see CORS/404/403/etc.
      // ignore: avoid_print
      print('AppLogger.log error: $e');
    }
  }
}

class Logger {
  static Future<void> info(String message, {Map<String, dynamic>? data}) {
    return AppLogger.log(level: "info", message: message, metadata: data);
  }

  static Future<void> error(String message, {Map<String, dynamic>? data}) {
    return AppLogger.log(level: "error", message: message, metadata: data);
  }
}
