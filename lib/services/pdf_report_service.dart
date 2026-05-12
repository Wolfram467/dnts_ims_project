import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/print_settings.dart';

class PdfReportService {
  static Future<void> generateInventoryReport(
    String selectedFacilityName,
    Map<String, Map<String, List<Map<String, dynamic>>>> groupedAuditComponents,
    PrintSettings settings,
  ) async {
    final pdfDocument = pw.Document();
    final darkBlueColor = PdfColor.fromHex('#000080');

    final categories = groupedAuditComponents[selectedFacilityName] ?? {};

    if (categories.isEmpty) {
      pdfDocument.addPage(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Text('No data for $selectedFacilityName'))));
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfDocument.save(),
        name: 'Empty_Report.pdf',
      );
      return;
    }

    for (final entry in categories.entries) {
      final categoryName = entry.key;
      final components = entry.value;
      final List<List<String>> categoryData = [];

      for (int i = 0; i < components.length; i++) {
        final component = components[i];
        
        // Translate L1_D01 to LAB1 - PC1
        String location = component['desk_id']?.toString() ?? 'N/A';
        final deskMatch = RegExp(r'L\d+_D(\d+)').firstMatch(location);
        
        if (deskMatch == null) {
          // Maintain existing location if no match
        } else {
          final pcNumberString = deskMatch.group(1) ?? '0';
          final pcNumber = int.tryParse(pcNumberString) ?? 0;
          final labName = selectedFacilityName.toUpperCase().replaceAll(' ', '');
          location = '$labName - PC$pcNumber';
        }

        // Combine Manufacturer and DNTS Serials
        final manufacturerSerial = component['mfg_serial']?.toString() ?? 'UNKNOWN';
        final dntsSerial = component['dnts_serial']?.toString() ?? 'N/A';
        
        final String serialCombined;
        if (manufacturerSerial == 'UNKNOWN') {
          serialCombined = dntsSerial;
        } else if (manufacturerSerial.isEmpty) {
          serialCombined = dntsSerial;
        } else {
          serialCombined = '$manufacturerSerial / $dntsSerial';
        }

        // Map 'Deployed' to 'FUNCTIONAL' to match official forms
        String status = component['status']?.toString().toUpperCase() ?? 'DEPLOYED';
        if (status == 'DEPLOYED') {
          status = 'FUNCTIONAL';
        }

        categoryData.add([
          (i + 1).toString(),
          categoryName.toUpperCase(),
          'UNKNOWN',
          serialCombined,
          location,
          'N/A',
          status,
        ]);
      }

      // Add a distinct page (or set of pages) for each Category
      pdfDocument.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.legal,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context pdfContext) {
            return [
              pw.Container(
                width: double.infinity,
                color: darkBlueColor,
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('VERSION 15 ${settings.academicYear}', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.SizedBox(height: 2),
                    pw.Text('${selectedFacilityName.toUpperCase()} INVENTORY', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              pw.Table.fromTextArray(
                headers: ['CTN', 'PARTICULAR', 'BRAND', 'SERIAL/STICKER NUMBER', 'LOCATION', 'DATE OF ACQUISITION', 'STATUS'],
                data: categoryData,
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: pw.BoxDecoration(color: darkBlueColor),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellHeight: 25,
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(1.0),
                  3: const pw.FlexColumnWidth(3.0),
                  4: const pw.FlexColumnWidth(1.2),
                  5: const pw.FlexColumnWidth(1.5),
                  6: const pw.FlexColumnWidth(1.2),
                },
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                  6: pw.Alignment.center,
                },
              ),
              pw.SizedBox(height: 20),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('DATE UPDATED: ${settings.dateUpdated}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('T.A ASSIGNED: ${settings.taAssignedNames}', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center),
                  pw.SizedBox(height: 4),
                  pw.Text('SHIFT TYPE: ${settings.shiftType}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ];
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat pdfPageFormat) async => pdfDocument.save(),
      name: 'Inventory_Ledger_${selectedFacilityName.replaceAll(' ', '_')}.pdf',
    );
  }
}
