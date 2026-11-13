import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'app_date_utils.dart';
import 'currency_utils.dart';
import 'statement_data.dart';

/// Builds a print-ready PDF for [statement].
Future<Uint8List> buildStatementPdf(
  CustomerStatement statement,
  PdfPageFormat format,
) async {
  final document = pw.Document(
    title: 'Statement - ${statement.customer}',
    creator: 'Credit Bill System',
  );

  final regularFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
  );
  final boldFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
  );

  final primary = PdfColor.fromInt(0xFF1565C0);
  final primaryDark = PdfColor.fromInt(0xFF0D47A1);
  final ink = PdfColor.fromInt(0xFF122B47);
  final muted = PdfColor.fromInt(0xFF5B7189);
  final tint = PdfColor.fromInt(0xFFEAF3FF);
  final border = PdfColor.fromInt(0xFFE1EDFB);
  final payment = PdfColor.fromInt(0xFF1E8E5A);
  final today = DateTime.now();

  final firstDate = statement.firstDate;
  final lastDate = statement.lastDate;
  final period = firstDate == null || lastDate == null
      ? 'No transactions'
      : '${formatShortDate(firstDate)} - ${formatShortDate(lastDate)}';

  document.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 30),
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
      footer: (context) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: border, width: 0.7)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Computer-generated statement - Credit Bill System',
                style: pw.TextStyle(fontSize: 8, color: muted),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: muted),
              ),
            ],
          ),
        );
      },
      build: (context) {
        return [
          _buildHeader(
            primary: primary,
            primaryDark: primaryDark,
            ink: ink,
            muted: muted,
            today: today,
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'CUSTOMER STATEMENT',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: primaryDark,
              letterSpacing: 0.4,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'A summary of credit sales and payments for this customer.',
            style: pw.TextStyle(fontSize: 9, color: muted),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: tint,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'STATEMENT FOR',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: muted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      statement.customer,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: ink,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'STATEMENT PERIOD',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: muted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      period,
                      style: pw.TextStyle(fontSize: 9.5, color: ink),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              pw.Expanded(
                child: _summaryBox(
                  label: 'TOTAL CREDIT SALES',
                  value: _amount(statement.totalCredit),
                  color: primary,
                  background: tint,
                  border: border,
                  muted: muted,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _summaryBox(
                  label: 'TOTAL PAYMENTS',
                  value: _amount(statement.totalPayments),
                  color: payment,
                  background: PdfColor.fromInt(0xFFE8F6EF),
                  border: PdfColor.fromInt(0xFFCDEBDD),
                  muted: muted,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _summaryBox(
                  label: 'REMAINING BALANCE',
                  value: _amount(statement.remainingBalance),
                  color: primaryDark,
                  background: PdfColor.fromInt(0xFFF7FAFF),
                  border: border,
                  muted: muted,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'TRANSACTION DETAILS',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: ink,
              letterSpacing: 0.6,
            ),
          ),
          pw.SizedBox(height: 8),
          if (statement.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: border),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'No transactions have been recorded for this customer.',
                style: pw.TextStyle(fontSize: 10, color: muted),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder(
                top: pw.BorderSide(color: border, width: 0.7),
                bottom: pw.BorderSide(color: border, width: 0.7),
                horizontalInside: pw.BorderSide(color: border, width: 0.5),
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(62),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FixedColumnWidth(60),
                4: const pw.FixedColumnWidth(60),
                5: const pw.FixedColumnWidth(68),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primary),
                  children: [
                    _tableHeader('DATE'),
                    _tableHeader('DETAILS'),
                    _tableHeader('TYPE'),
                    _tableHeader('DEBIT', alignRight: true),
                    _tableHeader('CREDIT', alignRight: true),
                    _tableHeader('BALANCE', alignRight: true),
                  ],
                ),
                for (final line in statement.lines)
                  pw.TableRow(
                    children: [
                      _tableBody(
                        formatShortDate(line.entry.date),
                        color: muted,
                      ),
                      _tableBody(line.entry.details, color: ink),
                      _tableBody(
                        line.entry.typeLabel,
                        color: line.entry.isPayment ? payment : primary,
                      ),
                      _tableBody(
                        line.entry.isPayment ? '-' : _amount(line.entry.amount),
                        alignRight: true,
                        color: ink,
                      ),
                      _tableBody(
                        line.entry.isPayment ? _amount(line.entry.amount) : '-',
                        alignRight: true,
                        color: line.entry.isPayment ? payment : ink,
                      ),
                      _tableBody(
                        _amount(line.balanceAfter),
                        alignRight: true,
                        color: ink,
                        bold: true,
                      ),
                    ],
                  ),
              ],
            ),
          pw.SizedBox(height: 16),
          _totalRow(
            statement: statement,
            primaryDark: primaryDark,
            ink: ink,
            border: border,
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Thank you for your business. Please contact the shop if you '
            'have any questions about this statement.',
            style: pw.TextStyle(fontSize: 9, color: muted, lineSpacing: 2),
          ),
        ];
      },
    ),
  );

  return document.save();
}

pw.Widget _buildHeader({
  required PdfColor primary,
  required PdfColor primaryDark,
  required PdfColor ink,
  required PdfColor muted,
  required DateTime today,
}) {
  return pw.Column(
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 38,
                height: 38,
                decoration: pw.BoxDecoration(
                  color: primary,
                  borderRadius: pw.BorderRadius.circular(9),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'CB',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CREDIT BILL SYSTEM',
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryDark,
                      letterSpacing: 0.4,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Shop credit and billing',
                    style: pw.TextStyle(fontSize: 9, color: muted),
                  ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'STATEMENT DATE',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: muted,
                  letterSpacing: 0.8,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                formatShortDate(today),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: ink,
                ),
              ),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 14),
      pw.Divider(color: PdfColor.fromInt(0xFFE1EDFB), height: 1),
    ],
  );
}

pw.Widget _summaryBox({
  required String label,
  required String value,
  required PdfColor color,
  required PdfColor background,
  required PdfColor border,
  required PdfColor muted,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(11),
    decoration: pw.BoxDecoration(
      color: background,
      border: pw.Border.all(color: border, width: 0.7),
      borderRadius: pw.BorderRadius.circular(7),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: muted,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _tableHeader(String text, {bool alignRight = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 7),
    child: pw.Text(
      text,
      textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(
        fontSize: 7.5,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        letterSpacing: 0.4,
      ),
    ),
  );
}

pw.Widget _tableBody(
  String text, {
  required PdfColor color,
  bool alignRight = false,
  bool bold = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 7),
    child: pw.Text(
      text,
      textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(
        fontSize: 8.5,
        color: color,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

pw.Widget _totalRow({
  required CustomerStatement statement,
  required PdfColor primaryDark,
  required PdfColor ink,
  required PdfColor border,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF7FAFF),
      border: pw.Border.all(color: border, width: 0.7),
      borderRadius: pw.BorderRadius.circular(7),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'REMAINING BALANCE',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: primaryDark,
                letterSpacing: 0.7,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'After all recorded credit sales and payments',
              style: pw.TextStyle(fontSize: 8.5, color: ink),
            ),
          ],
        ),
        pw.Text(
          _amount(statement.remainingBalance),
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: primaryDark,
          ),
        ),
      ],
    ),
  );
}

String _amount(double value) => formatRupees(value);
