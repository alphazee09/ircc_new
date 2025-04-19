// ignore_for_file: unused_import, unnecessary_import, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../models/application_data.dart';
import '../../utils/storage_service.dart';
import './home_screen.dart';

class StatusCheckScreen extends StatefulWidget {
  const StatusCheckScreen({super.key});

  @override
  State<StatusCheckScreen> createState() => _StatusCheckScreenState();
}

class _StatusCheckScreenState extends State<StatusCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _applicationNoController = TextEditingController();
  
  bool _isLoading = false;
  bool _isGeneratingPdf = false;
  bool _isGeneratingReceipt = false;
  ApplicationData? _applicationData;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    // Request storage permissions when screen loads
    _requestPermissions();
  }
  
  Future<void> _requestPermissions() async {
    await StorageService.requestStoragePermissions();
  }
  
  @override
  void dispose() {
    _applicationNoController.dispose();
    super.dispose();
  }
  
  // Helper method to build PDF rows
  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }
  
  Future<void> _checkStatus() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _applicationData = null;
        _errorMessage = null;
      });
      
      try {
        // Format application number to remove any whitespace
        final applicationNo = _applicationNoController.text.trim();
        
        // Debug: Print all applications before searching
        await StorageService.debugPrintAllApplications();
        
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 3));
        
        // Get application data
        final applicationData = await StorageService.getApplicationDataByNumber(
          applicationNo,
        );
        
        if (applicationData != null) {
          setState(() {
            _applicationData = applicationData;
            _isLoading = false;
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application found successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Application not found. Please check the application number and try again.';
            _isLoading = false;
          });
          
          // Show more detailed error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Application "$applicationNo" not found in the system.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching for application: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _generatePdf() async {
    if (_applicationData == null) return;
    
    setState(() {
      _isGeneratingPdf = true;
    });
    
    try {
      // Request permissions first
      await StorageService.requestStoragePermissions();
      
      final pdf = pw.Document();
      
      // Get applicant photo
      pw.MemoryImage? photoImage;
      if (_applicationData!.photoPath != null) {
        final photoFile = await StorageService.getImage(_applicationData!.photoPath);
        if (photoFile != null) {
          final photoBytes = await photoFile.readAsBytes();
          photoImage = pw.MemoryImage(photoBytes);
        }
      }
      
      // Add page with application details
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with logo
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'IMMIGRATION, REFUGEES AND',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'CITIZENSHIP CANADA',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Application Status: ${_applicationData!.applicationStatus}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red,
                          ),
                        ),
                      ],
                    ),
                    photoImage != null
                        ? pw.Container(
                            width: 100,
                            height: 120,
                            child: pw.Image(photoImage),
                          )
                        : pw.Container(
                            width: 100,
                            height: 120,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(),
                            ),
                            child: pw.Center(
                              child: pw.Text('No Photo'),
                            ),
                          ),
                  ],
                ),
                pw.SizedBox(height: 20),
                
                // Application details
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'APPLICATION DETAILS',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Divider(),
                      _buildPdfRow('Application Number', _applicationData!.applicationNo ?? 'N/A'),
                      _buildPdfRow('Application Date', _applicationData!.applicationDate ?? 'N/A'),
                      _buildPdfRow('Status', _applicationData!.applicationStatus ?? 'N/A'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Applicant details
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'APPLICANT INFORMATION',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Divider(),
                      _buildPdfRow('Name', _applicationData!.applicantName ?? 'N/A'),
                      _buildPdfRow('Sex', _applicationData!.sex ?? 'N/A'),
                      _buildPdfRow('Nationality', _applicationData!.nationality ?? 'N/A'),
                      _buildPdfRow('Passport No', _applicationData!.passportNo ?? 'N/A'),
                      _buildPdfRow('Passport Expiry', _applicationData!.passportExpiryDate ?? 'N/A'),
                      _buildPdfRow('Current Resident Country', _applicationData!.currentResidentCountry ?? 'N/A'),
                      _buildPdfRow('Status', _applicationData!.status ?? 'N/A'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Invitation details
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INVITATION INFORMATION',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Divider(),
                      _buildPdfRow('Owner Name', _applicationData!.invitationOwnerName ?? 'N/A'),
                      _buildPdfRow('ID Card', _applicationData!.idCard ?? 'N/A'),
                      _buildPdfRow('Job Title', _applicationData!.jobTitle ?? 'N/A'),
                      _buildPdfRow('Address', _applicationData!.address ?? 'N/A'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Payment details
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'PAYMENT INFORMATION',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'PAID',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green,
                            ),
                          ),
                        ],
                      ),
                      pw.Divider(),
                      _buildPdfRow('Receipt Number', _applicationData!.receiptNumber ?? 'N/A'),
                      _buildPdfRow('Transaction ID', _applicationData!.transactionId ?? 'N/A'),
                      _buildPdfRow('Payment Method', _applicationData!.paymentMethod ?? 'N/A'),
                      _buildPdfRow('Payment Date', _applicationData!.paymentDate ?? 'N/A'),
                      _buildPdfRow('Amount Paid', 'CAD ${_applicationData!.paidAmount ?? 'N/A'}'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Footer
                pw.Center(
                  child: pw.Text(
                    'This document is for information purposes only.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      // Save PDF
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/application_${_applicationData!.applicationNo}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      setState(() {
        _isGeneratingPdf = false;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGeneratingPdf = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _generateReceiptPdf() async {
    if (_applicationData == null) return;
    
    setState(() {
      _isGeneratingReceipt = true;
    });
    
    try {
      // Request permissions first
      await StorageService.requestStoragePermissions();
      
      final pdf = pw.Document();
      
      // Add page with receipt details
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with logo
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'IMMIGRATION, REFUGEES AND',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'CITIZENSHIP CANADA',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      'RECEIPT',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                
                // Receipt details
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Center(
                        child: pw.Text(
                          'PAYMENT CONFIRMATION',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Center(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.green,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
                          ),
                          child: pw.Text(
                            'PAID',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      _buildPdfRow('Receipt Number', _applicationData!.receiptNumber ?? 'N/A'),
                      _buildPdfRow('Transaction ID', _applicationData!.transactionId ?? 'N/A'),
                      _buildPdfRow('Application Number', _applicationData!.applicationNo ?? 'N/A'),
                      _buildPdfRow('Applicant Name', _applicationData!.applicantName ?? 'N/A'),
                      _buildPdfRow('Payment Method', _applicationData!.paymentMethod ?? 'N/A'),
                      _buildPdfRow('Payment Date', _applicationData!.paymentDate ?? 'N/A'),
                      pw.SizedBox(height: 10),
                      pw.Divider(thickness: 2),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Amount Paid:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          pw.Text(
                            'CAD ${_applicationData!.paidAmount ?? 'N/A'}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Footer
                pw.Center(
                  child: pw.Text(
                    'This document is a proof of payment for immigration services.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Immigration, Refugees and Citizenship Canada',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      // Save PDF
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/receipt_${_applicationData!.applicationNo}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      setState(() {
        _isGeneratingReceipt = false;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt PDF saved to: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGeneratingReceipt = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating receipt PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Status Check'),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Application number input form
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _applicationNoController,
                  decoration: const InputDecoration(
                    labelText: 'Application Number',
                    hintText: 'Enter your application number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter application number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Check status button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkStatus,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Check Status', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
              
              // Display error message if any
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Display application details if available
              if (_applicationData != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Application status card
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with status
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Application Status',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _applicationData!.applicationStatus == 'COMPLETED'
                                            ? Colors.green
                                            : _applicationData!.applicationStatus == 'IN PROGRESS'
                                                ? Colors.orange
                                                : Colors.red,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _applicationData!.applicationStatus ?? 'UNKNOWN',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                // Application details
                                _buildInfoRow('Application No', _applicationData!.applicationNo ?? 'N/A'),
                                _buildInfoRow('Applicant Name', _applicationData!.applicantName ?? 'N/A'),
                                _buildInfoRow('Nationality', _applicationData!.nationality ?? 'N/A'),
                                _buildInfoRow('Application Date', _applicationData!.applicationDate ?? 'N/A'),
                                
                                // Payment status if available
                                if (_applicationData!.paidAmount != null)
                                  _buildInfoRow('Payment', 'CAD ${_applicationData!.paidAmount}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Action buttons for PDF generation
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isGeneratingPdf ? null : _generatePdf,
                                icon: _isGeneratingPdf
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.description),
                                label: const Text('Generate Application Details'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Receipt button (only enabled if payment is made)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (_isGeneratingReceipt || _applicationData!.paidAmount == null)
                                    ? null
                                    : _generateReceiptPdf,
                                icon: _isGeneratingReceipt
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.receipt),
                                label: const Text('Generate Payment Receipt'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper widget for displaying information rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}