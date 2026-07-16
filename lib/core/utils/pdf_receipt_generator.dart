// lib/core/utils/pdf_receipt_generator.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

class PdfReceiptGenerator {
  static Future<Uint8List> generateReceipt({
    required String receiptNo,
    required String studentName,
    required String className,
    required double amount,
    required double balance,
    required String paymentMode,
    required DateTime date,
    String? parentName,
    String? transactionId,
    String? installment,
    String? academicYear,
    bool isBookReceipt = false,
    String? booksDetails,
    String? distributionStatus,
  }) async {
    final pdf = pw.Document();

    // Load school logo
    pw.MemoryImage? logoImage;
    try {
      final ByteData bytes = await rootBundle.load('assets/images/logo.jpg');
      final Uint8List logoBytes = bytes.buffer.asUint8List();
      logoImage = pw.MemoryImage(logoBytes);
    } catch (e) {
      // Fallback if logo fails to load
    }

    // Color definitions to match physical receipt
    final crimsonRed = PdfColor.fromInt(0xFFC8102E);
    final darkValue = PdfColors.blueGrey800; // Handwritten fill color simulation

    // Format Date: DD/MM/YYYY
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    // Calculate Academic Year (June to May cycle)
    final schoolYear = date.month >= 6 ? date.year : date.year - 1;
    final yearStr = academicYear ?? '${schoolYear.toString().substring(2)} - ${(schoolYear + 1).toString().substring(2)}';

    // Amount in Words
    final amountWords = _convertNumberToWords(amount);

    // Deducing Installment check
    final isFull = installment == 'Full Payment' || (installment == null && balance <= 0);
    final isFirst = installment == '1st Installment';
    final isSecond = installment == '2nd Installment';

    // Class mapping for checkboxes
    final isPG = className.toLowerCase().contains('playgroup') || className.toLowerCase().contains('pg');
    final isNur = className.toLowerCase().contains('nursery') || className.toLowerCase().contains('nur');
    final isJrKg = className.toLowerCase().contains('jr. kg') || className.toLowerCase().contains('lkg');
    final isSrKg = className.toLowerCase().contains('sr. kg') || className.toLowerCase().contains('ukg');

    final isStatusFull = distributionStatus == 'Fully Distributed';
    final isStatusPartial = distributionStatus == 'Partially Distributed' || distributionStatus == null;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: crimsonRed, width: 2.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Row
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        margin: const pw.EdgeInsets.only(right: 16),
                        child: pw.Image(logoImage, width: 64, height: 64),
                      ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            "Bright Vision Education Society's",
                            style: pw.TextStyle(
                              color: crimsonRed,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            "Humpty Dumpty Pre-School",
                            style: pw.TextStyle(
                              color: crimsonRed,
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            "Plot No. A/9/23, \"Shrirang\", Ashoknagar, Satpur, Nashik - 422012 (Maharashtra)",
                            style: pw.TextStyle(
                              color: crimsonRed,
                              fontSize: 9,
                            ),
                          ),
                          pw.Text(
                            "Mob. No. 9422758714",
                            style: pw.TextStyle(
                              color: crimsonRed,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 64), // Balancing logo size on the right
                  ],
                ),

                pw.SizedBox(height: 10),
                pw.Divider(color: crimsonRed, thickness: 1),
                pw.SizedBox(height: 10),

                // Subheader & Meta Row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Date
                    pw.Row(
                      children: [
                        pw.Text('Date : ', style: pw.TextStyle(color: crimsonRed, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Text(dateStr, style: pw.TextStyle(color: darkValue, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    // Centered Pill
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: crimsonRed,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Text(
                        isBookReceipt ? 'Books Distribution & Payment' : 'Cash / Cheque Receipt',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    // Receipt No & Year
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text('Receipt No.: ', style: pw.TextStyle(color: crimsonRed, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                            pw.Text(receiptNo, style: pw.TextStyle(color: darkValue, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        pw.Row(
                          children: [
                            pw.Text('Year.: 20', style: pw.TextStyle(color: crimsonRed, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                            pw.Text(yearStr, style: pw.TextStyle(color: darkValue, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Main Receipt Layout: Left details column, Right Amount box
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Form fields
                      pw.Expanded(
                        flex: 3,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildFieldRow('Received From Mr./Mrs.', parentName ?? studentName, crimsonRed, darkValue),
                            pw.SizedBox(height: 8),
                            _buildFieldRow('Father of Ward of', studentName, crimsonRed, darkValue),
                            pw.SizedBox(height: 8),
                            _buildFieldRow('of Rs. (in words)', amountWords, crimsonRed, darkValue),
                            pw.SizedBox(height: 8),
                            pw.Row(
                              children: [
                                pw.Text('Dated : ', style: pw.TextStyle(color: crimsonRed, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                pw.Text(dateStr, style: pw.TextStyle(color: darkValue, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(width: 4),
                                pw.Expanded(
                                  child: _buildFieldRow(
                                    'by cheque No. / D.D. No. / Ref.',
                                    transactionId != null && transactionId.isNotEmpty ? transactionId : 'Cash Payment',
                                    crimsonRed,
                                    darkValue,
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 12),
                            if (isBookReceipt) ...[
                              pw.Row(
                                children: [
                                  pw.Text('For Books Set: ', style: pw.TextStyle(color: crimsonRed, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  pw.SizedBox(width: 6),
                                  pw.Expanded(
                                    child: pw.Container(
                                      padding: const pw.EdgeInsets.only(bottom: 1),
                                      decoration: pw.BoxDecoration(
                                        border: pw.Border(
                                          bottom: pw.BorderSide(color: crimsonRed, width: 0.8, style: pw.BorderStyle.dashed),
                                        ),
                                      ),
                                      child: pw.Text(booksDetails ?? 'Standard Book Set', style: pw.TextStyle(color: darkValue, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                    ),
                                  ),
                                  pw.SizedBox(width: 12),
                                  pw.Text('Class: ', style: pw.TextStyle(color: crimsonRed, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  pw.Text(className, style: pw.TextStyle(color: darkValue, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                ],
                              ),
                              pw.SizedBox(height: 12),
                              pw.Row(
                                children: [
                                  pw.Text('Distribution Status: ', style: pw.TextStyle(color: crimsonRed, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  pw.SizedBox(width: 12),
                                  _buildCheckbox('Fully Distributed', isStatusFull, crimsonRed, darkValue),
                                  _buildCheckbox('Partially Distributed', isStatusPartial, crimsonRed, darkValue),
                                ],
                              ),
                            ] else ...[
                              // Class Checkboxes
                              pw.Row(
                                children: [
                                  pw.Text('Against Admission of ', style: pw.TextStyle(color: crimsonRed, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  pw.SizedBox(width: 4),
                                  _buildCheckbox('PG', isPG, crimsonRed, darkValue),
                                  _buildCheckbox('Nur.', isNur, crimsonRed, darkValue),
                                  _buildCheckbox('Jr. Kg.', isJrKg, crimsonRed, darkValue),
                                  _buildCheckbox('Sr.Kg.', isSrKg, crimsonRed, darkValue),
                                  pw.Text('for the Academic Year: ', style: pw.TextStyle(color: crimsonRed, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                                  pw.Text('20$yearStr', style: pw.TextStyle(color: darkValue, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                                ],
                              ),
                              pw.SizedBox(height: 12),
                              // Installment Checkboxes
                              pw.Row(
                                children: [
                                  pw.Text('Thank you ', style: pw.TextStyle(color: crimsonRed, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  pw.SizedBox(width: 12),
                                  _buildCheckbox('I st Install', isFirst, crimsonRed, darkValue),
                                  _buildCheckbox('II nd Install', isSecond, crimsonRed, darkValue),
                                  _buildCheckbox('Full Payment', isFull, crimsonRed, darkValue),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      // Amount Box on Right
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Cash / Cheque / D.D. Sum',
                            style: pw.TextStyle(color: crimsonRed, fontSize: 9, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Container(
                            width: 130,
                            height: 70,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: crimsonRed, width: 2),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Row(
                              children: [
                                pw.Container(
                                  width: 30,
                                  alignment: pw.Alignment.center,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border(right: pw.BorderSide(color: crimsonRed, width: 1.5)),
                                  ),
                                  child: pw.Text(
                                    'f', // Rupee symbol from default PDF symbol font or simple Rupee
                                    style: pw.TextStyle(color: crimsonRed, fontSize: 20, fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                                pw.Expanded(
                                  child: pw.Container(
                                    alignment: pw.Alignment.center,
                                    child: pw.Text(
                                      '${amount.toStringAsFixed(0)}/-',
                                      style: pw.TextStyle(color: darkValue, fontSize: 16, fontWeight: pw.FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                // Signatures & Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Subject to Realization of Cheque / D.D.',
                          style: pw.TextStyle(color: crimsonRed, fontSize: 8, fontStyle: pw.FontStyle.italic),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Remaining Balance: Rs. ${balance.toStringAsFixed(0)}/-',
                          style: pw.TextStyle(color: darkValue, fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(width: 100, height: 0.8, color: crimsonRed),
                        pw.SizedBox(height: 2),
                        pw.Text('Giver\'s Signature', style: pw.TextStyle(color: crimsonRed, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(width: 100, height: 0.8, color: crimsonRed),
                        pw.SizedBox(height: 2),
                        pw.Text('Receiver\'s Signature', style: pw.TextStyle(color: crimsonRed, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'HUMPTY DUMPTY PRE-SCHOOL',
                    style: pw.TextStyle(color: crimsonRed, fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildFieldRow(String label, String value, PdfColor labelColor, PdfColor valueColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(label, style: pw.TextStyle(color: labelColor, fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 1),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: labelColor, width: 0.8, style: pw.BorderStyle.dashed),
                ),
              ),
              child: pw.Text(value, style: pw.TextStyle(color: valueColor, fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCheckbox(String label, bool isChecked, PdfColor borderColor, PdfColor checkColor) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 12,
          height: 12,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: borderColor, width: 1.2),
            borderRadius: pw.BorderRadius.circular(1),
          ),
          alignment: pw.Alignment.center,
          child: isChecked
              ? pw.Text(
                  'X',
                  style: pw.TextStyle(color: checkColor, fontSize: 9, fontWeight: pw.FontWeight.bold),
                )
              : pw.SizedBox(),
        ),
        pw.SizedBox(width: 4),
        pw.Text(label, style: pw.TextStyle(color: borderColor, fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(width: 14),
      ],
    );
  }

  static String _convertNumberToWords(double number) {
    final int val = number.round();
    if (val == 0) return 'Zero';

    final units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
      'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    ];
    final tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String convertLessThanOneThousand(int n) {
      String current;
      if (n % 100 < 20) {
        current = units[n % 100];
        n = n ~/ 100;
      } else {
        current = units[n % 10];
        n = n ~/ 10;
        current = tens[n % 10] + (current.isNotEmpty ? ' ${current}' : '');
        n = n ~/ 10;
      }
      if (n == 0) return current;
      return '${units[n]} Hundred${current.isNotEmpty ? ' and ${current}' : ''}';
    }

    int temp = val;
    String result = '';

    // Crores
    if (temp ~/ 10000000 > 0) {
      result += '${convertLessThanOneThousand(temp ~/ 10000000)} Crore ';
      temp = temp % 10000000;
    }
    // Lakhs
    if (temp ~/ 100000 > 0) {
      result += '${convertLessThanOneThousand(temp ~/ 100000)} Lakh ';
      temp = temp % 100000;
    }
    // Thousands
    if (temp ~/ 1000 > 0) {
      result += '${convertLessThanOneThousand(temp ~/ 1000)} Thousand ';
      temp = temp % 1000;
    }
    // Hundreds
    if (temp > 0) {
      result += convertLessThanOneThousand(temp);
    }

    return '${result.trim()} Rupees Only';
  }
}

