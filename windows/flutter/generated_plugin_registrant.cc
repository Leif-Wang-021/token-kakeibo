//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <dynamic_color/dynamic_color_plugin_c_api.h>
#include <flutter_desktop_notifications/windows_notification_plugin_c_api.h>
#include <fullscreen_window/fullscreen_window_plugin_c_api.h>
#include <webview_win_floating/webview_win_floating_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  DynamicColorPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DynamicColorPluginCApi"));
  WindowsNotificationPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WindowsNotificationPluginCApi"));
  FullscreenWindowPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FullscreenWindowPluginCApi"));
  WebviewWinFloatingPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WebviewWinFloatingPluginCApi"));
}
