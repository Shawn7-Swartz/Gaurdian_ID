import 'dart:async';

import 'package:flutter/material.dart';

import 'transaction_service.dart';

class MinorTransactionScreen extends StatefulWidget {
  const MinorTransactionScreen({
    super.key,
    this.service = const TransactionService(),
    this.childId = 'child-001',
  });

  final TransactionService service;
  final String childId;

  @override
  State<MinorTransactionScreen> createState() => _MinorTransactionScreenState();
}

class _MinorTransactionScreenState extends State<MinorTransactionScreen> {
  final _amountController = TextEditingController();
  TransactionRecord? _record;
  Timer? _pollTimer;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  double? _parseAmount() {
    final raw = _amountController.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    return double.tryParse(raw);
  }

  Future<void> _start() async {
    final amount = _parseAmount();
    if (amount == null || amount <= 0) {
      setState(() {
        _error = 'Enter a valid amount';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _record = null;
    });

    try {
      final record = await widget.service.startTransaction(
        childId: widget.childId,
        amount: amount,
      );

      if (!mounted) return;

      setState(() {
        _record = record;
      });

      _pollTimer?.cancel();
      if (record.isPending) {
        _pollTimer = Timer.periodic(
          const Duration(seconds: 3),
          (_) => _pollStatus(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _pollStatus() async {
    final record = _record;
    if (record == null || !record.isPending) {
      return;
    }

    try {
      final updated = await widget.service.getTransaction(record.transactionId);
      if (!mounted) return;

      setState(() {
        _record = updated;
      });

      if (!updated.isPending) {
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    } catch (_) {
      // Keep polling; transient failures should not break flow.
    }
  }

  Color _statusColor(TransactionRecord record) {
    if (record.isApproved) return const Color(0xFF1ED760);
    if (record.isDenied) return const Color(0xFFFF4D4F);
    return const Color(0xFFFFC107);
  }

  String _statusLabel(TransactionRecord record) {
    if (record.isApproved) return 'APPROVED';
    if (record.isDenied) return 'DENIED';
    return 'WAITING FOR APPROVAL…';
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Minor Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter amount',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 250',
                      errorText: _error,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Minor spend limit: Rs. 500',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _busy ? null : _start,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(_busy ? 'Sending…' : 'Send transaction'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (record != null) ...[
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _statusColor(record),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _statusLabel(record),
                          style: TextStyle(
                            color: _statusColor(record),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Amount: Rs. ${record.amount.toStringAsFixed(0)}'),
                    Text(
                      'Limit: Rs. ${record.limit.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    if (record.reason != null)
                      Text(
                        record.reason!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    if (record.isPending) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(minHeight: 8),
                      const SizedBox(height: 10),
                      const Text(
                        'Polling backend every 3 seconds…',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

