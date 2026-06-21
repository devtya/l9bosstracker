import 'dart:io';
import 'package:image/image.dart';

void main() {
  final file = File('assets/icon/l9_icon_square_1024.png');
  final bytes = file.readAsBytesSync();
  final img = decodeImage(bytes)!;
  
  int bgR = 0x13, bgG = 0x11, bgB = 0x1f;
  
  int minX = 9999, minY = 9999, maxX = 0, maxY = 0;
  
  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      final p = img.getPixel(x, y);
      if ((p.r - bgR).abs() > 10 || (p.g - bgG).abs() > 10 || (p.b - bgB).abs() > 10) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }
  
  final w = maxX - minX + 1;
  final h = maxY - minY + 1;
  
  print('Image size: ${img.width}x${img.height}');
  print('Content bounding box: ($minX, $minY) to ($maxX, $maxY)');
  print('Content size: ${w}x$h');
  
  const safeZone = 1024 * 0.66;
  final safeX1 = (1024 - safeZone) / 2;
  final safeY1 = (1024 - safeZone) / 2;
  final safeX2 = 1024 - safeX1;
  final safeY2 = 1024 - safeY1;
  
  print('\nSafe zone (66%): (${safeX1.toStringAsFixed(0)}, ${safeY1.toStringAsFixed(0)}) to (${safeX2.toStringAsFixed(0)}, ${safeY2.toStringAsFixed(0)})');
  
  bool inside = minX >= safeX1 && minY >= safeY1 && maxX <= safeX2 && maxY <= safeY2;
  print('\nContent fully inside safe zone: $inside');
  
  if (!inside) {
    print('WARNING: Content exceeds safe zone!');
    if (minX < safeX1) print('  Left overflows by ${(safeX1 - minX).toStringAsFixed(0)}px');
    if (minY < safeY1) print('  Top overflows by ${(safeY1 - minY).toStringAsFixed(0)}px');
    if (maxX > safeX2) print('  Right overflows by ${(maxX - safeX2).toStringAsFixed(0)}px');
    if (maxY > safeY2) print('  Bottom overflows by ${(maxY - safeY2).toStringAsFixed(0)}px');
  } else {
    print('Margin - Left: ${(minX - safeX1).toStringAsFixed(0)}, Top: ${(minY - safeY1).toStringAsFixed(0)}');
    print('Margin - Right: ${(safeX2 - maxX).toStringAsFixed(0)}, Bottom: ${(safeY2 - maxY).toStringAsFixed(0)}');
  }
}
