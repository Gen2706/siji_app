import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  // Icon 1024x1024 - background merah + S putih
  final size = 1024;
  final icon = img.Image(width: size, height: size);

  // Fill merah
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      icon.setPixelRgba(x, y, 220, 38, 38, 255);
    }
  }

  // Rounded corners effect
  final radius = size ~/ 4;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = (x < radius) ? radius - x : (x > size - radius) ? x - (size - radius) : 0;
      final dy = (y < radius) ? radius - y : (y > size - radius) ? y - (size - radius) : 0;
      if (dx * dx + dy * dy > radius * radius) {
        icon.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }

  Directory('assets/icon').createSync(recursive: true);
  Directory('assets/splash').createSync(recursive: true);

  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(icon));
  File('assets/icon/icon_foreground.png').writeAsBytesSync(img.encodePng(icon));

  // Splash - background transparan + logo putih
  final splash = img.Image(width: 512, height: 512);
  // Transparan
  for (var y = 0; y < 512; y++) {
    for (var x = 0; x < 512; x++) {
      splash.setPixelRgba(x, y, 0, 0, 0, 0);
    }
  }
  // Circle putih di tengah
  img.fillCircle(splash, x: 256, y: 256, radius: 200,
      color: img.ColorRgb8(255, 255, 255));

  File('assets/splash/splash.png').writeAsBytesSync(img.encodePng(splash));
  File('assets/splash/splash_dark.png').writeAsBytesSync(img.encodePng(splash));

  print('✅ Assets created!');
}