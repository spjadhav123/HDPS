// lib/core/models/receipt_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Receipt {
  final String id;
  final String receiptNo;
  final String studentId;
  final String studentName;
  final String className;
  final double amount;
  final DateTime date;
  final String transactionId;
  final String orderId;
  final String paymentMethod;
  final String description;
  final String receivedFrom;
  final String installment;

  Receipt({
    required this.id,
    required this.receiptNo,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.amount,
    required this.date,
    required this.transactionId,
    required this.orderId,
    required this.paymentMethod,
    required this.description,
    this.receivedFrom = '',
    this.installment = '',
  });

  factory Receipt.fromMap(Map<String, dynamic> data, String id) {
    return Receipt(
      id: id,
      receiptNo: data['receiptNo'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      className: data['className'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: data['date'] != null ? (data['date'] as Timestamp).toDate() : DateTime.now(),
      transactionId: data['transactionId'] ?? '',
      orderId: data['orderId'] ?? '',
      paymentMethod: data['paymentMethod'] ?? data['paymentMode'] ?? '',
      description: data['description'] ?? '',
      receivedFrom: data['receivedFrom'] ?? '',
      installment: data['installment'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'receiptNo': receiptNo,
      'studentId': studentId,
      'studentName': studentName,
      'className': className,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'transactionId': transactionId,
      'orderId': orderId,
      'paymentMethod': paymentMethod,
      'description': description,
      'receivedFrom': receivedFrom,
      'installment': installment,
    };
  }
}

