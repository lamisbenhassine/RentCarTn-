import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/car.dart';
import '../models/user_profile.dart';
import 'pdf_download_stub.dart'
    if (dart.library.html) 'pdf_download_web.dart' as pdf_download;

/// Génère et exporte un devis PDF pour les véhicules sélectionnés.
class DevisPdfService {
  static const appName = 'RentCar Tunisia';

  Future<pw.Font> _loadFont(String asset) async {
    final data = await rootBundle.load(asset);
    return pw.Font.ttf(data);
  }

  pw.Widget _clientBlock({
    required pw.Font base,
    required pw.Font bold,
    required UserProfile client,
  }) {
    final phone = client.phone.trim().isEmpty
        ? '—'
        : '+216 ${client.phone.trim()}';
    final lines = <String>[
      'Nom : ${client.lastName}',
      'Prénom : ${client.firstName}',
      'E-mail : ${client.email}',
      'Téléphone : $phone',
      if (client.city.trim().isNotEmpty) 'Ville : ${client.city}',
      if (client.address.trim().isNotEmpty) 'Adresse : ${client.address}',
    ];

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey300),
        borderRadius: pw.BorderRadius.circular(6),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Informations client',
            style: pw.TextStyle(
              font: bold,
              fontSize: 12,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 8),
          for (final line in lines)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                line,
                style: pw.TextStyle(
                  font: base,
                  fontSize: 10,
                  color: PdfColors.grey800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<Uint8List> buildPdf(
    List<Car> cars, {
    UserProfile? client,
  }) async {
    final base = await _loadFont('assets/fonts/NotoSans-Regular.ttf');
    final bold = await _loadFont('assets/fonts/NotoSans-Bold.ttf');

    final now = DateTime.now();
    final dateLabel = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final totalPerDay =
        cars.fold<double>(0, (sum, c) => sum + c.pricePerDay);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: base, bold: bold),
        build: (context) => [
          pw.Text(
            appName,
            style: pw.TextStyle(
              font: bold,
              fontSize: 22,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Devis de location',
            style: pw.TextStyle(
              font: bold,
              fontSize: 16,
              color: PdfColors.blueGrey700,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Date : $dateLabel',
            style: pw.TextStyle(
              font: base,
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${cars.length} véhicule${cars.length > 1 ? 's' : ''} sélectionné'
            '${cars.length > 1 ? 's' : ''}',
            style: pw.TextStyle(
              font: base,
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
          if (client != null) ...[
            pw.SizedBox(height: 16),
            _clientBlock(base: base, bold: bold, client: client),
          ],
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Véhicule',
              'Année',
              'Lieu',
              'Prix / jour (TND)',
            ],
            data: [
              for (final car in cars)
                [
                  car.fullName,
                  '${car.year}',
                  car.city,
                  car.pricePerDay.toStringAsFixed(0),
                ],
            ],
            headerStyle: pw.TextStyle(
              font: bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            cellStyle: pw.TextStyle(font: base, fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              1: pw.Alignment.center,
              3: pw.Alignment.centerRight,
            },
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerCount: 1,
          ),
          pw.SizedBox(height: 24),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                border: pw.Border.all(color: PdfColors.blueGrey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total journalier',
                    style: pw.TextStyle(
                      font: base,
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${totalPerDay.toStringAsFixed(0)} TND / jour',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 16,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 28),
          pw.Text(
            'Document généré automatiquement par $appName. '
            'Tarifs indicatifs hors options supplémentaires.',
            style: pw.TextStyle(
              font: base,
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> exportQuote(
    List<Car> cars, {
    UserProfile? client,
  }) async {
    if (cars.isEmpty) return;

    final bytes = await buildPdf(cars, client: client);
    final filename =
        'devis_rentcar_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    if (kIsWeb) {
      pdf_download.downloadPdfBytes(bytes, filename);
      return;
    }

    try {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (_) {
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: filename,
      );
    }
  }
}
