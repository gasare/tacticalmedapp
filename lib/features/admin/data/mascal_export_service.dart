import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../patients/domain/patient_model.dart';

class MascalExportService {
  static Future<void> generateAndShareCSV(List<Patient> patients) async {
    final buffer = StringBuffer();
    
    // Write Headers
    buffer.writeln('BATTLE ROSTER,NAME,GENDER,AGE,UNIT,GPS LOCATION,TRIAGE SEVERITY,INJURIES,DTG (Date-Time Group)');
    
    // Write Data
    for (var patient in patients) {
      final rosterId = patient.id.substring(0, 8).toUpperCase();
      final name = _escapeCSV(patient.name);
      final gender = _escapeCSV(patient.gender);
      final age = patient.age;
      final unit = _escapeCSV(patient.unit ?? 'UNKNOWN');
      final gps = _escapeCSV(patient.gpsLocation ?? 'UNKNOWN');
      final severity = _escapeCSV(patient.severity);
      final injuries = _escapeCSV(patient.injuries);
      final dtg = DateFormat('yyyy-MM-dd HH:mm:ss').format(patient.registeredAt);

      buffer.writeln('$rosterId,$name,$gender,$age,$unit,$gps,$severity,$injuries,$dtg');
    }

    final output = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${output.path}/MASCAL_REPORT_$timestamp.csv');
    
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'MASCAL Patient Report - $timestamp',
    );
  }

  static String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
