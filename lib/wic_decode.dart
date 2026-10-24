import 'dart:async';
import 'dart:io';

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'wic_decode_platform_interface.dart';

class WicDecode {
  Future<Map<String, dynamic>> decodeImageToRawPixelFile({
    required String srcImage,
    required String destFile,
    int? outWidth,
    int? outHeight,
  }) {
    return WicDecodePlatform.instance.decodeImageToRawPixelFile(
      srcImage: srcImage,
      destFile: destFile,
      outWidth: outWidth,
      outHeight: outHeight,
    );
  }

  /// Decodes a raw RGBA pixel file produced by [decodeImageToRawPixelFile] into a [ui.Image].
  Future<ui.Image> decodeRawPixelFileToUIImage({
    required String filePath,
    required int width,
    required int height,
  }) {
    return _decodeRawPixelFileToUIImage(
      filePath: filePath,
      width: width,
      height: height,
    );
  }

  /// Builds a widget that displays [image] with the EXIF [orientation] applied.
  static Widget buildImageViewFromUIImage(ui.Image image, [int orientation = 1]) {
    int quarterTurns = 0;
    bool flipX = false;
    bool flipY = false;
    switch (orientation) {
      case 2:
        flipX = true;
        break;
      case 3:
        quarterTurns = 2;
        break;
      case 4:
        flipY = true;
        break;
      case 5:
        quarterTurns = 1;
        flipX = true;
        break;
      case 6:
        quarterTurns = 1;
        break;
      case 7:
        quarterTurns = 3;
        flipX = true;
        break;
      case 8:
        quarterTurns = 3;
        break;
      default:
        break;
    }

    Widget child = RawImage(
      image: image,
      fit: BoxFit.contain,
    );

    if (flipX || flipY) {
      child = Transform.scale(
        scaleX: flipX ? -1.0 : 1.0,
        scaleY: flipY ? -1.0 : 1.0,
        alignment: Alignment.center,
        child: child,
      );
    }

    if (quarterTurns != 0) {
      child = RotatedBox(
        quarterTurns: quarterTurns,
        child: child,
      );
    }

    return FittedBox(
      fit: BoxFit.contain,
      child: child,
    );
  }
}

/// Convenience accessors for the size returned by [WicDecode.decodeImageToRawPixelFile].
extension WicDecodeSize on Map<String, dynamic> {
  int get width => this['width'] as int;
  int get height => this['height'] as int;
  int get orientation => (this['orientation'] as int?) ?? 1;
}

Future<ui.Image> _decodeRawPixelFileToUIImage({
  required String filePath,
  required int width,
  required int height,
}) async {
  final rawBytes = await File(filePath).readAsBytes();
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    rawBytes,
    width,
    height,
    ui.PixelFormat.rgba8888,
    (image) => completer.complete(image),
  );
  return completer.future;
}
