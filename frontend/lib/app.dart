import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'features/splash/splash_camera_screen.dart';

class GuardianWalletScope extends InheritedWidget {
  const GuardianWalletScope({
    super.key,
    required this.cameras,
    required super.child,
  });

  final List<CameraDescription> cameras;

  static List<CameraDescription> of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<GuardianWalletScope>();
    assert(scope != null, 'GuardianWalletScope not found in widget tree.');
    return scope!.cameras;
  }

  @override
  bool updateShouldNotify(GuardianWalletScope oldWidget) {
    return oldWidget.cameras != cameras;
  }
}

class GuardianWalletApp extends StatelessWidget {
  const GuardianWalletApp({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    return GuardianWalletScope(
      cameras: cameras,
      child: MaterialApp(
        title: 'Guardian ID',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF365DF0),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF071120),
          useMaterial3: true,
        ),
        home: SplashCameraScreen(cameras: cameras),
      ),
    );
  }
}
