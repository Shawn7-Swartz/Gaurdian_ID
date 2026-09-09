import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/api_config.dart';
import '../wallet/wallet_mode_screen.dart';
import 'splash_face_scanner_web.dart' if (dart.library.io) 'splash_face_scanner_io.dart' as fs;

class SplashCameraScreen extends StatefulWidget {
  const SplashCameraScreen({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<SplashCameraScreen> createState() => _SplashCameraScreenState();
}

class _SplashCameraScreenState extends State<SplashCameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  String? _cameraMessage;

  late final fs.SplashFaceScanner _faceScanner;
  Timer? _facePollTimer;
  bool _scanBusy = false;

  /// Hysteresis so the UI does not flicker between Major / Minor.
  bool _facePresent = false;
  int _positiveStreak = 0;
  int _negativeStreak = 0;

  @override
  void initState() {
    super.initState();
    _faceScanner = fs.SplashFaceScanner();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    if (widget.cameras.isEmpty) {
      setState(() {
        _cameraMessage =
            'No camera available. You can still open the wallet in parent mode.';
      });
      return;
    }

    final selectedCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );
    final controller = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    setState(() {
      _controller = controller;
      _initializeFuture = controller.initialize();
    });

    try {
      await _initializeFuture;
      if (!mounted) {
        return;
      }
      setState(() {
        _cameraMessage = null;
      });
      if (!kIsWeb) {
        _startFacePolling();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cameraMessage = 'Camera preview unavailable: $error';
      });
    }
  }

  void _startFacePolling() {
    _facePollTimer?.cancel();
    _facePollTimer = Timer.periodic(const Duration(milliseconds: 1300), (_) {
      unawaited(_runFaceScan());
    });
  }

  Future<void> _runFaceScan() async {
    final controller = _controller;
    if (kIsWeb || !mounted || controller == null || _scanBusy || _cameraMessage != null) {
      return;
    }

    _scanBusy = true;
    try {
      final shot = await controller.takePicture();
      final hasFace = await _faceScanner.hasFaceInImage(shot.path);
      if (!mounted) {
        return;
      }
      _applyFaceSignal(hasFace);
    } catch (_) {
      // Skip failed frames (e.g. capture in progress).
    } finally {
      _scanBusy = false;
    }
  }

  void _applyFaceSignal(bool hasFace) {
    var changed = false;
    if (hasFace) {
      _positiveStreak++;
      _negativeStreak = 0;
      if (_positiveStreak >= 2 && !_facePresent) {
        _facePresent = true;
        changed = true;
      }
    } else {
      _negativeStreak++;
      _positiveStreak = 0;
      if (_negativeStreak >= 3 && _facePresent) {
        _facePresent = false;
        changed = true;
      }
    }
    if (changed) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _facePollTimer?.cancel();
    _faceScanner.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _continueToWallet({required bool forceMajor}) {
    _facePollTimer?.cancel();
    _facePollTimer = null;

    final mode = forceMajor
        ? WalletMode.major
        : (_facePresent ? WalletMode.minor : WalletMode.major);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: WalletModeScreen(initialMode: mode),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewFuture = _initializeFuture;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: _cameraMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _cameraMessage!,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : previewFuture == null
                    ? const Center(child: CircularProgressIndicator())
                    : FutureBuilder<void>(
                        future: previewFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError || _controller == null) {
                            return const Center(
                              child: Text(
                                'Starting camera preview...',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          return CameraPreview(_controller!);
                        },
                      ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.28),
                  const Color(0xFF071120).withValues(alpha: 0.85),
                  const Color(0xFF071120),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('Week 6 — Full integration'),
                  ),
                  const Spacer(),
                  const Text(
                    'Guardian ID',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    kIsWeb
                        ? 'Web preview: use Android/iOS for camera face detection. Liveness and transactions use API_BASE_URL when set.'
                        : 'Face detection picks Minor vs Major on entry. Liveness and transactions use your deployed API when you build with API_BASE_URL.',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _facePresent ? Icons.face : Icons.face_retouching_off,
                          color: _facePresent
                              ? const Color(0xFF7D5CFF)
                              : Colors.white70,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _cameraMessage != null
                                ? 'Open the parent wallet below, or grant camera to enable face-based mode.'
                                : kIsWeb
                                    ? 'On web, wallet opens in Major by default; use a device build for live face mode.'
                                    : _facePresent
                                        ? 'Face detected — opening the wallet will start in Minor (protected) mode.'
                                        : 'No stable face yet — opening the wallet will start in Major (full) mode. Step into frame for Minor.',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _continueToWallet(forceMajor: false),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      _facePresent
                          ? 'Enter wallet (Minor)'
                          : 'Enter wallet (Major)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => _continueToWallet(forceMajor: true),
                      child: const Text('Always open as parent (Major)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ApiConfig.usesRemoteBackend
                        ? 'API: ${ApiConfig.baseUrl}'
                        : 'API (local emulator): ${ApiConfig.baseUrl}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
