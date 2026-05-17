import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../dashboard/data/dashboard_providers.dart';
import '../../tools/data/tool_detail_providers.dart';

class PdfReportService {
  const PdfReportService._();

  static Future<void> printGeneralStatus(DashboardSnapshot snapshot) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _header('SIGCAL - Estatus general de herramientas'),
          pw.SizedBox(height: 16),
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _metric('Inventario', snapshot.totalTools.toString()),
              _metric('', snapshot.inCalibration.toString()),
              _metric('Accion requerida', snapshot.actionRequired.toString()),
              _metric('Health score', '${snapshot.healthScore.round()}%'),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['', '', '', 'Vence', ''],
            data: [
              for (final tool in snapshot.tools)
                [
                  tool.internalCode ?? '-',
                  tool.displayName,
                  tool.currentLocation ?? '-',
                  _formatDate(tool.latestCalibration?.expirationDate),
                  _stateLabel(tool.complianceState),
                ],
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  static Future<void> printToolStatus(ToolDetailRecord tool) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _header('SIGCAL - Estatus independiente de herramienta'),
          pw.SizedBox(height: 12),
          pw.Text(
            tool.nomenclature,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _metric('', tool.internalCode ?? '-'),
              _metric('Serie', tool.serialNumber ?? '-'),
              _metric('Parte', tool.partNumber ?? '-'),
              _metric('', _stateLabel(tool.complianceState)),
            ],
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Datos tecnicos'),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: ['Campo', 'Valor'],
            data: [
              ['Fabricante', tool.manufacturer ?? '-'],
              ['Modelo', tool.model ?? '-'],
              ['Categoria', tool.category ?? '-'],
              ['', tool.currentLocation ?? '-'],
              ['Fecha adquisicion', _formatDate(tool.acquisitionDate)],
              ['QR unico', tool.qrCode ?? '-'],
              ['Data sheet', tool.dataSheetUrl ?? '-'],
            ],
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Historial de calibraciones'),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: ['Fecha', 'Certificado', 'Centro', 'Resultado', 'Vence'],
            data: [
              for (final item in tool.calibrations)
                [
                  _formatDate(item.calibrationDate),
                  item.certificateNumber ?? '-',
                  item.providerName ?? item.calibrationCenter ?? '-',
                  item.result ?? '-',
                  _formatDate(item.expirationDate),
                ],
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  static Future<void> printToolQrLabel(ToolDetailRecord tool) async {
    final doc = pw.Document();
    final certificate = tool.latestCalibration?.certificateNumber ?? '-';

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          90 * PdfPageFormat.mm,
          55 * PdfPageFormat.mm,
          marginAll: 5 * PdfPageFormat.mm,
        ),
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blueGrey500, width: 1.2),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: tool.toolQrPayload,
                width: 92,
                height: 92,
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SIGCAL',
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      tool.nomenclature,
                      maxLines: 3,
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Cod: ${tool.internalCode ?? '-'}'),
                    pw.Text('Serie: ${tool.serialNumber ?? '-'}'),
                    pw.Text('Cert: $certificate'),
                    pw.Text('QR: ${tool.qrCode ?? '-'}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  static Future<void> printLoanVoucher({
    required ToolDetailRecord tool,
    required ToolLoanRecord loan,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header('SIGCAL - Vale digital de retiro'),
            pw.SizedBox(height: 20),
            pw.Text(
              tool.nomenclature,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ['Campo', 'Detalle'],
              data: [
                ['', tool.internalCode ?? '-'],
                ['Responsable', loan.borrowerName],
                ['Taller', loan.workshop],
                ['Fecha retiro', _formatDate(loan.loanDate)],
                ['Retorno estimado', _formatDate(loan.expectedReturnDate)],
                ['Validez QR', loan.qrPayload],
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blueGrey300),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Este vale digital fue generado por SIGCAL. El codigo QR valida el retiro dentro del sistema.',
                  ),
                  pw.SizedBox(height: 14),
                  pw.Center(
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: loan.qrPayload,
                      width: 150,
                      height: 150,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  static pw.Widget _header(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey900,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            DateTime.now().toIso8601String().split('T').first,
            style: const pw.TextStyle(color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  static pw.Widget _metric(String label, String value) {
    return pw.Container(
      width: 128,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey100),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.blueGrey)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static String _stateLabel(ComplianceState state) {
    return switch (state) {
      ComplianceState.compliant => '',
      ComplianceState.grace => 'En gracia',
      ComplianceState.warning => 'Critico',
      ComplianceState.expired => 'Vencido',
      ComplianceState.inCalibration => '',
      ComplianceState.withoutCalibration => '',
    };
  }

  static String _formatDate(DateTime? value) {
    if (value == null || value.millisecondsSinceEpoch == 0) {
      return '-';
    }

    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
