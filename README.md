# wic_decode

[![pub package](https://img.shields.io/pub/v/wic_decode.svg)](https://pub.dev/packages/wic_decode)

A Flutter plugin for decoding images on Windows using the Windows Imaging Component (WIC).

## Features

- Decode an image file to raw RGBA pixels via `decodeImageToRawPixelFile`.
- Read the decoded image's EXIF/XMP/WIC orientation (`1`–`8`, defaults to `1`).
- Decode the resulting raw pixel file into a `dart:ui.Image` with `decodeRawPixelFileToUIImage`.
- Display an image with orientation applied using `WicDecode.buildImageViewFromUIImage`.

## Usage

```dart
import 'package:flutter/widgets.dart';
import 'package:wic_decode/wic_decode.dart';

final plugin = WicDecode();

final result = await plugin.decodeImageToRawPixelFile(
  srcImage: 'input.jpg',
  destFile: 'output.raw',
);

final image = await plugin.decodeRawPixelFileToUIImage(
  filePath: 'output.raw',
  width: result.width,
  height: result.height,
);

// Apply EXIF orientation when displaying:
WicDecode.buildImageViewFromUIImage(image, result.orientation);
```

`result` exposes:

- `result.width` — output image width
- `result.height` — output image height
- `result.orientation` — EXIF/XMP orientation (1–8), defaults to 1

## Platform support

- Windows only.
