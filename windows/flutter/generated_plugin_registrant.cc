//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_pos_printer_platform/flutter_pos_printer_platform_plugin.h>
#include <flutter_thermal_printer/flutter_thermal_printer_plugin_c_api.h>
#include <network_info_plus/network_info_plus_windows_plugin.h>
#include <printing/printing_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FlutterPosPrinterPlatformPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterPosPrinterPlatformPlugin"));
  FlutterThermalPrinterPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterThermalPrinterPluginCApi"));
  NetworkInfoPlusWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("NetworkInfoPlusWindowsPlugin"));
  PrintingPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PrintingPlugin"));
}
