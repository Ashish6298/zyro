import 'dart:convert';
import 'package:http/http.dart' as http;

class DownloadApiService {
  final String baseUrl;

  // Android emulator uses 10.0.2.2 to reach the host machine's localhost.
  // Physical devices need `adb reverse tcp:3000 tcp:3000` then use localhost:3000.
  DownloadApiService({String? baseUrl})
      : baseUrl = baseUrl ?? 'http://10.0.2.2:3000';

  Future<Map<String, dynamic>> fetchMetadata(String url) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/video/metadata'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'url': url}),
          )
          .timeout(const Duration(seconds: 180));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Server error (${response.statusCode})');
      }
    } on Exception catch (e) {
      throw Exception('Backend unreachable: $e\n\nMake sure your backend is running and run:\nadb reverse tcp:3000 tcp:3000');
    }
  }

  Future<String> startDownload({
    required String url,
    required String formatId,
    int? expectedHeight,
    required String mode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/video/download'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'url': url,
        'formatId': formatId,
        'expectedHeight': expectedHeight,
        'mode': mode,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['taskId'] as String;
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to start download task');
      } catch (_) {
        throw Exception('Failed to start download task (Status code: ${response.statusCode})');
      }
    }
  }

  Future<Map<String, dynamic>> checkStatus(String taskId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/video/status/$taskId'),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['task'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to check task status');
    }
  }
}
