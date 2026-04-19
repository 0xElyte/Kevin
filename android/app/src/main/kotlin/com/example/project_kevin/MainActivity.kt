package com.example.project_kevin

import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "com.projectkevin/os_bridge"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openApp" -> {
                        val appName = call.argument<String>("appName") ?: ""
                        handleOpenApp(appName, result)
                    }
                    "navigateToSettings" -> {
                        val action = call.argument<String>("action") ?: ""
                        handleNavigateToSettings(action, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // -------------------------------------------------------------------------
    // openApp — fuzzy PackageManager lookup + Intent.ACTION_MAIN launch
    // -------------------------------------------------------------------------

    private fun handleOpenApp(appName: String, result: MethodChannel.Result) {
        val pm = packageManager
        val launchableApps = pm.getInstalledApplications(PackageManager.GET_META_DATA)

        // Fuzzy, case-insensitive match against the app's label.
        val query = appName.trim().lowercase()
        val match = launchableApps.firstOrNull { appInfo ->
            val label = pm.getApplicationLabel(appInfo).toString().lowercase()
            label.contains(query) || query.contains(label)
        }

        if (match == null) {
            result.success(
                mapOf(
                    "success" to false,
                    "errorMessage" to "No installed app found matching \"$appName\"."
                )
            )
            return
        }

        val launchIntent = pm.getLaunchIntentForPackage(match.packageName)
        if (launchIntent == null) {
            result.success(
                mapOf(
                    "success" to false,
                    "errorMessage" to "\"${pm.getApplicationLabel(match)}\" cannot be launched directly."
                )
            )
            return
        }

        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            startActivity(launchIntent)
            result.success(mapOf("success" to true))
        } catch (e: Exception) {
            result.success(
                mapOf(
                    "success" to false,
                    "errorMessage" to "Failed to launch app: ${e.localizedMessage}"
                )
            )
        }
    }

    // -------------------------------------------------------------------------
    // navigateToSettings — android.settings.* intent launch
    // -------------------------------------------------------------------------

    private fun handleNavigateToSettings(action: String, result: MethodChannel.Result) {
        if (action.isEmpty()) {
            result.success(
                mapOf("success" to false, "errorMessage" to "No settings action provided.")
            )
            return
        }

        val intent = Intent(action).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        try {
            startActivity(intent)
            result.success(mapOf("success" to true))
        } catch (e: Exception) {
            result.success(
                mapOf(
                    "success" to false,
                    "errorMessage" to "Could not open settings ($action): ${e.localizedMessage}"
                )
            )
        }
    }
}
