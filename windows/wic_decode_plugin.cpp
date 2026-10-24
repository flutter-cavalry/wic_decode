#include "wic_decode_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <wincodec.h>

#include <propvarutil.h>
#include <wrl/client.h>

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <memory>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

namespace {

using Microsoft::WRL::ComPtr;

std::wstring Utf8ToWide(const std::string &input) {
  if (input.empty()) {
    return std::wstring();
  }
  int size = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, input.c_str(),
                                static_cast<int>(input.size()), nullptr, 0);
  if (size <= 0) {
    size = MultiByteToWideChar(CP_ACP, 0, input.c_str(),
                               static_cast<int>(input.size()), nullptr, 0);
    if (size <= 0) {
      return std::wstring();
    }
    std::wstring result(size, L'\0');
    MultiByteToWideChar(CP_ACP, 0, input.c_str(),
                        static_cast<int>(input.size()), result.data(), size);
    return result;
  }
  std::wstring result(size, L'\0');
  MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, input.c_str(),
                      static_cast<int>(input.size()), result.data(), size);
  return result;
}

std::string WideToUtf8(const std::wstring &input) {
  if (input.empty()) {
    return std::string();
  }
  int size = WideCharToMultiByte(CP_UTF8, 0, input.c_str(),
                                 static_cast<int>(input.size()), nullptr, 0,
                                 nullptr, nullptr);
  if (size <= 0) {
    return std::string();
  }
  std::string result(size, '\0');
  WideCharToMultiByte(CP_UTF8, 0, input.c_str(),
                      static_cast<int>(input.size()), result.data(), size,
                      nullptr, nullptr);
  return result;
}

bool DecodeImageToRawPixelFile(const std::string &srcImage, const std::string &destFile,
                  bool hasSize, int outWidth, int outHeight,
                  int &resultWidth, int &resultHeight,
                  int &resultOrientation,
                  std::string &error) {
  HRESULT hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  const bool coInitialized = SUCCEEDED(hr);
  if (FAILED(hr) && hr != RPC_E_CHANGED_MODE) {
    error = "Failed to initialize COM.";
    return false;
  }

  bool success = false;
  do {
    ComPtr<IWICImagingFactory> factory;
    hr = CoCreateInstance(CLSID_WICImagingFactory2, nullptr, CLSCTX_INPROC_SERVER,
                          IID_PPV_ARGS(&factory));
    if (FAILED(hr)) {
      hr = CoCreateInstance(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER,
                            IID_PPV_ARGS(&factory));
      if (FAILED(hr)) {
        error = "Failed to create WIC imaging factory.";
        break;
      }
    }

    std::wstring wsrc = Utf8ToWide(srcImage);
    ComPtr<IWICBitmapDecoder> decoder;
    hr = factory->CreateDecoderFromFilename(wsrc.c_str(), nullptr, GENERIC_READ,
                                            WICDecodeMetadataCacheOnDemand,
                                            &decoder);
    if (FAILED(hr)) {
      error = "Failed to open source image: " + srcImage;
      break;
    }

    ComPtr<IWICBitmapFrameDecode> frame;
    hr = decoder->GetFrame(0, &frame);
    if (FAILED(hr)) {
      error = "Failed to read image frame.";
      break;
    }

    int orientation = 1;
    {
      ComPtr<IWICMetadataQueryReader> metadataReader;
      if (SUCCEEDED(frame->GetMetadataQueryReader(&metadataReader)) &&
          metadataReader) {
        PROPVARIANT value;
        PropVariantInit(&value);
        if (SUCCEEDED(metadataReader->GetMetadataByName(
                L"System.Photo.Orientation", &value))) {
          switch (value.vt) {
            case VT_UI1:
              orientation = value.bVal;
              break;
            case VT_I2:
              orientation = value.iVal;
              break;
            case VT_UI2:
              orientation = value.uiVal;
              break;
            case VT_I4:
              orientation = value.lVal;
              break;
            case VT_UI4:
              orientation = static_cast<int>(value.ulVal);
              break;
            case VT_INT:
              orientation = value.intVal;
              break;
            case VT_UINT:
              orientation = static_cast<int>(value.uintVal);
              break;
            default:
              break;
          }
          if (orientation < 1 || orientation > 8) {
            orientation = 1;
          }
        }
        PropVariantClear(&value);
      }
    }

    ComPtr<IWICFormatConverter> converter;
    hr = factory->CreateFormatConverter(&converter);
    if (FAILED(hr)) {
      error = "Failed to create format converter.";
      break;
    }
    hr = converter->Initialize(frame.Get(), GUID_WICPixelFormat32bppRGBA,
                               WICBitmapDitherTypeNone, nullptr, 0.0,
                               WICBitmapPaletteTypeMedianCut);
    if (FAILED(hr)) {
      error = "Failed to convert to 32bpp RGBA.";
      break;
    }

    UINT srcWidth = 0;
    UINT srcHeight = 0;
    if (FAILED(converter->GetSize(&srcWidth, &srcHeight))) {
      error = "Failed to get image size.";
      break;
    }

    ComPtr<IWICBitmapSource> source = converter;

    if (hasSize) {
      if (outWidth <= 0 || outHeight <= 0) {
        error = "Invalid output size.";
        break;
      }
      UINT targetWidth = srcWidth;
      UINT targetHeight = srcHeight;
      if (srcWidth > 0 && srcHeight > 0) {
        const double scaleX = static_cast<double>(outWidth) / srcWidth;
        const double scaleY = static_cast<double>(outHeight) / srcHeight;
        const double scale = (std::min)(scaleX, scaleY);
        if (scale < 1.0) {
          targetWidth = static_cast<UINT>(std::lround(srcWidth * scale));
          targetHeight = static_cast<UINT>(std::lround(srcHeight * scale));
          if (targetWidth < 1) targetWidth = 1;
          if (targetHeight < 1) targetHeight = 1;
          while (targetWidth > static_cast<UINT>(outWidth)) targetWidth--;
          while (targetHeight > static_cast<UINT>(outHeight)) targetHeight--;
        }
      }
      if (targetWidth != srcWidth || targetHeight != srcHeight) {
        ComPtr<IWICBitmapScaler> scaler;
        hr = factory->CreateBitmapScaler(&scaler);
        if (FAILED(hr)) {
          error = "Failed to create bitmap scaler.";
          break;
        }
        hr = scaler->Initialize(converter.Get(), targetWidth, targetHeight,
                                WICBitmapInterpolationModeFant);
        if (FAILED(hr)) {
          error = "Failed to scale image.";
          break;
        }
        // IWICBitmapScaler always emits 32bppBGRA regardless of the source
        // pixel format, so wrap it in a format converter to restore the
        // 32bppRGBA layout the rest of the pipeline (and Dart) expects.
        ComPtr<IWICFormatConverter> scaledConverter;
        hr = factory->CreateFormatConverter(&scaledConverter);
        if (FAILED(hr)) {
          error = "Failed to create format converter.";
          break;
        }
        hr = scaledConverter->Initialize(
            scaler.Get(), GUID_WICPixelFormat32bppRGBA,
            WICBitmapDitherTypeNone, nullptr, 0.0,
            WICBitmapPaletteTypeMedianCut);
        if (FAILED(hr)) {
          error = "Failed to convert scaled image.";
          break;
        }
        source = scaledConverter;
      }
    }

    UINT width = 0;
    UINT height = 0;
    hr = source->GetSize(&width, &height);
    if (FAILED(hr)) {
      error = "Failed to get image size.";
      break;
    }
    resultWidth = static_cast<int>(width);
    resultHeight = static_cast<int>(height);
    resultOrientation = orientation;

    const UINT stride = width * 4;
    const size_t bufferSize = static_cast<size_t>(stride) * height;
    std::vector<BYTE> buffer(bufferSize);

    WICRect rect = {0, 0, static_cast<INT>(width), static_cast<INT>(height)};
    hr = source->CopyPixels(&rect, stride, static_cast<UINT>(bufferSize),
                            buffer.data());
    if (FAILED(hr)) {
      error = "Failed to copy pixels.";
      break;
    }

    std::wstring wdest = Utf8ToWide(destFile);
    std::ofstream out(std::filesystem::path(wdest), std::ios::binary | std::ios::trunc);
    if (!out) {
      error = "Failed to open destination file: " + destFile;
      break;
    }
    out.write(reinterpret_cast<const char *>(buffer.data()),
              static_cast<std::streamsize>(buffer.size()));
    if (!out) {
      error = "Failed to write destination file: " + destFile;
      break;
    }
    out.close();

    success = true;
  } while (false);

  if (coInitialized) {
    CoUninitialize();
  }
  return success;
}

}  // namespace

namespace wic_decode {

// static
void WicDecodePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "wic_decode",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<WicDecodePlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

WicDecodePlugin::WicDecodePlugin() {}

WicDecodePlugin::~WicDecodePlugin() {}

void WicDecodePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("decodeImageToRawPixelFile") == 0) {
    const auto *args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!args) {
      result->Error("invalid_arguments", "Expected a map of arguments.");
      return;
    }

    auto getString = [&args](const char *key) -> std::string {
      auto it = args->find(flutter::EncodableValue(std::string(key)));
      if (it == args->end()) {
        return std::string();
      }
      if (auto *v = std::get_if<std::string>(&it->second)) {
        return *v;
      }
      return std::string();
    };
    auto getInt = [&args](const char *key, bool *present) -> int {
      *present = false;
      auto it = args->find(flutter::EncodableValue(std::string(key)));
      if (it == args->end() || std::holds_alternative<std::monostate>(it->second)) {
        return 0;
      }
      *present = true;
      if (auto *v = std::get_if<int32_t>(&it->second)) {
        return *v;
      }
      if (auto *v = std::get_if<int64_t>(&it->second)) {
        return static_cast<int>(*v);
      }
      if (auto *v = std::get_if<double>(&it->second)) {
        return static_cast<int>(*v);
      }
      return 0;
    };

    const std::string srcImage = getString("srcImage");
    const std::string destFile = getString("destFile");
    if (srcImage.empty() || destFile.empty()) {
      result->Error("invalid_arguments",
                    "srcImage and destFile are required.");
      return;
    }

    bool widthPresent = false;
    bool heightPresent = false;
    int outWidth = getInt("outWidth", &widthPresent);
    int outHeight = getInt("outHeight", &heightPresent);
    const bool hasSize = widthPresent || heightPresent;
    if (hasSize && !(widthPresent && heightPresent)) {
      result->Error("invalid_arguments",
                    "outWidth and outHeight must both be provided.");
      return;
    }

    auto result_shared =
        std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(
            result.release());

    std::thread([srcImage, destFile, hasSize, outWidth, outHeight,
                 result_shared]() {
      std::string error;
      int resultWidth = 0;
      int resultHeight = 0;
      int resultOrientation = 1;
      if (DecodeImageToRawPixelFile(srcImage, destFile, hasSize, outWidth, outHeight,
                       resultWidth, resultHeight, resultOrientation, error)) {
        flutter::EncodableMap result_map;
        result_map[flutter::EncodableValue(std::string("width"))] =
            flutter::EncodableValue(resultWidth);
        result_map[flutter::EncodableValue(std::string("height"))] =
            flutter::EncodableValue(resultHeight);
        result_map[flutter::EncodableValue(std::string("orientation"))] =
            flutter::EncodableValue(resultOrientation);
        result_shared->Success(flutter::EncodableValue(result_map));
      } else {
        result_shared->Error("decode_failed", error);
      }
    }).detach();
  } else {
    result->NotImplemented();
  }
}

}  // namespace wic_decode
