import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Mobile / desktop VM: ML Kit face detection for splash flow.
class SplashFaceScanner {
  SplashFaceScanner()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.fast,
            enableTracking: true,
            enableLandmarks: false,
            enableContours: false,
            enableClassification: false,
          ),
        );

  final FaceDetector _detector;

  Future<bool> hasFaceInImage(String path) async {
    final input = InputImage.fromFilePath(path);
    final faces = await _detector.processImage(input);
    return faces.isNotEmpty;
  }

  void dispose() {
    _detector.close();
  }
}
