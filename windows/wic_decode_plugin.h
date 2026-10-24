#ifndef FLUTTER_PLUGIN_WIC_DECODE_PLUGIN_H_
#define FLUTTER_PLUGIN_WIC_DECODE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace wic_decode {

class WicDecodePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  WicDecodePlugin();

  virtual ~WicDecodePlugin();

  // Disallow copy and assign.
  WicDecodePlugin(const WicDecodePlugin&) = delete;
  WicDecodePlugin& operator=(const WicDecodePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace wic_decode

#endif  // FLUTTER_PLUGIN_WIC_DECODE_PLUGIN_H_
