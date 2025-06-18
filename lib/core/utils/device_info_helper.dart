// lib/core/utils/device_info_helper.dart

import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceInfoHelper {
  static DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Raccoglie informazioni complete del dispositivo per il feedback
  static Future<String> getDeviceInfoJson() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      Map<String, dynamic> deviceInfo = {
        'timestamp': DateTime.now().toIso8601String(),
        'platform': 'Flutter',
        'app_version': packageInfo.version,
        'app_build': packageInfo.buildNumber,
        'package_name': packageInfo.packageName,
      };

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceInfo.addAll({
          'os': 'Android',
          'os_version': androidInfo.version.release,
          'device_model': androidInfo.model,
          'device_brand': androidInfo.brand,
          'device_manufacturer': androidInfo.manufacturer,
          'device_product': androidInfo.product,
          'sdk_int': androidInfo.version.sdkInt,
          'is_physical_device': androidInfo.isPhysicalDevice,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceInfo.addAll({
          'os': 'iOS',
          'os_version': iosInfo.systemVersion,
          'device_model': iosInfo.model,
          'device_name': iosInfo.name,
          'device_system_name': iosInfo.systemName,
          'is_physical_device': iosInfo.isPhysicalDevice,
        });
      } else {
        deviceInfo['os'] = 'Unknown';
      }

      // Aggiungi info debug se in modalità debug
      if (kDebugMode) {
        deviceInfo['debug_mode'] = true;
      }

      return jsonEncode(deviceInfo);
    } catch (e) {
      // In caso di errore, ritorna un JSON minimo
      return jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'platform': 'Flutter',
        'error': 'Failed to collect device info: $e',
      });
    }
  }

  /// Versione semplificata per test rapidi
  static String getBasicDeviceInfo() {
    return jsonEncode({
      'timestamp': DateTime.now().toIso8601String(),
      'platform': 'Flutter',
      'os': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
    });
  }
}