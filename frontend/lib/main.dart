import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'app.dart';

export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(GuardianWalletApp(cameras: cameras));
}
