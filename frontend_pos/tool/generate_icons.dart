import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final tealColor = img.ColorRgba8(0, 121, 107, 255); // #00796B
  final whiteColor = img.ColorRgba8(255, 255, 255, 255);
  final transparentColor = img.ColorRgba8(0, 0, 0, 0);

  // Ensure directories exist
  Directory('assets/images').createSync(recursive: true);

  // 1. Generate Full Bleed Solid Logo (assets/images/logo.png)
  final solidImage = img.Image(width: size, height: size, numChannels: 4);
  img.fill(solidImage, color: tealColor);
  _drawZenviTriangle(solidImage, size, whiteColor, 0.28, 0.075);
  File('assets/images/logo.png').writeAsBytesSync(img.encodePng(solidImage));
  print('Generated assets/images/logo.png');

  // 2. Generate Adaptive Icon Foreground (Transparent background, centered in safe zone)
  final foregroundImage = img.Image(width: size, height: size, numChannels: 4);
  img.fill(foregroundImage, color: transparentColor);
  _drawZenviTriangle(foregroundImage, size, whiteColor, 0.34, 0.065);
  File('assets/images/logo_foreground.png').writeAsBytesSync(img.encodePng(foregroundImage));
  print('Generated assets/images/logo_foreground.png');

  // 3. Generate Splash Screen Logo (512x512 with transparent background and white logo)
  const splashSize = 512;
  final splashImage = img.Image(width: splashSize, height: splashSize, numChannels: 4);
  img.fill(splashImage, color: transparentColor);
  _drawZenviTriangle(splashImage, splashSize, whiteColor, 0.26, 0.08);
  
  // Save splash drawable for Android
  final splashDir = Directory('android/app/src/main/res/drawable');
  if (!splashDir.existsSync()) splashDir.createSync(recursive: true);
  File('android/app/src/main/res/drawable/ic_splash_logo.png').writeAsBytesSync(img.encodePng(splashImage));
  print('Generated android/app/src/main/res/drawable/ic_splash_logo.png');

  // Also save to assets/images/splash_logo.png
  File('assets/images/splash_logo.png').writeAsBytesSync(img.encodePng(splashImage));
  print('Done all icon generation!');
}

void _drawZenviTriangle(
  img.Image image,
  int size,
  img.Color color,
  double paddingFraction,
  double thicknessFraction,
) {
  final paddingX = size * paddingFraction;
  final paddingY = size * paddingFraction;
  final thickness = (size * thicknessFraction).round();

  final topLeftX = paddingX;
  final topLeftY = paddingY;
  final topRightX = size - paddingX;
  final topRightY = paddingY;
  final bottomCenterX = size / 2.0;
  final bottomCenterY = size - paddingY * 1.15;

  final topWidth = topRightX - topLeftX;
  final gapStartX = (topLeftX + topWidth * 0.24).round();
  final gapEndX = (topLeftX + topWidth * 0.38).round();

  final tlX = topLeftX.round();
  final tlY = topLeftY.round();
  final trX = topRightX.round();
  final trY = topRightY.round();
  final bcX = bottomCenterX.round();
  final bcY = bottomCenterY.round();

  // Draw lines with thickness
  img.drawLine(image, x1: gapStartX, y1: tlY, x2: tlX, y2: tlY, color: color, thickness: thickness);
  img.drawLine(image, x1: tlX, y1: tlY, x2: bcX, y2: bcY, color: color, thickness: thickness);
  img.drawLine(image, x1: bcX, y1: bcY, x2: trX, y2: trY, color: color, thickness: thickness);
  img.drawLine(image, x1: trX, y1: trY, x2: gapEndX, y2: trY, color: color, thickness: thickness);
}
