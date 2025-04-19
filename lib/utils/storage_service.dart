// ignore_for_file: unused_import, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/application_data.dart';

class StorageService {
  static const String _applicationDataKey = 'application_data_list';
  static const String _applicationNoKey = 'application_no';

  // Request storage permissions
  static Future<bool> requestStoragePermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.photos,
    ].request();
    
    return statuses[Permission.storage]!.isGranted && 
           statuses[Permission.photos]!.isGranted;
  }

  // Save application data
  static Future<bool> saveApplicationData(ApplicationData data) async {
    try {
      // Request permissions first
      await requestStoragePermissions();
      
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing applications list or create new one
      List<String> applicationsList = prefs.getStringList(_applicationDataKey) ?? [];
      
      // Convert new application to JSON
      final jsonData = json.encode(data.toJson());
      
      // Check if application already exists
      bool applicationExists = false;
      List<String> updatedList = [];
      
      for (String appJson in applicationsList) {
        final app = ApplicationData.fromJson(json.decode(appJson));
        if (app.applicationNo == data.applicationNo) {
          // Replace existing application
          updatedList.add(jsonData);
          applicationExists = true;
        } else {
          updatedList.add(appJson);
        }
      }
      
      // If application doesn't exist, add it
      if (!applicationExists) {
        updatedList.add(jsonData);
      }
      
      // Save updated list
      final result = await prefs.setStringList(_applicationDataKey, updatedList);
      
      // Debug confirmation
      if (kDebugMode) {
        print('Saved application data: $jsonData');
      }
      if (kDebugMode) {
        print('Current applications count: ${updatedList.length}');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving application data: $e');
      }
      return false;
    }
  }

  // Get all applications
  static Future<List<ApplicationData>> getAllApplications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonDataList = prefs.getStringList(_applicationDataKey) ?? [];
      
      List<ApplicationData> applications = [];
      for (String jsonData in jsonDataList) {
        applications.add(ApplicationData.fromJson(json.decode(jsonData)));
      }
      
      if (kDebugMode) {
        print('Retrieved ${applications.length} applications');
      }
      return applications;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving applications: $e');
      }
      return [];
    }
  }
  
  // Get application data by application number
  static Future<ApplicationData?> getApplicationDataByNumber(String applicationNo) async {
    try {
      // Request permissions first
      await requestStoragePermissions();
      
      final prefs = await SharedPreferences.getInstance();
      final jsonDataList = prefs.getStringList(_applicationDataKey) ?? [];
      
      // Print debug info
      if (kDebugMode) {
        print('Searching for application: $applicationNo');
      }
      if (kDebugMode) {
        print('Total applications stored: ${jsonDataList.length}');
      }
      
      for (String jsonData in jsonDataList) {
        final data = ApplicationData.fromJson(json.decode(jsonData));
        
        // Check if application number matches
        if (data.applicationNo == applicationNo) {
          if (kDebugMode) {
            print('Application found: ${data.applicationNo}');
          }
          return data;
        }
      }
      
      if (kDebugMode) {
        print('Application not found: $applicationNo');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving application data: $e');
      }
      return null;
    }
  }

  // Generate and save application number
  static Future<String> generateApplicationNo() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_applicationNoKey) ?? 0;
    final newCount = currentCount + 1;
    
    await prefs.setInt(_applicationNoKey, newCount);
    
    // Format: CA20250418001 (without hyphens)
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final appNo = 'CA$dateStr${newCount.toString().padLeft(3, '0')}';
    
    return appNo;
  }

  // Generate receipt number
  static String generateReceiptNumber() {
    final random = Random();
    final receiptNumber = 'R${random.nextInt(900000) + 100000}';
    return receiptNumber;
  }

  // Generate transaction ID
  static String generateTransactionId() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final transactionId = List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
    return 'TXN$transactionId';
  }

  // Get payment methods
  static List<String> getPaymentMethods() {
    return ['Credit Card', 'Debit Card', 'Bank Transfer', 'PayPal'];
  }

  // Save image to local storage
  static Future<String> saveImage(File imageFile) async {
    try {
      // Request permissions first
      await requestStoragePermissions();
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'applicant_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await imageFile.copy('${directory.path}/$fileName');
      
      // Print debug info
      if (kDebugMode) {
        print('Image saved to: ${savedImage.path}');
      }
      
      return savedImage.path;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving image: $e');
      }
      rethrow;
    }
  }

  // Get image from path
  static Future<File?> getImage(String? path) async {
    if (path == null || path.isEmpty) {
      print('Image path is null or empty');
      return null;
    }
    
    try {
      // Request permissions first
      await requestStoragePermissions();
      
      final file = File(path);
      if (await file.exists()) {
        print('Image found at: $path');
        return file;
      }
      
      print('Image not found at: $path');
      
      // Try to search in application documents directory as fallback
      try {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = path.split('/').last;
        final alternativePath = '${directory.path}/$fileName';
        final alternativeFile = File(alternativePath);
        
        if (await alternativeFile.exists()) {
          print('Image found at alternative path: $alternativePath');
          return alternativeFile;
        }
      } catch (e) {
        print('Error searching for alternative image path: $e');
      }
      
      return null;
    } catch (e) {
      print('Error retrieving image: $e');
      return null;
    }
  }
  
  // Debug: Print all stored applications with detailed information
  static Future<void> debugPrintAllApplications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonDataList = prefs.getStringList(_applicationDataKey) ?? [];
      
      print('===== DEBUG: ALL STORED APPLICATIONS =====');
      print('Total applications: ${jsonDataList.length}');
      
      for (int i = 0; i < jsonDataList.length; i++) {
        try {
          final app = ApplicationData.fromJson(json.decode(jsonDataList[i]));
          print('Application ${i+1}: ${app.applicationNo} - ${app.applicantName}');
          print('  Status: ${app.applicationStatus}');
          print('  Created: ${app.applicationDate}');
          print('  Image path exists: ${app.photoPath != null ? await File(app.photoPath!).exists() : false}');
        } catch (e) {
          print('Error parsing application $i: $e');
          print('Raw JSON: ${jsonDataList[i]}');
        }
      }
      
      print('=========================================');
    } catch (e) {
      print('Error in debug print: $e');
    }
  }
  
  // Clear all application data (for testing)
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('All application data cleared');
    } catch (e) {
      print('Error clearing data: $e');
    }
  }
  
  // Show debug dialog with storage information
  static Future<void> showDebugDialog(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonDataList = prefs.getStringList(_applicationDataKey) ?? [];
      
      String debugInfo = 'Total applications: ${jsonDataList.length}\n\n';
      
      for (int i = 0; i < jsonDataList.length; i++) {
        final app = ApplicationData.fromJson(json.decode(jsonDataList[i]));
        debugInfo += 'App ${i+1}: ${app.applicationNo} - ${app.applicantName}\n';
      }
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Storage Debug Info'),
          content: SingleChildScrollView(
            child: Text(debugInfo),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                await clearAllData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              },
              child: const Text('Clear All Data'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing debug dialog: $e');
    }
  }
}
