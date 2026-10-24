import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:path/path.dart' as p;
import 'package:wic_decode/wic_decode.dart';

void writeBmp(File file, int width, int height) {
  final rowStride = (width * 3 + 3) & ~3;
  final imageSize = rowStride * height;
  final fileSize = 54 + imageSize;
  final bytes = Uint8List(fileSize);
  final bd = ByteData.view(bytes.buffer);
  bytes[0] = 0x42;
  bytes[1] = 0x4D;
  bd.setUint32(2, fileSize, Endian.little);
  bd.setUint32(10, 54, Endian.little);
  bd.setUint32(14, 40, Endian.little);
  bd.setInt32(18, width, Endian.little);
  bd.setInt32(22, height, Endian.little);
  bd.setUint16(26, 1, Endian.little);
  bd.setUint16(28, 24, Endian.little);
  bd.setUint32(34, imageSize, Endian.little);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final offset = 54 + (height - 1 - y) * rowStride + x * 3;
      bytes[offset] = (x * 60 + y * 20) & 0xFF;
      bytes[offset + 1] = (y * 60) & 0xFF;
      bytes[offset + 2] = (x * 60) & 0xFF;
    }
  }
  file.writeAsBytesSync(bytes, flush: true);
}

void addOrientationTest(
  String label,
  String fileName,
  int width,
  int height,
  int orientation,
) {
  testWidgets('orientation: $label', (WidgetTester tester) async {
    final plugin = WicDecode();
    final dataDir = Directory(
      p.join(Directory.current.path, 'integration_test', 'data'),
    );
    final src = File(p.join(dataDir.path, fileName));
    final dest = File(
      p.join(Directory.systemTemp.path, 'wic_orient_$label.raw'),
    );
    expect(await src.exists(), isTrue);
    final result = await plugin.decodeImageToRawPixelFile(
      srcImage: src.path,
      destFile: dest.path,
    );
    expect(result.width, width);
    expect(result.height, height);
    expect(result.orientation, orientation);
  });
}


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('decodeToFile test', (WidgetTester tester) async {
    final plugin = WicDecode();
    final dir = Directory.systemTemp;
    final src = File(p.join(dir.path, 'wic_integration_sample.png'));
    final dest = File(p.join(dir.path, 'wic_integration_output.raw'));
    src.writeAsBytesSync(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAYAAACp8Z5+AAAAHklEQVQI12P4'
      '//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==',
    ));
    await plugin.decodeImageToRawPixelFile(srcImage: src.path, destFile: dest.path);
    expect(dest.existsSync(), isTrue);
    expect(dest.lengthSync() > 0, isTrue);

    await plugin.decodeImageToRawPixelFile(
      srcImage: src.path,
      destFile: p.join(dir.path, 'wic_integration_resized.raw'),
      outWidth: 2,
      outHeight: 2,
    );
  });
  testWidgets('decodeWicRawPixelFile test', (WidgetTester tester) async {
    final plugin = WicDecode();
    final dir = Directory.systemTemp;
    final src = File(p.join(dir.path, 'wic_raw_sample.png'));
    final dest = File(p.join(dir.path, 'wic_raw_output.raw'));
    src.writeAsBytesSync(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAYAAACp8Z5+AAAAHklEQVQI12P4'
      '//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==',
    ));

    final size = await plugin.decodeImageToRawPixelFile(srcImage: src.path, destFile: dest.path);
    expect(size.width, 4);
    expect(size.height, 4);
    final image = await plugin.decodeRawPixelFileToUIImage(
      filePath: dest.path,
      width: size.width,
      height: size.height,
    );
    expect(image.width, 4);
    expect(image.height, 4);
    image.dispose();

    final resizedDest = File(p.join(dir.path, 'wic_raw_resized.raw'));
    final resizedSize = await plugin.decodeImageToRawPixelFile(
      srcImage: src.path,
      destFile: resizedDest.path,
      outWidth: 2,
      outHeight: 2,
    );
    expect(resizedSize.width, 2);
    expect(resizedSize.height, 2);
    final resizedImage = await plugin.decodeRawPixelFileToUIImage(
      filePath: resizedDest.path,
      width: resizedSize.width,
      height: resizedSize.height,
    );
    expect(resizedImage.width, 2);
    expect(resizedImage.height, 2);
    resizedImage.dispose();
  });

  testWidgets('decode scales down to max size keeping aspect ratio',
      (WidgetTester tester) async {
    final plugin = WicDecode();
    final dir = Directory.systemTemp;
    final src = File(p.join(dir.path, 'wic_aspect_src.bmp'));
    writeBmp(src, 4, 2);

    // Original size is returned when no max size is given.
    final original = await plugin.decodeImageToRawPixelFile(
      srcImage: src.path,
      destFile: p.join(dir.path, 'wic_aspect_original.raw'),
    );
    expect(original.width, 4);
    expect(original.height, 2);

    // Max size 2x2: width is limiting, height scales proportionally.
    final resizedDest = File(p.join(dir.path, 'wic_aspect_resized.raw'));
    final resized = await plugin.decodeImageToRawPixelFile(
      srcImage: src.path,
      destFile: resizedDest.path,
      outWidth: 2,
      outHeight: 2,
    );
    expect(resized.width, 2);
    expect(resized.height, 1);
    expect(resizedDest.lengthSync(), 2 * 1 * 4);

    final image = await plugin.decodeRawPixelFileToUIImage(
      filePath: resizedDest.path,
      width: resized.width,
      height: resized.height,
    );
    expect(image.width, 2);
    expect(image.height, 1);
    image.dispose();

    // A max size larger than the source must not upscale.
    final upscaledDest = File(p.join(dir.path, 'wic_aspect_upscaled.raw'));
    final upscaled = await plugin.decodeImageToRawPixelFile(
      srcImage: src.path,
      destFile: upscaledDest.path,
      outWidth: 8,
      outHeight: 8,
    );
    expect(upscaled.width, 4);
    expect(upscaled.height, 2);

    // Height-limited max size.
    final heightLimitedDest =
        File(p.join(dir.path, 'wic_aspect_height_limited.raw'));
    final heightLimited = await plugin.decodeImageToRawPixelFile(
      srcImage: src.path,
      destFile: heightLimitedDest.path,
      outWidth: 4,
      outHeight: 1,
    );
    expect(heightLimited.width, 2);
    expect(heightLimited.height, 1);
  });

  addOrientationTest('png', 'orient.png', 100, 70, 8);
  addOrientationTest('jpg', 'orient.jpg', 100, 70, 8);
  addOrientationTest('heic', 'orient.heic', 70, 100, 1);
  addOrientationTest('avif', 'orient.avif', 70, 100, 1);
  addOrientationTest('jxl', 'orient.jxl', 70, 100, 1);
}
