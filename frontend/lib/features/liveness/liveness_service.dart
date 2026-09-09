import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';

class LivenessResult {
  const LivenessResult({
    required this.passed,
    required this.message,
    required this.nextTarget,
  });

  final bool passed;
  final String message;
  final String? nextTarget;

  factory LivenessResult.fromJson(Map<String, dynamic> json) {
    return LivenessResult(
      passed: json['passed'] as bool? ?? false,
      message: json['message'] as String? ?? 'No response message',
      nextTarget: json['next_target'] as String?,
    );
  }
}

class LivenessService {
  const LivenessService();

  static String get baseUrl => ApiConfig.baseUrl;

  Future<LivenessResult> sendFrame({
    required String sessionId,
    required String targetPosition,
    required String imagePath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/liveness'),
    )
      ..fields['session_id'] = sessionId
      ..fields['target_position'] = targetPosition
      ..files.add(
        await http.MultipartFile.fromPath(
          'frame',
          imagePath,
          filename: Uri.file(imagePath).pathSegments.isNotEmpty
              ? Uri.file(imagePath).pathSegments.last
              : 'frame.jpg',
        ),
      );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Liveness request failed (${streamed.statusCode}): $body');
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    return LivenessResult.fromJson(decoded);
  }
}
