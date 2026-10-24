import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wic_decode_platform_interface.dart';

/// An implementation of [WicDecodePlatform] that uses method channels.
class MethodChannelWicDecode extends WicDecodePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('wic_decode');

  @override
  Future<Map<String, dynamic>> decodeImageToRawPixelFile({
    required String srcImage,
    required String destFile,
    int? outWidth,
    int? outHeight,
  }) async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'decodeImageToRawPixelFile',
      <String, dynamic>{
        'srcImage': srcImage,
        'destFile': destFile,
        'outWidth': outWidth,
        'outHeight': outHeight,
      },
    );
    if (result == null) {
      return <String, dynamic>{};
    }
    return Map<String, dynamic>.from(result);
  }
}
