// ignore_for_file: unused_field, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/application_data.dart';
import '../../utils/storage_service.dart';
import 'home_screen.dart';
import 'status_check_screen.dart';

class PaymentScreen extends StatefulWidget {
  final ApplicationData applicationData;

  const PaymentScreen({
    super.key,
    required this.applicationData,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final bool _isLoading = false;
  bool _isSubmitting = false;
  String _selectedPaymentMethod = 'Credit Card';
  final List<String> _paymentMethods = StorageService.getPaymentMethods();

  @override
  void initState() {
    super.initState();
    // Set default amount
    _amountController.text = '150.00';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isSubmitting = true;
      });
      
      try {
        // Format amount to ensure it has two decimal places
        final amountValue = double.tryParse(_amountController.text) ?? 0.0;
        final formattedAmount = amountValue.toStringAsFixed(2);
        
        // Update the controller with formatted value
        _amountController.text = formattedAmount;
        
        // Generate application number if not already set
        if (widget.applicationData.applicationNo == null || widget.applicationData.applicationNo!.isEmpty) {
          final applicationNo = await StorageService.generateApplicationNo();
          widget.applicationData.applicationNo = applicationNo;
        }
        
        // Set application date if not already set
        if (widget.applicationData.applicationDate == null || widget.applicationData.applicationDate!.isEmpty) {
          widget.applicationData.applicationDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        }
        
        // Generate payment details
        widget.applicationData.receiptNumber = StorageService.generateReceiptNumber();
        widget.applicationData.transactionId = StorageService.generateTransactionId();
        widget.applicationData.paymentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        widget.applicationData.paymentMethod = _selectedPaymentMethod;
        widget.applicationData.paidAmount = formattedAmount;
        
        // Update application status
        widget.applicationData.applicationStatus = 'COMPLETED';
        
        // Save application data
        final saveResult = await StorageService.saveApplicationData(widget.applicationData);
        if (kDebugMode) {
          print('Final save result: $saveResult');
        }
        
        if (!saveResult) {
          throw Exception('Failed to save application data');
        }
        
        // Show processing dialog
        _showProcessingDialog();
        
        // Simulate processing delay
        await Future.delayed(const Duration(seconds: 3));
        
        // Show success dialog
        if (mounted) {
          Navigator.pop(context); // Dismiss processing dialog
          
          setState(() {
            _isSubmitting = false;
          });
          
          _showSuccessDialog(widget.applicationData.applicationNo!);
        }
      } catch (e) {
        // Close processing dialog if it's showing
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
  
  void _showProcessingDialog() {
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
              'Processing Payment',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we process your application...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String applicationNo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Application Submitted'),
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
              'Your application has been submitted successfully!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Application Number: ${widget.applicationData.applicationNo}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Receipt Number: ${widget.applicationData.receiptNumber}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please save these numbers to check your application status.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatusCheckScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text('Check Status'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                ),
                (route) => false,
              );
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 3: Payment'),
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
                  value: 1.0,
                  backgroundColor: Colors.grey,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                
                // Payment information
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
                        'Payment Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Please enter the amount you have paid for this application.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Amount field
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Paid Amount (CAD)',
                          prefixIcon: Icon(Icons.attach_money),
                          hintText: 'e.g., 150.00',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the paid amount';
                          }
                          
                          // Check if it's a valid number
                          final amountValue = double.tryParse(value);
                          if (amountValue == null) {
                            return 'Please enter a valid amount';
                          }
                          
                          // Ensure amount is positive
                          if (amountValue <= 0) {
                            return 'Amount must be greater than zero';
                          }
                          
                          return null;
                        },
                        // Format amount to two decimal places when focus is lost
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            final amountValue = double.tryParse(value);
                            if (amountValue != null) {
                              // Only format when focus is lost to avoid cursor position issues
                              setState(() {});
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Payment method dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon: Icon(Icons.payment),
                        ),
                        value: _selectedPaymentMethod,
                        items: _paymentMethods.map((String method) {
                          return DropdownMenuItem<String>(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedPaymentMethod = newValue;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a payment method';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Payment details preview
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Preview',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Application Fee:'),
                                Text('CAD ${_amountController.text.isEmpty ? "0.00" : _amountController.text}'),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Amount:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'CAD ${_amountController.text.isEmpty ? "0.00" : _amountController.text}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Payment Method:'),
                                Text(_selectedPaymentMethod),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Payment Date:'),
                                Text(DateFormat('yyyy-MM-dd').format(DateTime.now())),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitApplication,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Submit Application',
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
