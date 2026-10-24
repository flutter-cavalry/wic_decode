import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:path/path.dart' as p;
import 'package:wic_decode/wic_decode.dart';

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
}
