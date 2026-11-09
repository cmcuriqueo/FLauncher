/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

package me.efesser.flauncher

import android.Manifest
import android.accessibilityservice.AccessibilityService
import android.app.ActivityManager
import android.app.AlarmManager
import android.bluetooth.BluetoothManager
import android.content.Intent
import android.content.Intent.*
import android.content.pm.*
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.location.LocationManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Build
import android.os.UserHandle
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.Serializable

private const val METHOD_CHANNEL = "me.efesser.flauncher/method"
private const val EVENT_CHANNEL = "me.efesser.flauncher/event"

class MainActivity : FlutterActivity() {
    val launcherAppsCallbacks = ArrayList<LauncherApps.Callback>()
    private var pendingBackupJson: String? = null
    private var pendingBackupResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getApplications" -> result.success(getApplications())
                "applicationExists" -> result.success(applicationExists(call.arguments as String))
                "launchApp" -> result.success(launchApp(call.arguments as String))
                "openSettings" -> result.success(openSettings())
                "openAppInfo" -> result.success(openAppInfo(call.arguments as String))
                "uninstallApp" -> result.success(uninstallApp(call.arguments as String))
                "forceStopApp" -> result.success(forceStopApp(call.arguments as String))
                "isDefaultLauncher" -> result.success(isDefaultLauncher())
                "checkForGetContentAvailability" -> result.success(checkForGetContentAvailability())
                "startAmbientMode" -> result.success(startAmbientMode())
                "getWatchNextPrograms" -> result.success(getWatchNextPrograms())
                "getNetworkStatus" -> result.success(getNetworkStatus())
                "getNetworkDetails" -> result.success(getNetworkDetails())
                "openNetworkSettings" -> result.success(openNetworkSettings())
                "openWifiSettings" -> result.success(openWifiSettings())
                "openBluetoothSettings" -> result.success(openBluetoothSettings())
                "lockScreen" -> result.success(lockScreen())
                "getStorageStatus" -> result.success(getStorageStatus())
                "getLauncherMemoryUsage" -> result.success(getLauncherMemoryUsage())
                "openApplicationManagement" -> result.success(openApplicationManagement())
                "getNextAlarm" -> result.success(getNextAlarm())
                "getLastLocation" -> result.success(getLastLocation())
                "getBluetoothStatus" -> result.success(getBluetoothStatus())
                "saveBackup" -> saveBackup(call.arguments as String, result)
                "readBackup" -> readBackup(result)
                "launchIntentUri" -> result.success(launchIntentUri(call.arguments as String))
                else -> throw IllegalArgumentException()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(object : StreamHandler {
            lateinit var launcherAppsCallback: LauncherApps.Callback
            val launcherApps = getSystemService(LAUNCHER_APPS_SERVICE) as LauncherApps
            override fun onListen(arguments: Any?, events: EventSink) {
                launcherAppsCallback = object : LauncherApps.Callback() {
                    override fun onPackageRemoved(packageName: String, user: UserHandle) {
                        events.success(mapOf("action" to "PACKAGE_REMOVED", "packageName" to packageName))
                    }

                    override fun onPackageAdded(packageName: String, user: UserHandle) {
                        getApplication(packageName)
                            ?.let { events.success(mapOf("action" to "PACKAGE_ADDED", "activitiyInfo" to it)) }
                    }

                    override fun onPackageChanged(packageName: String, user: UserHandle) {
                        getApplication(packageName)
                            ?.let { events.success(mapOf("action" to "PACKAGE_CHANGED", "activitiyInfo" to it)) }
                    }

                    override fun onPackagesAvailable(packageNames: Array<out String>, user: UserHandle, replacing: Boolean) {
                        val applications = packageNames.map(::getApplication)
                        if (applications.isNotEmpty()) {
                            events.success(mapOf("action" to "PACKAGES_AVAILABLE", "activitiesInfo" to applications))
                        }
                    }

                    override fun onPackagesUnavailable(packageNames: Array<out String>, user: UserHandle, replacing: Boolean) {}
                }

                launcherAppsCallbacks.add(launcherAppsCallback)
                launcherApps.registerCallback(launcherAppsCallback)
            }

            override fun onCancel(arguments: Any?) {
                launcherApps.unregisterCallback(launcherAppsCallback)
                launcherAppsCallbacks.remove(launcherAppsCallback)
            }
        })
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        val pending = pendingBackupResult ?: return
        pendingBackupResult = null
        if (resultCode != RESULT_OK || data?.data == null) {
            pending.success(null)
            return
        }
        val uri = data.data!!
        try {
            if (requestCode == 4101) {
                contentResolver.openOutputStream(uri)?.use { stream ->
                    stream.write(pendingBackupJson?.toByteArray() ?: byteArrayOf())
                }
                pending.success(uri.toString())
            } else if (requestCode == 4102) {
                val text = contentResolver.openInputStream(uri)?.bufferedReader()?.use { it.readText() }
                pending.success(text)
            } else {
                pending.success(null)
            }
        } catch (_: Exception) {
            pending.success(null)
        } finally {
            pendingBackupJson = null
        }
    }

    override fun onDestroy() {
        val launcherApps = getSystemService(LAUNCHER_APPS_SERVICE) as LauncherApps
        launcherAppsCallbacks.forEach(launcherApps::unregisterCallback)
        super.onDestroy()
    }

    private fun getNetworkStatus(): Map<String, Any?> = try {
        val connectivityManager = getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val network = connectivityManager.activeNetwork
            val capabilities = network?.let(connectivityManager::getNetworkCapabilities)
            val connectionType = when {
                capabilities == null -> "none"
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
                else -> "other"
            }
            val hasInternet = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true &&
                    capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
            mapOf(
                "hasInternet" to hasInternet,
                "type" to connectionType,
                "ipAddress" to network?.let(connectivityManager::getLinkProperties)?.let(::ipv4Address),
            )
        } else {
            val networkInfo = connectivityManager.activeNetworkInfo
            val connected = networkInfo?.isConnected == true
            val connectionType = when {
                !connected -> "none"
                networkInfo?.type == ConnectivityManager.TYPE_WIFI -> "wifi"
                networkInfo?.type == ConnectivityManager.TYPE_ETHERNET -> "ethernet"
                else -> "other"
            }
            mapOf(
                "hasInternet" to connected,
                "type" to connectionType,
                "ipAddress" to if (connected) legacyIpv4Address() else null,
            )
        }
    } catch (e: Exception) {
        mapOf("hasInternet" to false, "type" to "none", "ipAddress" to null)
    }

    private fun getNetworkDetails(): Map<String, Any?> {
        var gateway: String? = null
        var dnsServers = emptyList<String>()
        var vpnActive = false
        var wifiSignal: Int? = null
        var wifiFrequency: Int? = null
        var wifiLinkSpeed: Int? = null
        try {
            val connectivityManager = getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val network = connectivityManager.activeNetwork
                val capabilities = network?.let(connectivityManager::getNetworkCapabilities)
                val linkProperties = network?.let(connectivityManager::getLinkProperties)
                gateway = linkProperties?.routes
                    ?.firstOrNull { it.gateway is java.net.Inet4Address }
                    ?.gateway?.hostAddress
                dnsServers = linkProperties?.dnsServers?.mapNotNull { it.hostAddress } ?: emptyList()
                vpnActive = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
                if (capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true) {
                    val wifiManager = applicationContext.getSystemService(WIFI_SERVICE) as android.net.wifi.WifiManager
                    @Suppress("DEPRECATION")
                    val connectionInfo = wifiManager.connectionInfo
                    wifiSignal = connectionInfo.rssi
                    wifiLinkSpeed = connectionInfo.linkSpeed
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        wifiFrequency = connectionInfo.frequency
                    }
                }
            } else {
                dnsServers = legacyDnsServers()
                @Suppress("DEPRECATION")
                vpnActive = connectivityManager.activeNetworkInfo?.type == ConnectivityManager.TYPE_VPN
                @Suppress("DEPRECATION")
                if (connectivityManager.activeNetworkInfo?.type == ConnectivityManager.TYPE_WIFI) {
                    val wifiManager = applicationContext.getSystemService(WIFI_SERVICE) as android.net.wifi.WifiManager
                    @Suppress("DEPRECATION")
                    val connectionInfo = wifiManager.connectionInfo
                    wifiSignal = connectionInfo.rssi
                    wifiLinkSpeed = connectionInfo.linkSpeed
                }
                gateway = legacyGateway(wifiSignal != null)
            }
        } catch (_: Exception) {
        }
        return mapOf(
            "gateway" to gateway,
            "dnsServers" to dnsServers,
            "vpnActive" to vpnActive,
            "wifiSignal" to wifiSignal,
            "wifiFrequency" to wifiFrequency,
            "wifiLinkSpeed" to wifiLinkSpeed,
        )
    }

    private fun legacyDnsServers(): List<String> = try {
        val connectivityManager = getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager
        val method = ConnectivityManager::class.java.getMethod("getLinkProperties", Int::class.javaPrimitiveType)
        val properties = method.invoke(connectivityManager, ConnectivityManager.TYPE_WIFI) as? android.net.LinkProperties
        properties?.dnsServers?.mapNotNull { it.hostAddress } ?: emptyList()
    } catch (_: Exception) {
        emptyList()
    }

    private fun legacyGateway(wifi: Boolean): String? = if (!wifi) null else try {
        val wifiManager = applicationContext.getSystemService(WIFI_SERVICE) as android.net.wifi.WifiManager
        @Suppress("DEPRECATION")
        val address = wifiManager.dhcpInfo.gateway
        if (address == 0) null else String.format(
            "%d.%d.%d.%d",
            address and 0xff,
            address shr 8 and 0xff,
            address shr 16 and 0xff,
            address shr 24 and 0xff,
        )
    } catch (_: Exception) {
        null
    }

    private fun openNetworkSettings() = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startActivity(Intent(Settings.Panel.ACTION_INTERNET_CONNECTIVITY))
        } else {
            startActivity(Intent(Settings.ACTION_WIRELESS_SETTINGS))
        }
        true
    } catch (_: Exception) {
        try {
            startActivity(Intent(Settings.ACTION_WIRELESS_SETTINGS))
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openWifiSettings() = try {
        startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
        true
    } catch (_: Exception) {
        openNetworkSettings()
    }

    private fun openBluetoothSettings() = try {
        startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
        true
    } catch (_: Exception) {
        openSettings()
    }

    private fun getStorageStatus(): Map<String, Any?> = try {
        val stat = android.os.StatFs(android.os.Environment.getDataDirectory().absolutePath)
        mapOf(
            "totalBytes" to stat.totalBytes,
            "freeBytes" to stat.availableBytes,
        )
    } catch (_: Exception) {
        mapOf("totalBytes" to 0L, "freeBytes" to 0L)
    }

    private fun getLauncherMemoryUsage(): Long? = try {
        val activityManager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = activityManager
            .getProcessMemoryInfo(intArrayOf(android.os.Process.myPid()))
            .firstOrNull()
        memoryInfo?.let {
            (it.dalvikPss + it.nativePss + it.otherPss) * 1024L
        }
    } catch (_: Exception) {
        null
    }

    private fun getNextAlarm(): Long? = try {
        val alarm = (getSystemService(ALARM_SERVICE) as AlarmManager).nextAlarmClock
        alarm?.triggerTime
    } catch (_: Exception) {
        null
    }

    private fun getLastLocation(): Map<String, Any?>? {
        if (checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) != PERMISSION_GRANTED) {
            requestPermissions(arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION), 1001)
            return null
        }
        return try {
            val manager = getSystemService(LOCATION_SERVICE) as LocationManager
            var location: android.location.Location? = null
            for (provider in listOf(LocationManager.NETWORK_PROVIDER, LocationManager.GPS_PROVIDER)) {
                location = try {
                    manager.getLastKnownLocation(provider)
                } catch (_: Exception) {
                    null
                }
                if (location != null) break
            }
            location?.let { mapOf("latitude" to it.latitude, "longitude" to it.longitude) }
        } catch (_: Exception) {
            null
        }
    }

    private fun getBluetoothStatus(): Map<String, Any?> = try {
        if (android.os.Build.VERSION.SDK_INT >= 31 &&
            checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) != PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.BLUETOOTH_CONNECT), 1002)
            mapOf("available" to false, "devices" to emptyList<Map<String, Any?>>())
        } else {
            val adapter = (getSystemService(BLUETOOTH_SERVICE) as BluetoothManager).adapter
            if (adapter == null) {
                mapOf("available" to false, "devices" to emptyList<Map<String, Any?>>())
            } else {
                val devices = adapter.bondedDevices.map { device ->
                    val connected = try {
                        device.javaClass.getMethod("isConnected").invoke(device) as Boolean
                    } catch (_: Exception) {
                        false
                    }
                    val battery = try {
                        val level = device.javaClass.getMethod("getBatteryLevel").invoke(device) as Int
                        if (level in 0..100) level else null
                    } catch (_: Exception) {
                        null
                    }
                    mapOf("name" to (device.name ?: device.address), "connected" to connected, "battery" to battery)
                }
                mapOf("available" to true, "devices" to devices)
            }
        }
    } catch (_: Exception) {
        mapOf("available" to false, "devices" to emptyList<Map<String, Any?>>())
    }

    private fun saveBackup(json: String, result: MethodChannel.Result) {
        pendingBackupJson = json
        pendingBackupResult = result
        try {
            startActivityForResult(Intent(ACTION_CREATE_DOCUMENT).apply {
                addCategory(CATEGORY_OPENABLE)
                type = "application/json"
                putExtra(EXTRA_TITLE, "flauncher-backup.json")
            }, 4101)
        } catch (_: Exception) {
            pendingBackupResult = null
            pendingBackupJson = null
            result.success(null)
        }
    }

    private fun readBackup(result: MethodChannel.Result) {
        pendingBackupResult = result
        try {
            startActivityForResult(Intent(ACTION_OPEN_DOCUMENT).apply {
                addCategory(CATEGORY_OPENABLE)
                type = "application/json"
            }, 4102)
        } catch (_: Exception) {
            pendingBackupResult = null
            result.success(null)
        }
    }

    private fun openApplicationManagement() = try {
        startActivity(Intent(Settings.ACTION_MANAGE_APPLICATIONS_SETTINGS))
        true
    } catch (_: Exception) {
        try {
            startActivity(Intent(Settings.ACTION_APPLICATION_SETTINGS))
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun lockScreen() = try {
        val service = FLauncherAccessibilityService.instance
        if (service != null) {
            service.performGlobalAction(AccessibilityService.GLOBAL_ACTION_LOCK_SCREEN)
        } else {
            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
            false
        }
    } catch (_: Exception) {
        false
    }

    private fun ipv4Address(linkProperties: android.net.LinkProperties): String? = linkProperties.linkAddresses
        .asSequence()
        .map { it.address }
        .firstOrNull { it is java.net.Inet4Address && !it.isLoopbackAddress }
        ?.hostAddress

    private fun legacyIpv4Address(): String? = java.net.NetworkInterface.getNetworkInterfaces()
        .toList()
        .asSequence()
        .filter { it.isUp && !it.isLoopback }
        .flatMap { it.inetAddresses.toList().asSequence() }
        .firstOrNull { it is java.net.Inet4Address && !it.isLoopbackAddress }
        ?.hostAddress

    private fun getApplications(): List<Map<String, Serializable?>> {
        val tvActivitiesInfo = queryIntentActivities(false)
        val nonTvActivitiesInfo = queryIntentActivities(true)
                .filter { nonTvActivityInfo -> !tvActivitiesInfo.any { tvActivityInfo -> tvActivityInfo.packageName == nonTvActivityInfo.packageName } }
        return tvActivitiesInfo.map { buildAppMap(it, false) } + nonTvActivitiesInfo.map { buildAppMap(it, true) }
    }

    private fun getApplication(packageName: String): Map<String, Serializable?>? {
        return packageManager.getLeanbackLaunchIntentForPackage(packageName)
            ?.resolveActivityInfo(packageManager, 0)
            ?.let { buildAppMap(it, false) }
            ?: return packageManager.getLaunchIntentForPackage(packageName)
                ?.resolveActivityInfo(packageManager, 0)
                ?.let { buildAppMap(it, true) }
    }

    private fun applicationExists(packageName: String) = try {
        val flag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            PackageManager.MATCH_UNINSTALLED_PACKAGES
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_UNINSTALLED_PACKAGES
        }
        packageManager.getApplicationInfo(packageName, flag)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }

    private fun queryIntentActivities(sideloaded: Boolean) = packageManager
            .queryIntentActivities(Intent(ACTION_MAIN, null)
                    .addCategory(if (sideloaded) CATEGORY_LAUNCHER else CATEGORY_LEANBACK_LAUNCHER), 0)
            .map(ResolveInfo::activityInfo)

    private fun buildAppMap(activityInfo: ActivityInfo, sideloaded: Boolean) = mapOf(
            "name" to activityInfo.loadLabel(packageManager).toString(),
            "packageName" to activityInfo.packageName,
            "banner" to activityInfo.loadBanner(packageManager)?.let(::drawableToByteArray),
            "icon" to activityInfo.loadIcon(packageManager)?.let(::drawableToByteArray),
            "version" to packageManager.getPackageInfo(activityInfo.packageName, 0).versionName,
            "sideloaded" to sideloaded,
    )

    private fun launchApp(packageName: String) = try {
        val intent = packageManager.getLeanbackLaunchIntentForPackage(packageName)
                ?: packageManager.getLaunchIntentForPackage(packageName)
        startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }

    private fun openSettings() = try {
        startActivity(Intent(Settings.ACTION_SETTINGS))
        true
    } catch (e: Exception) {
        false
    }

    private fun openAppInfo(packageName: String) = try {
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null))
                .let(::startActivity)
        true
    } catch (e: Exception) {
        false
    }

    private fun uninstallApp(packageName: String) = try {
        Intent(ACTION_DELETE)
                .setData(Uri.fromParts("package", packageName, null))
                .let(::startActivity)
        true
    } catch (e: Exception) {
        false
    }

    private fun forceStopApp(packageName: String) = try {
        val activityManager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        activityManager.killBackgroundProcesses(packageName)
        true
    } catch (e: Exception) {
        false
    }

    private fun checkForGetContentAvailability() = try {
        val intentActivities = packageManager.queryIntentActivities(Intent(ACTION_GET_CONTENT, null).setTypeAndNormalize("image/*"), 0)
        intentActivities.isNotEmpty()
    } catch (e: Exception) {
        false
    }

    private fun isDefaultLauncher() = try {
        val defaultLauncher = packageManager.resolveActivity(Intent(ACTION_MAIN).addCategory(CATEGORY_HOME), 0)
        defaultLauncher?.activityInfo?.packageName == packageName
    } catch (e: Exception) {
        false
    }

    private fun startAmbientMode() = try {
        Intent(ACTION_MAIN)
            .setClassName("com.android.systemui", "com.android.systemui.Somnambulator")
            .let(::startActivity)
        true
    } catch (e: Exception) {
        false
    }

    private fun getWatchNextPrograms(): List<Map<String, Serializable?>> = try {
        val cursor = contentResolver.query(
            Uri.parse("content://android.media.tv/watch_next_program"),
            arrayOf("title", "package_name", "intent_uri", "poster_art_uri", "duration_millis", "last_playback_position_millis"),
            null, null, null,
        )
        val programs = mutableListOf<Map<String, Serializable?>>()
        cursor?.use {
            while (it.moveToNext()) {
                val duration = it.getDouble(4)
                val lastPosition = it.getDouble(5)
                val progress = if (duration > 0) (lastPosition / duration).coerceIn(0.0, 1.0) else null
                programs.add(mapOf(
                    "title" to (it.getString(0) ?: ""),
                    "packageName" to it.getString(1),
                    "intentUri" to it.getString(2),
                    "progress" to progress,
                    "poster" to it.getString(3)?.let { uri -> uriToByteArray(Uri.parse(uri)) },
                ))
            }
        }
        programs
    } catch (e: Exception) {
        emptyList()
    }

    private fun launchIntentUri(intentUri: String) = try {
        Intent.parseUri(intentUri, URI_INTENT_SCHEME)
            .addFlags(FLAG_ACTIVITY_NEW_TASK)
            .let(::startActivity)
        true
    } catch (e: Exception) {
        false
    }

    private fun uriToByteArray(uri: Uri): ByteArray? = try {
        contentResolver.openInputStream(uri)?.use { input ->
            val bitmap = android.graphics.BitmapFactory.decodeStream(input) ?: return null
            val maxWidth = 960
            val scaled = if (bitmap.width > maxWidth) {
                val height = bitmap.height * maxWidth / bitmap.width
                Bitmap.createScaledBitmap(bitmap, maxWidth, height, true)
            } else {
                bitmap
            }
            val stream = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.JPEG, 80, stream)
            stream.toByteArray()
        }
    } catch (e: Exception) {
        null
    }

    private fun drawableToByteArray(drawable: Drawable): ByteArray? {
        if (drawable.intrinsicWidth <= 0 || drawable.intrinsicHeight <= 0) {
            return null
        }

        fun drawableToBitmap(drawable: Drawable): Bitmap {
            val bitmap = Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            return bitmap
        }

        val bitmap = drawableToBitmap(drawable)
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}
