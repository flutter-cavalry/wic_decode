#include "include/wic_decode/wic_decode_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "wic_decode_plugin.h"

void WicDecodePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  wic_decode::WicDecodePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
