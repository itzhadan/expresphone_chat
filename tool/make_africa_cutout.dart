import 'dart:collection';
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final source = File('assets/africa.png').readAsBytesSync();
  final original = img.decodePng(source);
  if (original == null) {
    throw StateError('Could not read assets/africa.png');
  }

  final width = original.width;
  final height = original.height;
  final outside = List<bool>.filled(width * height, false);
  final queue = Queue<(int, int)>();

  bool isBackground(int x, int y) {
    final pixel = original.getPixel(x, y);
    return pixel.r > 232 && pixel.g > 232 && pixel.b > 232;
  }

  void add(int x, int y) {
    final index = y * width + x;
    if (outside[index] || !isBackground(x, y)) return;
    outside[index] = true;
    queue.add((x, y));
  }

  for (var x = 0; x < width; x++) {
    add(x, 0);
    add(x, height - 1);
  }
  for (var y = 0; y < height; y++) {
    add(0, y);
    add(width - 1, y);
  }

  while (queue.isNotEmpty) {
    final (x, y) = queue.removeFirst();
    if (x > 0) add(x - 1, y);
    if (x < width - 1) add(x + 1, y);
    if (y > 0) add(x, y - 1);
    if (y < height - 1) add(x, y + 1);
  }

  final cutout = img.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (outside[y * width + x]) {
        cutout.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }
      final pixel = original.getPixel(x, y);
      final luminance = ((pixel.r + pixel.g + pixel.b) / 3).round();
      final shade = (180 + (luminance - 130) * 0.30).round().clamp(176, 224);
      final alpha = luminance > 232 ? 155 : 238;
      cutout.setPixelRgba(x, y, shade, shade + 4, shade + 7, alpha);
    }
  }

  File('assets/africa_cutout.png').writeAsBytesSync(img.encodePng(cutout));
}
