import 'package:flutter/material.dart';

import '../../app.dart';
import '../liveness/liveness_screen.dart';
import '../transactions/minor_transaction_screen.dart';
import '../transactions/parent_approval_screen.dart';

part 'wallet_widgets.dart';

enum WalletMode { major, minor }

class WalletModeScreen extends StatefulWidget {
  const WalletModeScreen({
    super.key,
    this.initialMode = WalletMode.major,
  });

  /// Set from splash face flow: face in frame → minor, otherwise major (overridable in UI).
  final WalletMode initialMode;

  @override
  State<WalletModeScreen> createState() => _WalletModeScreenState();
}

class _WalletModeScreenState extends State<WalletModeScreen> {
  late WalletMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  void _openLivenessCheck() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LivenessScreen(cameras: GuardianWalletScope.of(context)),
      ),
    );
  }

  void _openMinorTransaction() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MinorTransactionScreen(),
      ),
    );
  }

  void _openParentApprovals() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ParentApprovalScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMajor = _mode == WalletMode.major;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF081321),
              Color(0xFF0A1628),
              Color(0xFF111D34),
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -90,
              right: -30,
              child: _BlurOrb(color: Color(0xFF365DF0), size: 220),
            ),
            const Positioned(
              bottom: 90,
              left: -50,
              child: _BlurOrb(color: Color(0xFF7D5CFF), size: 180),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    _WalletTopBar(
                      isMajor: isMajor,
                      onLivenessTap: _openLivenessCheck,
                      onTransactionTap:
                          isMajor ? _openParentApprovals : _openMinorTransaction,
                    ),
                    const SizedBox(height: 20),
                    _ModeToggle(
                      mode: _mode,
                      onChanged: (mode) {
                        if (mode == _mode) {
                          return;
                        }
                        setState(() {
                          _mode = mode;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 420),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(position: slide, child: child),
                          );
                        },
                        child: isMajor
                            ? const MajorWalletView(key: ValueKey('major'))
                            : const MinorWalletView(key: ValueKey('minor')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
