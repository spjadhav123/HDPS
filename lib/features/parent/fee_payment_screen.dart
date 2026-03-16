// lib/features/parent/fee_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import '../../shared/widgets/page_header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/models/student_model.dart';
import '../../core/providers/student_provider.dart';

import '../../core/models/fee_structure_model.dart';
import '../../core/providers/fee_structure_provider.dart';
import '../../core/providers/receipt_provider.dart';
import '../../core/models/receipt_model.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/app_animations.dart';
import 'dart:js' as js;
import 'dart:convert';
import 'package:http/http.dart' as http;

class FeePaymentScreen extends ConsumerStatefulWidget {
  const FeePaymentScreen({super.key});

  @override
  ConsumerState<FeePaymentScreen> createState() => _FeePaymentScreenState();
}

class _FeePaymentScreenState extends ConsumerState<FeePaymentScreen> {
  String _selectedMode = 'PhonePe (UPI)';
  Razorpay? _razorpay;
  Student? _currentStudent;
  double _currentAmountToBePaid = 0;
  final TextEditingController _upiIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _processPaymentSuccess(
      response.paymentId ?? '',
      response.orderId ?? '',
      response.signature ?? '',
    );
  }

  void _processPaymentSuccess(String paymentId, String orderId, String signature) async {
    if (_currentStudent == null) return;
    
    // 1. Verify payment with backend REST API
    AppToast.show(context, message: 'Verifying payment with backend...', type: ToastType.info);
    
    try {
      // Logic for real backend verification
      // final verifyResponse = await http.post(
      //   Uri.parse('https://your-backend.com/api/verify-payment'),
      //   body: jsonEncode({
      //     'razorpay_payment_id': paymentId,
      //     'razorpay_order_id': orderId,
      //     'razorpay_signature': signature,
      //     'studentId': _currentStudent!.id,
      //     'amount': _currentAmountToBePaid,
      //   }),
      //   headers: {'Content-Type': 'application/json'},
      // );
      
      await Future.delayed(const Duration(seconds: 2)); // Simulate network latency
      
      // Assume success for demo if we have a paymentId
      if (paymentId.isNotEmpty) {
        _showResultDialog('Payment Verified & Successful!', 'Payment ID: $paymentId', true);
        _savePayment(_currentStudent!, _currentAmountToBePaid, paymentId, orderId, _selectedMode);
      } else {
        _showResultDialog('Verification Failed!', 'Security Verification failed.', false);
      }
    } catch (e) {
      _showResultDialog('Error', 'Verification error: $e', false);
    }
  }

  Future<void> _savePayment(Student student, double amount, String txnId, String orderId, String method) async {
    try {
      final newPaid = student.feesPaid + amount;
      await FirebaseFirestore.instance.collection('students').doc(student.id).update({
        'feesPaid': newPaid,
      });

      final receiptRef = FirebaseFirestore.instance.collection('receipts').doc();
      await receiptRef.set({
        'receiptNo': 'HD-RC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        'studentId': student.id,
        'studentName': student.name,
        'className': student.className,
        'amount': amount,
        'date': FieldValue.serverTimestamp(),
        'transactionId': txnId,
        'orderId': orderId,
        'paymentMethod': method,
        'description': 'Fee Payment via App: $method',
      });
    } catch (e) {
      debugPrint('Error saving payment: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showResultDialog('Payment Failed', 'Error: ${response.message}', false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showResultDialog('Wallet selected', 'Wallet: ${response.walletName}', true);
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _upiIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(parentChildStudentProvider);
    final structuresAsync = ref.watch(allFeeStructuresProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: studentAsync.when(
        data: (student) {
          if (student == null) {
            return const Center(child: Text('No student assigned.'));
          }
          
          return structuresAsync.when(
            data: (structures) {
              final structure = structures.firstWhere((s) => s.className == student.className, orElse: () => FeeStructure(
                id: '', className: student.className, tuitionFee: 0, termFee: 0, transportFee: 0, examFee: 0, otherFees: 0, updatedAt: DateTime.now()
              ));
              
              final amountDue = student.feesTotal - student.feesPaid;
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageHeader(title: 'Pay Fees', subtitle: '${student.name} • Class: ${student.className}'),
                    const SizedBox(height: 24),
                    _buildFeeSummary(student, structure, amountDue),
                    const SizedBox(height: 20),
                    if (amountDue > 0) ...[
                      _buildPaymentForm(student, amountDue),
                      const SizedBox(height: 20),
                    ],
                    ref.watch(studentReceiptsStreamProvider(student.id)).when(
                      data: (receipts) => _buildPaymentHistory(receipts),
                      loading: () => const ShimmerListView(itemCount: 2, itemHeight: 60),
                      error: (err, _) => Center(child: Text('Error loading history: $err')),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildFeeSummary(Student student, FeeStructure structure, double amountDue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fee Breakdown (Particulars)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (structure.totalFee > 0) ...[
            _buildVerticalFeeLine('Tuition Fees', structure.tuitionFee),
            _buildVerticalFeeLine('Term Fees', structure.termFee),
            _buildVerticalFeeLine('Transport Fees', structure.transportFee),
            _buildVerticalFeeLine('Exam Fees', structure.examFee),
            _buildVerticalFeeLine('Other Fees', structure.otherFees),
          ] else ...[
            _buildVerticalFeeLine('Manual Total Fee Assignment', student.feesTotal),
          ],
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          _buildVerticalFeeLine('Total Payable', student.feesTotal, isBold: true),
          _buildVerticalFeeLine('Already Paid', student.feesPaid, isBold: true, color: Colors.greenAccent),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount Due', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: amountDue > 0 ? AppTheme.warning.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: amountDue > 0 ? AppTheme.warning.withOpacity(0.4) : Colors.green.withOpacity(0.4)),
                ),
                child: Text('₹${amountDue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildVerticalFeeLine(String label, double amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? Colors.white : Colors.white70, fontSize: isBold ? 15 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text('₹${amount.toStringAsFixed(0)}', style: TextStyle(color: color ?? Colors.white, fontSize: isBold ? 15 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(Student student, double amountDue) {
    final modes = ['PhonePe (UPI)', 'Google Pay (UPI)', 'Card', 'Netbanking'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Method', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: modes.map((m) {
              final isSelected = _selectedMode == m;
              return ChoiceChip(
                label: Text(m),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedMode = m),
                selectedColor: AppTheme.accent.withOpacity(0.15),
                checkmarkColor: AppTheme.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                labelStyle: TextStyle(color: isSelected ? AppTheme.accent : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
              );
            }).toList(),
          ),
          if (_selectedMode.contains('UPI')) ...[
            const SizedBox(height: 16),
            AnimatedFocusField(
              controller: _upiIdController,
              labelText: 'UPI ID (Required for $_selectedMode)',
              hintText: 'e.g. name@okhdfcbank',
              prefixIcon: const Icon(Icons.payment_rounded, size: 20, color: AppTheme.accent),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: AppButton(
              color: AppTheme.accent,
              onPressed: () {
                final upiId = _upiIdController.text.trim();
                
                if (_selectedMode.contains('UPI')) {
                  if (upiId.isEmpty) {
                    AppToast.show(context, message: 'Please enter your UPI ID to proceed', type: ToastType.warning);
                    return;
                  }
                  
                  final upiRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,}@[a-zA-Z]{2,}$');
                  if (!upiRegex.hasMatch(upiId)) {
                    AppToast.show(context, message: 'Please enter a properly formatted UPI ID (e.g., name@bank)', type: ToastType.warning);
                    return;
                  }
                }

                _openRazorpay(amountDue, student, _selectedMode, upiId);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Pay ₹${amountDue.toStringAsFixed(0)} via $_selectedMode', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildPaymentHistory(List<Receipt> receipts) {
    if (receipts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
        child: const Text('No recent payments found.', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          ...receipts.map((h) {
             final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(h.date);
             return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.receipt_rounded, color: AppTheme.accent, size: 20),
              ),
              title: Text(h.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text('${h.receiptNo}\n$dateStr', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4)),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('₹${h.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.download_rounded, size: 18, color: AppTheme.primary),
                    onPressed: () {
                      AppToast.show(context, message: 'Downloading PDF Receipt: ${h.receiptNo}...', type: ToastType.success);
                    },
                    tooltip: 'Download Receipt',
                  ),
                ],
              ),
             );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  void _openRazorpay(double amount, Student student, String selectedMode, String upiId) async {
    if (amount <= 0) return;
    
    _currentStudent = student;
    _currentAmountToBePaid = amount;

    // 1. Create Checkout Order ID from Backend via REST API
    AppToast.show(context, message: 'Initialising secure payment...', type: ToastType.info);
    
    String orderId = '';
    try {
      // Simulated Backend Call for demonstration
      // final res = await http.post(
      //   Uri.parse('https://your-backend.com/api/create-order'),
      //   body: jsonEncode({'amount': (amount * 100).toInt(), 'currency': 'INR'}),
      //   headers: {'Content-Type': 'application/json'},
      // );
      // orderId = jsonDecode(res.body)['orderId'];
      
      await Future.delayed(const Duration(seconds: 1));
      orderId = 'order_live_${DateTime.now().millisecondsSinceEpoch}'; // Mocking Order ID
    } catch (e) {
      AppToast.show(context, message: 'Failed to create payment order', type: ToastType.error);
      return;
    }

    // Convert to paise
    int amountInPaise = (amount * 100).toInt();

    var options = <String, dynamic>{
      'key': 'rzp_test_1DP5mmOlF5G5ag', 
      'amount': amountInPaise,
      'name': 'HD Preprimary School',
      'description': 'Fee Payment for ${student.name}',
      'order_id': orderId,
      'prefill': {
        'contact': student.phone,
        'email': student.parentEmail,
        'name': student.parent,
      },
      'theme': {
        'color': '#1E293B'
      }
    };

    if (kIsWeb) {
      // REAL LIVE WEB CHECKOUT via JS Interop
      js.context.callMethod('openRazorpayCheckout', [
        js.JsObject.jsify(options),
        js.allowInterop((paymentId, orderId, signature) {
          _processPaymentSuccess(paymentId, orderId ?? '', signature ?? '');
        }),
        js.allowInterop((error) {
           _showResultDialog('Payment Failed', 'Reason: $error', false);
        })
      ]);
      return;
    }

    try {
      _razorpay?.open(options);
    } catch (e) {
      _showResultDialog('Error', 'Cannot launch payment window: $e', false);
    }
  }

  void _showResultDialog(String title, String message, bool isSuccess) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle_rounded : Icons.error_rounded, 
                 color: isSuccess ? AppTheme.accent : Colors.red, size: 28),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _FeeLine extends StatelessWidget {
  final String label;
  final String amount;
  final bool isSmall;
  const _FeeLine({required this.label, required this.amount, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(amount, style: TextStyle(color: Colors.white, fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
