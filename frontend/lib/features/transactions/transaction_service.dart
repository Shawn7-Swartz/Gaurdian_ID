import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';

class TransactionRecord {
  const TransactionRecord({
    required this.transactionId,
    required this.childId,
    required this.amount,
    required this.limit,
    required this.status,
    required this.reason,
  });

  final String transactionId;
  final String childId;
  final double amount;
  final double limit;
  final String status; // approved | denied | pending
  final String? reason;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isDenied => status == 'denied';

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      transactionId: json['transaction_id'] as String,
      childId: json['child_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      limit: (json['limit'] as num).toDouble(),
      status: json['status'] as String,
      reason: json['reason'] as String?,
    );
  }
}

class TransactionService {
  const TransactionService();

  static String get baseUrl => ApiConfig.baseUrl;

  Future<TransactionRecord> startTransaction({
    required String childId,
    required double amount,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/start'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'child_id': childId, 'amount': amount}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Start transaction failed (${response.statusCode}): ${response.body}',
      );
    }

    return TransactionRecord.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<TransactionRecord> getTransaction(String transactionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/$transactionId'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Get transaction failed (${response.statusCode}): ${response.body}',
      );
    }

    return TransactionRecord.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<TransactionRecord>> listPending() async {
    final response = await http.get(Uri.parse('$baseUrl/transactions/pending'));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'List pending failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((e) => TransactionRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionRecord> decide({
    required String transactionId,
    required bool approve,
    String parentId = 'parent-001',
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/$transactionId/decision'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'decision': approve ? 'approve' : 'deny',
        'parent_id': parentId,
        'reason': reason,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Decision failed (${response.statusCode}): ${response.body}',
      );
    }

    return TransactionRecord.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

