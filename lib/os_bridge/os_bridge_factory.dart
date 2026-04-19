import 'dart:io';

import '../services/intent_router.dart';
import 'android_os_bridge.dart';
import 'windows_os_bridge.dart';

/// Returns the platform-appropriate [IOSBridge] implementation.
///
/// Returns `null` if the current platform is not supported.
IOSBridge? createOSBridge() {
  if (Platform.isAndroid) return AndroidOSBridge();
  if (Platform.isWindows) return WindowsOSBridge();
  return null;
}
