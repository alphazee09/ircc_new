// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import '../../models/application_data.dart';
import '../../utils/storage_service.dart';
import 'payment_screen.dart';

class InvitationFormScreen extends StatefulWidget {
  final ApplicationData applicationData;

  const InvitationFormScreen({
    super.key,
    required this.applicationData,
  });

  @override
  State<InvitationFormScreen> createState() => _InvitationFormScreenState();
}

class _InvitationFormScreenState extends State<InvitationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    
    // Fill in existing values if available
    _ownerNameController.text = widget.applicationData.invitationOwnerName ?? '';
    _idCardController.text = widget.applicationData.idCard ?? '';
    _jobTitleController.text = widget.applicationData.jobTitle ?? '';
    _addressController.text = widget.applicationData.address ?? '';
  }
  
  @override
  void dispose() {
    _ownerNameController.dispose();
    _idCardController.dispose();
    _jobTitleController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isSubmitting = true;
      });
      
      try {
        // Set invitation data
        widget.applicationData.invitationOwnerName = _ownerNameController.text.trim();
        widget.applicationData.idCard = _idCardController.text.trim();
        widget.applicationData.jobTitle = _jobTitleController.text.trim();
        widget.applicationData.address = _addressController.text.trim();
        
        // Save intermediate data
        final saveResult = await StorageService.saveApplicationData(widget.applicationData);
        
        if (!saveResult) {
          throw Exception('Failed to save invitation data');
        }
        
        // Show success dialog with loading animation
        _showSuccessDialog();
        
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 2));
        
        // Navigate to next screen
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
          
          // Close success dialog before navigating
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                applicationData: widget.applicationData,
              ),
            ),
          );
        }
      } catch (e) {
        // Close success dialog if it's showing
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        setState(() {
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Step 2 Completed',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Invitation information saved successfully!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 2: Invitation Details'),
        centerTitle: true,
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
                  value: 0.66,
                  backgroundColor: Colors.grey,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                
                // Invitation information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invitation Owner Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Owner name field
                      TextFormField(
                        controller: _ownerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Owner Name',
                          prefixIcon: Icon(Icons.person),
                          hintText: 'Enter invitation owner\'s full name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter owner\'s name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // ID card field
                      TextFormField(
                        controller: _idCardController,
                        decoration: const InputDecoration(
                          labelText: 'ID Card',
                          prefixIcon: Icon(Icons.credit_card),
                          hintText: 'Enter ID card number',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter ID card number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Job title field
                      TextFormField(
                        controller: _jobTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Job Title',
                          prefixIcon: Icon(Icons.work),
                          hintText: 'Enter job title',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter job title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Address field
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.location_on),
                          hintText: 'Enter full address',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Next button
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
                            'Next',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Back button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.accentColor),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppTheme {
  static const Color primaryColor = Color(0xFFE31937); // Canadian red
  static const Color accentColor = Color(0xFF0D1D42); // Dark blue
}
