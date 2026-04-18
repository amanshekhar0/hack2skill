import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/prediction_response.dart';

class PdfService {
  static Future<void> generateAndPrint(PredictionResponse result) async {
    final pdf = pw.Document();

    final schemesText = result.matchingSchemes.isEmpty
        ? 'No matching schemes'
        : result.matchingSchemes.join('\n- ');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: const PdfColor(0.1, 0.45, 0.91),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'VAANI SEVA',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'AI-Powered Citizen Welfare Eligibility Report',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'ELIGIBILITY ASSESSMENT RESULT',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor(0.13, 0.45, 0.91),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: result.isEligible
                      ? const PdfColor(0.2, 0.66, 0.33)
                      : const PdfColor(0.92, 0.26, 0.21),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  result.isEligible
                      ? '[ ELIGIBLE ] You qualify for government welfare schemes'
                      : '[ NOT ELIGIBLE ] You do not currently meet eligibility criteria',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
              _infoRow('Eligibility Score',
                  '${(result.eligibilityScore * 100).toStringAsFixed(1)}%'),
              pw.SizedBox(height: 20),
              pw.Text(
                'MATCHING SCHEMES',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor(0.13, 0.45, 0.91),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                      color: const PdfColor(0.9, 0.9, 0.9), width: 1),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  '- $schemesText',
                  style: const pw.TextStyle(fontSize: 12, lineSpacing: 4),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'AI RECOMMENDATION',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor(0.13, 0.45, 0.91),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: const PdfColor(0.97, 0.97, 0.97),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  _sanitizeForPdf(result.voiceUiMessage),
                  style: const pw.TextStyle(fontSize: 12, lineSpacing: 3),
                ),
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.SizedBox(height: 6),
              pw.Text(
                'Government of India | VAANI SEVA Platform',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 160,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(': $value', style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static String _sanitizeForPdf(String text) {
    // If the text contains Hindi/Kannada characters (non-ascii), 
    // replacing it with English fallback since PDF Helvetica lacks Indian fonts
    if (text.codeUnits.any((c) => c > 127)) {
      return "Your eligibility overview has been compiled successfully by VAANI SEVA AI engine based on the information provided.";
    }
    return text.replaceAll('✓', '').replaceAll('✗', '').replaceAll('—', '-');
  }
}
