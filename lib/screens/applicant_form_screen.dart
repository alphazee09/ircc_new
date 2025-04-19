// ignore_for_file: unnecessary_import, unused_field, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/application_data.dart';
import '../utils/storage_service.dart';
import 'invitation_form_screen.dart';

class ApplicantFormScreen extends StatefulWidget {
  const ApplicantFormScreen({super.key});

  @override
  State<ApplicantFormScreen> createState() => _ApplicantFormScreenState();
}

class _ApplicantFormScreenState extends State<ApplicantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passportNoController = TextEditingController();
  final TextEditingController _passportExpiryController = TextEditingController();
  final TextEditingController _currentResidentCountryController = TextEditingController();
  
  String _selectedSex = 'Male';
  String _selectedNationality = 'Canadian';
  final String _selectedStatus = 'Citizen';
  File? _selectedImage;
  final bool _isLoading = false;
  bool _isSubmitting = false;
  
  final List<String> _sexOptions = ['Male', 'Female', 'Other'];
  final List<String> _nationalityOptions = [
    'Canadian', 'American', 'British', 'Australian', 'Indian', 
    'Chinese', 'French', 'German', 'Japanese', 'Other'
  ];
  final List<String> _statusOptions = [
    'Citizen', 'Permanent Resident', 'Temporary Resident', 
    'Student', 'Worker', 'Visitor', 'Refugee', 'Other'
  ];
  
  @override
  void dispose() {
    _nameController.dispose();
    _passportNoController.dispose();
    _passportExpiryController.dispose();
    _currentResidentCountryController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    try {
      // Request permissions first
      await StorageService.requestStoragePermissions();
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = now.add(const Duration(days: 365));
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    
    if (picked != null) {
      setState(() {
        _passportExpiryController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }
  
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an applicant photo'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        _isSubmitting = true;
      });
      
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving applicant information...'),
                ],
              ),
            );
          },
        );
        
        // Generate application number
        final applicationNo = await StorageService.generateApplicationNo();
        
        // Save image
        final imagePath = await StorageService.saveImage(_selectedImage!);
        
        // Create application data
        final applicationData = ApplicationData(
          applicationNo: applicationNo,
          applicantName: _nameController.text,
          sex: _selectedSex,
          nationality: _selectedNationality,
          passportNo: _passportNoController.text,
          passportExpiryDate: _passportExpiryController.text,
          currentResidentCountry: _currentResidentCountryController.text,
          status: _selectedStatus,
          photoPath: imagePath,
          applicationDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          applicationStatus: 'IN PROGRESS',
        );
        
        // Save application data
        final result = await StorageService.saveApplicationData(applicationData);
        
        // Debug: Print all applications
        await StorageService.debugPrintAllApplications();
        
        // Close loading dialog
        Navigator.pop(context);
        
        if (result) {
          // Show success dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Step 1 Completed'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Applicant information saved successfully!',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Application Number: $applicationNo',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to invitation form screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvitationFormScreen(
                            applicationData: applicationData,
                          ),
                        ),
                      );
                    },
                    child: const Text('Continue to Step 2'),
                  ),
                ],
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error saving application data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Close loading dialog if open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 1: Applicant Information'),
        centerTitle: true,
        actions: [
          // Debug button
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              StorageService.showDebugDialog(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                const LinearProgressIndicator(
                  value: 0.33, // 1/3 steps
                  backgroundColor: Colors.grey,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step 1 of 3',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '33%',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Applicant photo
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 150,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Upload Photo',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Applicant Photo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap to select',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Applicant name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter applicant full name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter applicant name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Sex
                DropdownButtonFormField<String>(
                  value: _selectedSex,
                  decoration: const InputDecoration(
                    labelText: 'Sex',
                    prefixIcon: Icon(Icons.people),
                    border: OutlineInputBorder(),
                  ),
                  items: _sexOptions.map((String sex) {
                    return DropdownMenuItem<String>(
                      value: sex,
                      child: Text(sex),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedSex = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Nationality
                DropdownButtonFormField<String>(
                  value: _selectedNationality,
                  decoration: const InputDecoration(
                    labelText: 'Nationality',
                    prefixIcon: Icon(Icons.flag),
                    border: OutlineInputBorder(),
                  ),
                  items: _nationalityOptions.map((String nationality) {
                    return DropdownMenuItem<String>(
                      value: nationality,
                      child: Text(nationality),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedNationality = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Passport number
                TextFormField(
                  controller: _passportNoController,
                  decoration: const InputDecoration(
                    labelText: 'Passport Number',
                    hintText: 'Enter passport number',
                    prefixIcon: Icon(Icons.book),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter passport number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Passport expiry date
                TextFormField(
                  controller: _passportExpiryController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: const InputDecoration(
                    labelText: 'Passport Expiry Date',
                    hintText: 'Select expiry date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select passport expiry date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Current resident
                TextFormField(
                  controller: _currentResidentCountryController,
                  decoration: const InputDecoration(
                    labelText: 'Current Resident Country',
                    hintText: 'Enter current resident country',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter current resident country';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Save & Continue',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// AppTheme class for use within this file
class AppTheme {
  static const Color primaryColor = Color(0xFFE31937); // Canadian Red
  static const Color accentColor = Color(0xFF002868); // Dark Blue
}