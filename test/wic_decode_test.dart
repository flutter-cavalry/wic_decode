import 'package:flutter_test/flutter_test.dart';
import 'package:wic_decode/wic_decode.dart';
import 'package:wic_decode/wic_decode_platform_interface.dart';
import 'package:wic_decode/wic_decode_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWicDecodePlatform
    with MockPlatformInterfaceMixin
    implements WicDecodePlatform {
  @override
  Future<Map<String, dynamic>> decodeToFile({
    required String srcImage,
    required String destFile,
    int? outWidth,
    int? outHeight,
  }) async {
    return <String, dynamic>{'width': 1, 'height': 1, 'orientation': 1};
  }
}

void main() {
  final WicDecodePlatform initialPlatform = WicDecodePlatform.instance;

  test('$MethodChannelWicDecode is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWicDecode>());
  });

  test('decodeToFile', () async {
    WicDecode wicDecodePlugin = WicDecode();
    MockWicDecodePlatform fakePlatform = MockWicDecodePlatform();
    WicDecodePlatform.instance = fakePlatform;

    await wicDecodePlugin.decodeToFile(
      srcImage: 'src',
      destFile: 'dest',
    );
  });
}
