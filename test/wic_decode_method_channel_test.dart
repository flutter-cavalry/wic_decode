import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wic_decode/wic_decode.dart';
import 'package:wic_decode/wic_decode_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelWicDecode platform = MethodChannelWicDecode();
  const MethodChannel channel = MethodChannel('wic_decode');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return <String, dynamic>{'width': 1, 'height': 1, 'orientation': 1};
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('decodeToFile', () async {
    final result = await platform.decodeToFile(srcImage: 'src', destFile: 'dest');
    expect(result.width, 1);
    expect(result.height, 1);
    expect(result.orientation, 1);
  });
}
