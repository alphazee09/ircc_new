import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class DeviceVerificationService {
  static const String _verifiedKey = 'device_verified';
  
  // Authorized device identifiers
  static const List<String> _authorizedImeis = [
    '351807315694672',  // SIM Slot 1
    '351807315694680',  // SIM Slot 2
  ];
  static const String _authorizedIp = '192.168.100.254';
  
  // Check if device is authorized
  static Future<bool> isDeviceAuthorized() async {
    try {
      // First check if we've already verified this device
      final prefs = await SharedPreferences.getInstance();
      final isVerified = prefs.getBool(_verifiedKey) ?? false;
      
      if (isVerified) {
        return true;
      }
      
      // Check IMEI numbers
      final imeiVerified = await _verifyImei();
      
      // Check IP address
      final ipVerified = await _verifyIpAddress();
      
      // Device is authorized if both IMEI and IP are verified
      final isAuthorized = imeiVerified && ipVerified;
      
      // Save verification status for future app launches
      if (isAuthorized) {
        await prefs.setBool(_verifiedKey, true);
      }
      
      return isAuthorized;
    } catch (e) {
      if (kDebugMode) {
        print('Error during device verification: $e');
      }
      return false;
    }
  }
  
  // Verify IMEI numbers
  static Future<bool> _verifyImei() async {
    if (Platform.isAndroid) {
      try {
        // Request phone state permission is handled in main.dart
        
        // Method channel to get IMEI numbers
        const platform = MethodChannel('ca.ircc/device_info');
        final List<String> imeis = await platform.invokeMethod('getImeiNumbers');
        
        // Check if any of the device IMEIs match authorized IMEIs
        for (final imei in imeis) {
          if (_authorizedImeis.contains(imei)) {
            return true;
          }
        }
        
        return false;
      } catch (e) {
        if (kDebugMode) {
          print('Error getting IMEI: $e');
        }
        return false;
      }
    } else {
      // For non-Android devices, we can't check IMEI
      return false;
    }
  }
  
  // Verify IP address - workaround without network_info_plus
  static Future<bool> _verifyIpAddress() async {
    try {
      // Workaround: Use a custom method to get IP address since network_info_plus is unavailable
      final ip = await _getDeviceIp();
      return ip == _authorizedIp;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting IP address: $e');
      }
      return false;
    }
  }
  
  // Workaround method to get device IP address without using the missing package
  static Future<String?> _getDeviceIp() async {
    try {
      // Try to use platform channel to get IP address
      const platform = MethodChannel('ca.ircc/network_info');
      final String? ip = await platform.invokeMethod('getWifiIP');
      return ip;
    } catch (e) {
      if (kDebugMode) {
        print('Error in _getDeviceIp: $e');
      }
      // Return a mock IP for testing purposes
      return "192.168.1.1";
    }
  }
  
  // For testing purposes - reset verification status
  static Future<void> resetVerificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_verifiedKey);
  }
}
