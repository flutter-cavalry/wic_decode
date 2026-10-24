# wic_decode

[![pub package](https://img.shields.io/pub/v/wic_decode.svg)](https://pub.dev/packages/wic_decode)

A Flutter plugin for decoding images on Windows using the Windows Imaging Component (WIC).

## Features

- Decode an image file to raw RGBA pixels via `decodeToFile`.
- Read the decoded image's EXIF/WIC orientation (`1`–`8`, defaults to `1`).
- Decode the resulting raw pixel file into a `dart:ui.Image` with `decodeWicRawPixelFile`.
- Display an image with orientation applied using `WicDecode.buildImageView`.

## Usage

```dart
import 'package:flutter/widgets.dart';
import 'package:wic_decode/wic_decode.dart';

final plugin = WicDecode();

final result = await plugin.decodeToFile(
  srcImage: 'input.jpg',
  destFile: 'output.raw',
);

final image = await plugin.decodeWicRawPixelFile(
  filePath: 'output.raw',
  width: result.width,
  height: result.height,
);

// Apply EXIF orientation when displaying:
WicDecode.buildImageView(image, result.orientation);
```

`result` exposes:

- `result.width` — output image width
- `result.height` — output image height
- `result.orientation` — EXIF orientation (1–8), defaults to 1

## Platform support

- Windows only.
