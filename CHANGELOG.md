## 0.2.1

- Fix color shift (blue sky turning yellow) when an output size is set on HDR/wide-gamut images: `IWICBitmapScaler` emits BGRA regardless of input format, so its output is now converted back to RGBA.

## 0.2.0

- Treat `outWidth`/`outHeight` as a maximum size: scale down preserving aspect ratio, never upscaling, and return the actual output dimensions.

## 0.1.0

- Initial release.
