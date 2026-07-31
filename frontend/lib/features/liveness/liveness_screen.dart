import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/api_config.dart';
import 'liveness_service.dart';

enum LivenessStage { idle, running, pass, fail }

class LivenessScreen extends StatefulWidget {
  const LivenessScreen({
    super.key,
    required this.cameras,
    this.service = const LivenessService(),
  });

  final List<CameraDescription> cameras;
  final LivenessService service;

  @override
  State<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends State<LivenessScreen> {
  static const List<String> _targetSequence = ['left', 'center', 'right'];

  CameraController? _controller;
  Future<void>? _initializeFuture;
  String? _cameraMessage;
  String _currentTarget = _targetSequence.first;
  String _statusMessage = 'Align your face and follow the red dot.';
  LivenessStage _stage = LivenessStage.idle;
  bool _busy = false;
  int _progressIndex = 0;
  late String _sessionId;

  @override
  void initState() {
    super.initState();
    _newSession();
    _setupCamera();
  }

  void _newSession() {
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _setupCamera() async {
    if (widget.cameras.isEmpty) {
      setState(() {
        _cameraMessage = 'No camera available for liveness checks.';
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
      imageFormatGroup: ImageFormatGroup.jpeg,
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
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cameraMessage = 'Camera preview unavailable: $error';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _runLivenessCheck() async {
    final controller = _controller;
    final initializeFuture = _initializeFuture;

    if (_busy || controller == null || initializeFuture == null) {
      return;
    }

    setState(() {
      _newSession();
      _busy = true;
      _stage = LivenessStage.running;
      _statusMessage = 'Sending frames to backend...';
      _progressIndex = 0;
      _currentTarget = _targetSequence.first;
    });

    try {
      await initializeFuture;

      for (var index = 0; index < _targetSequence.length; index++) {
        final target = _targetSequence[index];

        if (!mounted) {
          return;
        }

        setState(() {
          _progressIndex = index;
          _currentTarget = target;
          _statusMessage = 'Look ${target.toUpperCase()} and hold steady.';
        });

        await Future<void>.delayed(const Duration(milliseconds: 900));
        final picture = await controller.takePicture();
        final result = await widget.service.sendFrame(
          sessionId: _sessionId,
          targetPosition: target,
          imagePath: picture.path,
        );

        if (!mounted) {
          return;
        }

        if (result.passed) {
          setState(() {
            _stage = LivenessStage.pass;
            _statusMessage = result.message;
          });
          return;
        }

        setState(() {
          _statusMessage = result.message;
          _currentTarget = result.nextTarget ?? target;
        });
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _stage = LivenessStage.fail;
        _statusMessage = 'Backend did not approve liveness for this attempt.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _stage = LivenessStage.fail;
        _statusMessage = 'Connection failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  void _resetFlow() {
    setState(() {
      _stage = LivenessStage.idle;
      _busy = false;
      _progressIndex = 0;
      _currentTarget = _targetSequence.first;
      _statusMessage = 'Align your face and follow the red dot.';
    });
  }

  Alignment _targetAlignment() {
    switch (_currentTarget) {
      case 'left':
        return const Alignment(-0.72, -0.2);
      case 'right':
        return const Alignment(0.72, -0.2);
      case 'center':
      default:
        return const Alignment(0, -0.2);
    }
  }

  Color _resultColor() {
    switch (_stage) {
      case LivenessStage.pass:
        return const Color(0xFF1ED760);
      case LivenessStage.fail:
        return const Color(0xFFFF4D4F);
      case LivenessStage.running:
        return const Color(0xFF365DF0);
      case LivenessStage.idle:
        return Colors.white70;
    }
  }

  String _resultLabel() {
    switch (_stage) {
      case LivenessStage.pass:
        return 'PASS';
      case LivenessStage.fail:
        return 'FAIL';
      case LivenessStage.running:
        return 'CHECKING';
      case LivenessStage.idle:
        return 'READY';
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewFuture = _initializeFuture;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Liveness Check'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: Colors.black,
                      child: _cameraMessage != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _cameraMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            )
                          : previewFuture == null
                              ? const Center(child: CircularProgressIndicator())
                              : FutureBuilder<void>(
                                  future: previewFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState !=
                                        ConnectionState.done) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    if (snapshot.hasError || _controller == null) {
                                      return const Center(
                                        child: Text(
                                          'Unable to start camera preview.',
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
                            Colors.black.withValues(alpha: 0.18),
                            Colors.black.withValues(alpha: 0.38),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            width: 220,
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(120),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeInOut,
                      alignment: _targetAlignment(),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: _StatusCard(
                        label: _resultLabel(),
                        color: _resultColor(),
                        message: _statusMessage,
                        progressIndex: _progressIndex,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _resetFlow,
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        (_cameraMessage != null || _busy) ? null : _runLivenessCheck,
                    child: Text(
                      _busy ? 'Checking...' : 'Start Liveness',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ApiConfig.usesRemoteBackend
                  ? 'Backend: ${LivenessService.baseUrl}/liveness'
                  : 'Backend (dev): ${LivenessService.baseUrl}/liveness',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.color,
    required this.message,
    required this.progressIndex,
  });

  final String label;
  final Color color;
  final String message;
  final int progressIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xCC071120),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (progressIndex + 1) / 3,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    );
  }
}
