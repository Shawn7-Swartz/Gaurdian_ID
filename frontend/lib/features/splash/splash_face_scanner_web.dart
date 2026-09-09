/// Web build: no ML Kit (avoids `dart:io` / Platform in native plugins).
class SplashFaceScanner {
  SplashFaceScanner();

  Future<bool> hasFaceInImage(String path) async => false;

  void dispose() {}
}
