// lib/core/utils/pdf_receipt_generator.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReceiptGenerator {
  static Future<Uint8List> generateReceipt({
    required String receiptNo,
    required String studentName,
    required String className,
    required double amount,
    required double balance,
    required String paymentMode,
    required DateTime date,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('HD PREPRIMARY SCHOOL', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 4),
                      pw.Text('Nurturing Young Minds', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                    ]
                  ),
                ),
                pw.SizedBox(height: 32),
                pw.Center(
                  child: pw.Text('FEE RECEIPT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                ),
                pw.SizedBox(height: 32),
                // Details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Receipt No: $receiptNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${date.day}/${date.month}/${date.year}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 24),
                // Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
                  children: [
                    _buildTableRow('Student Name:', studentName, isHeader: true),
                    _buildTableRow('Class:', className),
                    _buildTableRow('Payment Mode:', paymentMode),
                    _buildTableRow('Amount Paid:', 'Rs. ${amount.toStringAsFixed(2)}', isHeader: true),
                    _buildTableRow('Remaining Balance:', 'Rs. ${balance.toStringAsFixed(2)}'),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Parent Signature: ______________'),
                    pw.Text('Authorized Signatory: ______________'),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Center(
                  child: pw.Text('Thank you for the payment!', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildTableRow(String label, String value, {bool isHeader = false}) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, style: pw.TextStyle(fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
      ],
    );
  }
}
