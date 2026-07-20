import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/chord_sheet_entity.dart';

/// Monta um PDF da cifra (título, artista, tom/BPM e cada seção com letra +
/// acordes alinhados), com o ícone do app centralizado no rodapé de cada
/// página.
Future<Uint8List> buildChordSheetPdf({
  required String title,
  required String artist,
  required ChordSheetEntity chordSheet,
}) async {
  final doc = pw.Document();

  final regular = pw.Font.helvetica();
  final bold = pw.Font.helveticaBold();
  final mono = pw.Font.courier();
  final monoBold = pw.Font.courierBold();

  final iconBytes = await rootBundle.load('assets/icons/icon-512x512.png');
  final iconImage = pw.MemoryImage(iconBytes.buffer.asUint8List());

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 56),
      header: (context) => context.pageNumber == 1
          ? _buildHeader(chordSheet, title, artist, regular, bold)
          : pw.SizedBox(),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Image(iconImage, width: 20, height: 20),
      ),
      build: (context) => [
        for (final section in chordSheet.sections)
          _buildSection(section, mono, monoBold),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _buildHeader(
  ChordSheetEntity chordSheet,
  String title,
  String artist,
  pw.Font regular,
  pw.Font bold,
) {
  final song = chordSheet.song;
  final infoParts = <String>[
    if (song.originalKey != null) 'Tom ${song.originalKey}',
    if (song.bpm != null) '${song.bpm} BPM',
  ];

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 18)),
      if (artist.trim().isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Text(
          artist,
          style: pw.TextStyle(
            font: regular,
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
      ],
      if (infoParts.isNotEmpty) ...[
        pw.SizedBox(height: 6),
        pw.Text(
          infoParts.join('   •   '),
          style: pw.TextStyle(
            font: regular,
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
      ],
      pw.SizedBox(height: 10),
      pw.Divider(color: PdfColors.grey400),
      pw.SizedBox(height: 8),
    ],
  );
}

pw.Widget _buildSection(
  ChordSectionEntity section,
  pw.Font mono,
  pw.Font monoBold,
) {
  final children = <pw.Widget>[
    pw.Text(
      section.label.isNotEmpty ? section.label : section.type.ptLabel,
      style: pw.TextStyle(font: monoBold, fontSize: 12),
    ),
    pw.SizedBox(height: 4),
  ];

  if (section.type == ChordSectionType.chordSequence) {
    final chords = section.lines.isEmpty
        ? const <ChordEntity>[]
        : section.lines.first.chords;
    final sorted = [...chords]
      ..sort((a, b) => a.position.compareTo(b.position));
    children.add(
      pw.Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          for (final chord in sorted)
            pw.Text(
              chord.chord,
              style: pw.TextStyle(font: monoBold, fontSize: 11),
            ),
        ],
      ),
    );
  } else {
    for (final line in section.lines) {
      final chordLine = buildChordLineText(line.text, line.chords);
      if (chordLine.isNotEmpty) {
        children.add(
          pw.Text(chordLine, style: pw.TextStyle(font: monoBold, fontSize: 11)),
        );
      }
      children.add(
        pw.Text(
          line.text.isEmpty ? '(instrumental)' : line.text,
          style: pw.TextStyle(
            font: mono,
            fontSize: 11,
            fontStyle: line.text.isEmpty
                ? pw.FontStyle.italic
                : pw.FontStyle.normal,
            color: line.text.isEmpty ? PdfColors.grey600 : PdfColors.black,
          ),
        ),
      );
    }
  }

  children.add(pw.SizedBox(height: 14));
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: children,
  );
}
