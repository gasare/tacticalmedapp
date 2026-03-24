import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/patient_model.dart';

class PdfService {
  static Future<void> generateAndSharePatientReport(Patient patient) async {
    final pdf = pw.Document();

    pw.ImageProvider? profileImage;
    if (patient.base64Photo != null && patient.base64Photo!.isNotEmpty) {
      final imageBytes = base64Decode(patient.base64Photo!);
      profileImage = pw.MemoryImage(imageBytes);
    }

    pw.ImageProvider? woundImage;
    if (patient.base64WoundPhoto != null && patient.base64WoundPhoto!.isNotEmpty) {
      final woundBytes = base64Decode(patient.base64WoundPhoto!);
      woundImage = pw.MemoryImage(woundBytes);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TCOM Patient Medical Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.Text('Date: ${patient.registeredAt.year}-${patient.registeredAt.month.toString().padLeft(2, '0')}-${patient.registeredAt.day.toString().padLeft(2, '0')}', style: pw.TextStyle(color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Basic Info
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PATIENT INFORMATION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blue800)),
                  pw.Divider(color: PdfColors.grey400),
                  pw.SizedBox(height: 8),
                  _buildDetailRow('Name:', patient.name),
                  _buildDetailRow('Age:', patient.age.toString()),
                  _buildDetailRow('Gender:', patient.gender),
                  if (patient.unit != null && patient.unit!.isNotEmpty) _buildDetailRow('Unit:', patient.unit!),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            
            // Clinical Info
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('CLINICAL DETAILS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blue800)),
                  pw.Divider(color: PdfColors.grey400),
                  pw.SizedBox(height: 8),
                  _buildDetailRow('Initial Severity:', patient.severity),
                  _buildDetailRow('Injuries:', patient.injuries),
                  _buildDetailRow('Medical History:', patient.medicalHistory.isEmpty ? 'None' : patient.medicalHistory),
                ],
              ),
            ),
            
            // Photos
            pw.SizedBox(height: 24),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (profileImage != null)
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Text('Patient Photo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          height: 200,
                          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
                          child: pw.Image(profileImage, fit: pw.BoxFit.contain),
                        ),
                      ],
                    ),
                  ),
                if (profileImage != null && woundImage != null) pw.SizedBox(width: 16),
                if (woundImage != null)
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Text('Wound Detail', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          height: 200,
                          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
                          child: pw.Image(woundImage, fit: pw.BoxFit.contain),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            pw.SizedBox(height: 40),
            pw.Center(
              child: pw.Text('-- Confidential TCOM Record --', style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10)),
            ),
          ];
        },
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final sanitizedName = patient.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final file = File('${output.path}/Patient_${sanitizedName}_Report.pdf');
    await file.writeAsBytes(await pdf.save());

    // Share PDF
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Secure Patient Report - ${patient.name}',
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 100, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey800))),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }
}
