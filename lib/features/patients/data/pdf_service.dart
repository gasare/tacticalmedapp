import 'dart:convert';
import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive/hive.dart';
import '../../../core/storage/hive_service.dart';
import '../../auth/domain/user_account.dart';
import '../domain/patient_model.dart';
import '../../cases/domain/case_model.dart';

class PdfService {
  static Future<void> generateAndSharePatientReport(Patient patient) async {
    final authBox = Hive.box(HiveService.authBoxName);
    final username = authBox.get('last_logged_in_user');
    UserAccount? medic;
    if (username != null) {
      final accountsBox = Hive.box(HiveService.accountsBoxName);
      medic = accountsBox.get(username);
    }
    
    // Fetch cases for timeline
    final casesBox = Hive.box<CaseRecord>(HiveService.casesBoxName);
    final caseLogs = casesBox.values.where((c) => c.patientId == patient.id).toList();
    caseLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
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
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('DD FORM 1380 (TCCC CASUALTY CARD)',
                          style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black)),
                      pw.Text(
                          'BATTLE ROSTER: ${patient.id.substring(0, 8).toUpperCase()}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('DATE: ${patient.registeredAt.toIso8601String().split('T').first}', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
                ]
              )
            ),
            pw.SizedBox(height: 10),

            _buildTacticalSection('1. IDENTIFICATION', [
              _buildDetailRow('NAME:', patient.name),
              _buildDetailRow('GENDER / AGE:', '${patient.gender} / ${patient.age}'),
              _buildDetailRow('UNIT:', patient.unit ?? 'UNKNOWN'),
              _buildDetailRow('DTG (Date-Time Group):', patient.registeredAt.toString()),
            ]),
            
            _buildTacticalSection('2. EVACUATION / PRIORITY', [
              _buildDetailRow('EVAC PRIORITY:', _getEvacPriority(patient.severity)),
              _buildDetailRow('LOCATION/GRID:', patient.gpsLocation ?? 'UNKNOWN'),
            ]),

            _buildTacticalSection('3. MECHANISM & INJURIES', [
              _buildDetailRow('NARRATIVE:', patient.injuries),
              _buildDetailRow('HISTORY/ALLERGIES:', patient.medicalHistory.isEmpty ? 'NKDA / None noted' : patient.medicalHistory),
            ]),
            
            if (caseLogs.isNotEmpty)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1.5)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('4. TREATMENTS / TIMELINE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Divider(thickness: 1.5),
                    pw.SizedBox(height: 4),
                    ...caseLogs.map((log) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Text('[${log.timestamp.hour.toString().padLeft(2, '0')}${log.timestamp.minute.toString().padLeft(2, '0')}Z] - ${log.noteType.toUpperCase()}: ${log.description}', style: const pw.TextStyle(fontSize: 10)),
                      );
                    }),
                  ]
                )
              ),

            // Photos
            if (profileImage != null || woundImage != null)
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 8),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1.5)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('5. CLINICAL IMAGING', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Divider(thickness: 1.5),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (profileImage != null)
                          pw.Expanded(
                            child: pw.Column(
                              children: [
                                pw.Text('Patient Portrait', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 4),
                                pw.Container(
                                  height: 150,
                                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                                  child: pw.Image(profileImage, fit: pw.BoxFit.contain),
                                ),
                              ],
                            ),
                          ),
                        if (profileImage != null && woundImage != null) pw.SizedBox(width: 8),
                        if (woundImage != null)
                          pw.Expanded(
                            child: pw.Column(
                              children: [
                                pw.Text('Wound Pathology', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 4),
                                pw.Container(
                                  height: 150,
                                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                                  child: pw.Image(woundImage, fit: pw.BoxFit.contain),
                                ),
                              ],
                            ),
                          ),
                      ],
                    )
                  ]
                )
              ),

            if (medic != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Divider(color: PdfColors.black, thickness: 1.5),
                    pw.SizedBox(height: 8),
                    pw.Text('FIRST RESPONDER / MEDIC', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('NAME: ${medic.rank} ${medic.firstName} ${medic.lastName}'.trim(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text('UNIT: ${medic.role} - ${medic.unit}', style: const pw.TextStyle(fontSize: 10)),
                      ]
                    )
                  ]
                )
              ),

            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text('UNCLASSIFIED // FOR OFFICIAL USE ONLY',
                  style: pw.TextStyle(color: PdfColors.black, fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
          ];
        },
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final sanitizedName = patient.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final file = File('${output.path}/DD1380_${sanitizedName}_${patient.id.substring(0, 4)}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Share PDF
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'DD1380 Casualty Card - ${patient.name}',
    );
  }
  
  static String _getEvacPriority(String severity) {
    if (severity == 'Critical') return 'A - URGENT (Immediate Evac)';
    if (severity == 'Moderate') return 'B - PRIORITY (Evac within 4h)';
    return 'C - ROUTINE (Evac within 24h)';
  }

  static pw.Widget _buildTacticalSection(String title, List<pw.Widget> children) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: PdfColors.black)),
          pw.Divider(color: PdfColors.black, thickness: 1.5),
          pw.SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
              width: 140,
              child: pw.Text(label,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: PdfColors.black))),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }
}
