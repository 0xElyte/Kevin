enum SettingsTarget { wifi, bluetooth, display, sound, battery, storage }

class OSActionResult {
  final bool success;
  final String? errorMessage;

  const OSActionResult({required this.success, this.errorMessage});
}
