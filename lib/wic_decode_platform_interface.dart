import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'wic_decode_method_channel.dart';

abstract class WicDecodePlatform extends PlatformInterface {
  /// Constructs a WicDecodePlatform.
  WicDecodePlatform() : super(token: _token);

  static final Object _token = Object();

  static WicDecodePlatform _instance = MethodChannelWicDecode();

  /// The default instance of [WicDecodePlatform] to use.
  ///
  /// Defaults to [MethodChannelWicDecode].
  static WicDecodePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WicDecodePlatform] when
  /// they register themselves.
  static set instance(WicDecodePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Map<String, dynamic>> decodeToFile({
    required String srcImage,
    required String destFile,
    int? outWidth,
    int? outHeight,
  }) {
    throw UnimplementedError('decodeToFile() has not been implemented.');
  }
}
