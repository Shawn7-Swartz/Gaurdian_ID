import 'dart:async';

import 'package:flutter/material.dart';

import 'transaction_service.dart';

class ParentApprovalScreen extends StatefulWidget {
  const ParentApprovalScreen({
    super.key,
    this.service = const TransactionService(),
  });

  final TransactionService service;

  @override
  State<ParentApprovalScreen> createState() => _ParentApprovalScreenState();
}

class _ParentApprovalScreenState extends State<ParentApprovalScreen> {
  bool _busy = false;
  String? _error;
  List<TransactionRecord> _pending = const [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final pending = await widget.service.listPending();
      if (!mounted) return;
      setState(() {
        _pending = pending;
      });
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

  Future<void> _decide(TransactionRecord record, bool approve) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.service.decide(
        transactionId: record.transactionId,
        approve: approve,
      );
      await _refresh();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Parent Approvals'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pending transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Polling backend every 3 seconds…',
              style: TextStyle(color: Colors.white60),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFFF4D4F))),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: _pending.isEmpty
                  ? _EmptyState(isBusy: _busy)
                  : ListView.separated(
                      itemCount: _pending.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = _pending[index];
                        return _ApprovalCard(
                          record: record,
                          busy: _busy,
                          onApprove: () => _decide(record, true),
                          onDeny: () => _decide(record, false),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isBusy});

  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 44,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),
          Text(
            isBusy ? 'Checking…' : 'No pending approvals',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.record,
    required this.busy,
    required this.onApprove,
    required this.onDeny,
  });

  final TransactionRecord record;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_clock_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Child: ${record.childId}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onDeny,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF4D4F),
                  ),
                  child: const Text('Deny'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onApprove,
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

