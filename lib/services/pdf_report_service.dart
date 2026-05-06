import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  /// Generate and preview a PDF inventory report
  static Future<void> generateInventoryReport(
    String selectedFacilityName,
    Map<String, Map<String, List<Map<String, dynamic>>>> groupedAuditComponents,
  ) async {
    final pdfDocument = pw.Document();

    // Flatten data for the table
    final List<List<String>> reportTableData = [];
    
    // Header row
    reportTableData.add([
      'CTN',
      'Particular',
      'Brand',
      'Serial / Sticker Number',
      'Location',
      'Date of Acquisition',
      'Status',
    ]);

    // Add data rows - Iterating through Facility -> Category -> Components
    groupedAuditComponents.forEach((facilityName, categoriesMap) {
      categoriesMap.forEach((categoryName, componentList) {
        for (var component in componentList) {
          reportTableData.add([
            component['desk_id']?.toString() ?? 'N/A',
            categoryName,
            'UNKNOWN', // Default as requested
            component['dnts_serial']?.toString() ?? 'N/A',
            facilityName,
            'N/A', // Default as requested
            component['status']?.toString() ?? 'Deployed',
          ]);
        }
      });
    });

    pdfDocument.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context pdfContext) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('INVENTORY LEDGER: $selectedFacilityName',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  pw.Text('Generated: ${DateTime.now().toString().split('.')[0]}',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: reportTableData[0],
              data: reportTableData.sublist(1),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellHeight: 25,
              columnWidths: {
                0: const pw.FlexColumnWidth(1.0),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(2.5),
                4: const pw.FlexColumnWidth(1.2),
                5: const pw.FlexColumnWidth(1.5),
                6: const pw.FlexColumnWidth(1.5),
              },
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat pdfPageFormat) async => pdfDocument.save(),
      name: 'Inventory_Ledger_${selectedFacilityName.replaceAll(' ', '_')}.pdf',
    );
  }
}
