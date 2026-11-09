# FLauncher (fork)

FLauncher is an open-source alternative launcher for Android TV, built with [Flutter](https://flutter.dev).

The project is still at an early development stage and may be unstable. It currently lacks testing on real devices and has only been tested on Chromecast with Google TV.

## Origin
This repository is a fork of [FLauncher](https://gitlab.com/etienn01/flauncher) by Étienne Fesser. All credit for the original project goes to its author. This fork adds a glass-style UI redesign, a TV design token system, and a bundled local wallpaper gallery.

## Features
- [x] No ads
- [x] Customizable categories
- [x] Manually reorder apps within categories
- [x] Wallpaper support (Unsplash, gradients, bundled local wallpapers, online gallery from git repo, custom image)
- [x] Open "Android Settings"
- [x] Open "App info"
- [x] Uninstall app
- [x] Clock
- [x] Switch between row and grid for categories
- [x] Support for non-TV (sideloaded) apps
- [x] Navigation sound feedback
- [x] Force stop app
- [x] Favorites row
- [x] Contextual hero highlighting the focused app
- [x] "Continue watching" hero content from the Android TV Watch Next channel, with recent-app fallback
- [x] Liquid glass UI: specular highlights and focused glow on cards
- [x] Date below the clock
- [x] Network connection status and local IP address in the top bar

## Feature roadmap

Completed features are marked with `[x]` only after they are implemented and verified. Planned features remain marked with `[ ]`.

### Network diagnostics in Settings
- [x] Network diagnostics screen with an on-demand "Start test" action
- [x] Download and upload speed in Mbps
- [x] Latency (ping): minimum, average, and maximum
- [x] Packet loss percentage
- [x] Jitter and a simple connection-stability summary
- [x] Last test date and server used
- [x] Gateway and DNS server information
- [x] Wi-Fi signal strength, frequency, and link speed
- [x] VPN status
- [x] Shortcut to Android network settings

Network speed tests run only when requested by the user, since they consume data and can affect playback or other network activity. Tests use Cloudflare's HTTPS endpoints (approximately 8 MB downloaded and 1 MB uploaded); latency, packet loss, and jitter are HTTPS request estimates, not ICMP ping measurements. Gateway, DNS, VPN, and Wi-Fi details depend on what the Android version and device expose. Wi-Fi metrics show "Not available" on Ethernet and unsupported devices.

### Remote control and navigation
- [x] Remote-button mapping: detect a button press and assign an app
- [x] Netflix and YouTube button presets
- [x] Reliable D-pad access to every top-bar control, including Settings

Android does not allow every app to intercept every remote-control button globally. Buttons that FLauncher can receive may be mapped directly; global remapping of system-reserved buttons can require an accessibility service, device-specific permissions, ADB, or root access.

### Other planned features
- [x] Remote-friendly quick settings panel: Wi-Fi, Bluetooth, network settings, sleep, and screensaver
- [x] Top-bar customization: show or hide the date, network status, and local IP address
- [x] Storage space indicator, low-space warning, and app-management shortcut
- [x] Connected Bluetooth devices and controller battery levels when supported by Android
- [x] Global app search with D-pad navigation
- [x] Recent apps row with an option to clear history
- [x] Backup and restore for favorites, categories, ordering, and preferences
- [x] Optional weather information
- [x] Optional next-alarm indicator
- [x] Customizable screensaver using the available wallpapers

Free space is read from the device data partition. The top bar shows a storage warning when less than 10% or less than 1 GiB remains. Opening that warning, or the storage row in quick settings, opens Android's application management screen. Search filters installed apps and opens the selected one. Recent apps appear in their own row after they have been opened. Quick settings lists connected Bluetooth devices and a battery percentage when Android exposes one. Settings can export or import a JSON backup of categories, favorites, order, and preferences through the system file picker. Weather stays off until enabled and uses the last known location; the next alarm is shown by default. The screensaver can keep the current wallpaper or use one of the built-in gradients.

## Screenshots
|  |  |  |
|--|--|--|
| ![](screenshots/Screenshot_1624378896.png) | ![](screenshots/Screenshot_1624378921.png) | ![](screenshots/Screenshot_1624378938.png) |

## Set FLauncher as default launcher

### Method 1: remap the Home button
This is the "safer" and easiest way. Use [Button Mapper](https://play.google.com/store/apps/details?id=flar2.homebutton) to remap the Home button of the remote to launch FLauncher.

### Method 2: disable the default launcher
**:warning: Disclaimer :warning:**

**You are doing this at your own risk, and you'll be responsible in any case of malfunction on your device.**

The following commands have been tested on Chromecast with Google TV only. This may be different on other devices.

Once the default launcher is disabled, press the Home button on the remote, and you'll be prompted by the system to choose which app to set as default.

#### Disable default launcher
```shell
# Disable com.google.android.apps.tv.launcherx which is the default launcher on CCwGTV
$ adb shell pm disable-user --user 0 com.google.android.apps.tv.launcherx
# com.google.android.tungsten.setupwraith will then be used as a 'fallback' and will automatically
# re-enable the default launcher, so disable it as well
$ adb shell pm disable-user --user 0 com.google.android.tungsten.setupwraith
```

#### Re-enable default launcher
```shell
$ adb shell pm enable com.google.android.apps.tv.launcherx
$ adb shell pm enable com.google.android.tungsten.setupwraith
```

#### Known issues
On Chromecast with Google TV (maybe others), the "YouTube" remote button will stop working if the default launcher is disabled. As a workaround, you can use [Button Mapper](https://play.google.com/store/apps/details?id=flar2.homebutton) to remap it correctly.

## Wallpaper
Because Android's `WallpaperManager` is not available on some Android TV devices, FLauncher implements its own wallpaper management method.

Please note that changing wallpaper requires a file explorer to be installed on the device in order to pick a file.
