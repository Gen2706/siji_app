// Tool untuk generate asset SIJI
// Jalankan: dart run create_assets.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() {
  // Buat icon 1024x1024
  final icon = img.Image(width: 1024, height: 1024);

  // Background merah
  img.fill(icon, color: img.ColorRgb8(220, 38, 38));

  // Simpan
  File('assets/icon/icon.png')
      .writeAsBytesSync(img.encodePng(icon));

  print('Assets created!');
}