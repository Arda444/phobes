import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/stats_module_palette.dart';
import '../models/statistics_models.dart';

/// PDF ve Excel raporları — Phobes istatistik ekranına yakın düzen.
class StatisticsExportService {
  StatisticsExportService._();
  static final StatisticsExportService instance = StatisticsExportService._();

  static const _bg = PdfColor.fromInt(0xFF0F1117);
  static const _surfaceLight = PdfColor.fromInt(0xFF1A1D26);
  static const _surfaceVariant = PdfColor.fromInt(0xFF252A35);
  static const _onSurface = PdfColor.fromInt(0xFFF1F5F9);
  static const _muted = PdfColor.fromInt(0xFFCBD5E1);
  static const _primary = PdfColor.fromInt(0xFFA78BFA);
  static const _primaryDark = PdfColor.fromInt(0xFF6D28D9);
  static const _border = PdfColor.fromInt(0xFF3D4556);

  /// Modül rengi — yalnızca çubuk, nokta ve kenarlık (metin değil).
  static PdfColor _pdfAccentBar(Color c) => _pdfMixWithWhite(c, 0.25);

  static PdfColor _pdfAccentBorder(Color c) => _pdfMixWithWhite(c, 0.45);

  static PdfColor _pdfMixWithWhite(Color c, double whiteWeight) {
    final argb = c.value;
    final r = ((argb >> 16) & 0xFF);
    final g = ((argb >> 8) & 0xFF);
    final b = argb & 0xFF;
    final w = whiteWeight.clamp(0.0, 1.0);
    final lr = (r + (255 - r) * w).round().clamp(0, 255);
    final lg = (g + (255 - g) * w).round().clamp(0, 255);
    final lb = (b + (255 - b) * w).round().clamp(0, 255);
    return PdfColor.fromInt(0xFF000000 | (lr << 16) | (lg << 8) | lb);
  }

  static const _pageMargin = 40.0;
  static const _radius = 14.0;

  pw.Font? _regular;
  pw.Font? _bold;
  Uint8List? _logoBytes;

  pw.TextStyle _pdfTitle({double size = 15}) => pw.TextStyle(
        font: _bold,
        fontSize: size,
        color: _onSurface,
        lineSpacing: 1.2,
      );

  pw.TextStyle _pdfBody({double size = 10, PdfColor? color}) => pw.TextStyle(
        font: _regular,
        fontSize: size,
        color: color ?? _onSurface,
        lineSpacing: 1.35,
      );

  pw.TextStyle _pdfCaption({double size = 9}) => pw.TextStyle(
        font: _regular,
        fontSize: size,
        color: _muted,
        lineSpacing: 1.3,
      );

  Future<void> sharePdf(StatisticsSnapshot snap, {required String appTitle}) async {
    await _share(
      await buildPdfBytes(snap, appTitle: appTitle),
      'pdf',
      snap,
      appTitle,
    );
  }

  Future<void> shareExcel(StatisticsSnapshot snap, {required String appTitle}) async {
    await _share(
      await buildExcelBytes(snap, appTitle: appTitle),
      'xlsx',
      snap,
      appTitle,
    );
  }

  Future<void> downloadPdf(StatisticsSnapshot snap, {required String appTitle}) async {
    await _save(
      await buildPdfBytes(snap, appTitle: appTitle),
      'pdf',
      snap,
      appTitle,
    );
  }

  Future<void> downloadExcel(StatisticsSnapshot snap, {required String appTitle}) async {
    await _save(
      await buildExcelBytes(snap, appTitle: appTitle),
      'xlsx',
      snap,
      appTitle,
    );
  }

  Future<void> _share(
    Uint8List bytes,
    String ext,
    StatisticsSnapshot snap,
    String appTitle,
  ) async {
    final mime = ext == 'pdf'
        ? 'application/pdf'
        : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: mime,
          name: _fileName(snap, ext),
        ),
      ],
      subject: '$appTitle — ${snap.period.label}',
    );
  }

  Future<void> _save(
    Uint8List bytes,
    String ext,
    StatisticsSnapshot snap,
    String appTitle,
  ) async {
    final base = _fileName(snap, ext).replaceAll('.$ext', '');
    try {
      await FileSaver.instance.saveFile(
        name: base,
        bytes: bytes,
        ext: ext,
        mimeType: ext == 'pdf' ? MimeType.pdf : MimeType.microsoftExcel,
      );
    } catch (e) {
      debugPrint('FileSaver failed ($ext): $e');
      if (kIsWeb) {
        await _share(bytes, ext, snap, appTitle);
        return;
      }
      rethrow;
    }
  }

  String _fileName(StatisticsSnapshot snap, String ext) {
    final stamp = DateFormat('yyyy-MM-dd').format(snap.computedAt);
    return 'phobes-istatistik-${snap.period.name}-$stamp.$ext';
  }

  Future<Uint8List> buildPdfBytes(
    StatisticsSnapshot snap, {
    required String appTitle,
  }) async {
    await _ensureFonts();
    final sections = _sectionsFor(snap);
    final dateStr = DateFormat('d MMMM yyyy, HH:mm', 'tr_TR')
        .format(snap.computedAt);
    final scores = snap.moduleScores;

    final doc = pw.Document(
      title: '$appTitle İstatistik',
      author: appTitle,
    );

    final theme = pw.ThemeData.withFont(base: _regular, bold: _bold);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_pageMargin),
        theme: theme,
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          buildBackground: (_) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _bg),
          ),
        ),
        footer: (ctx) => _pdfPageFooter(appTitle, ctx.pageNumber),
        build: (context) => [
          _pdfHeaderBanner(appTitle, snap.period.label, dateStr),
          pw.SizedBox(height: 18),
          _pdfPanel(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(4, 6, 8, 6),
                  child: _pdfScoreRing(snap.globalActivityScore),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Genel aktivite', style: _pdfTitle(size: 17)),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        '${snap.period.shortLabel} döneminde ${snap.totalActions} eylem kaydedildi.',
                        style: _pdfCaption(size: 10),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: _pdfMiniStat(
                              'Toplam eylem',
                              '${snap.totalActions}',
                              accentBorder: _primary,
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Expanded(
                            child: _pdfMiniStat(
                              'Dönem',
                              snap.period.label,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          _pdfSectionHeading('Modül performansı', '0–100 normalize skor'),
          pw.SizedBox(height: 10),
          _pdfPanel(
            padding: 16,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: _pdfModuleBars(scores),
            ),
          ),
          pw.SizedBox(height: 12),
          _pdfModuleScoreLegend(scores),
          pw.SizedBox(height: 22),
          _pdfSectionHeading('Modül özeti', 'Dönemin ana göstergeleri'),
          pw.SizedBox(height: 12),
          _pdfOverviewGrid(sections),
          for (var i = 0; i < sections.length; i++) ...[
            pw.NewPage(),
            if (i == 0) ...[
              _pdfSectionHeading('Detaylı metrikler', 'Tüm modüller'),
              pw.SizedBox(height: 14),
            ],
            _pdfModuleDetailBlock(sections[i]),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfPanel({
    required pw.Widget child,
    double padding = 18,
    PdfColor? borderColor,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(padding),
      decoration: pw.BoxDecoration(
        color: _surfaceLight,
        borderRadius: pw.BorderRadius.circular(_radius),
        border: pw.Border.all(color: borderColor ?? _border),
      ),
      child: child,
    );
  }

  pw.Widget _pdfPageFooter(String appTitle, int page) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('$appTitle · İstatistik', style: _pdfCaption(size: 8)),
          pw.Text('Sayfa $page', style: _pdfCaption(size: 8)),
        ],
      ),
    );
  }

  pw.Widget _pdfSectionHeading(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: _pdfTitle()),
        pw.SizedBox(height: 4),
        pw.Text(subtitle, style: _pdfCaption()),
      ],
    );
  }

  String _formatPieLegend(Map<String, double> raw, {int maxItems = 4}) {
    final pie = _normalizePie(raw);
    if (pie.isEmpty) return '';
    final sorted = pie.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(maxItems)
        .map((e) => '${e.key} %${e.value.toStringAsFixed(0)}')
        .join('  ·  ');
  }

  pw.Widget _pdfModuleScoreLegend(
    List<({String label, double score, Color color, String hint})> scores,
  ) {
    return _pdfPanel(
      padding: 14,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < scores.length; i++) ...[
            if (i > 0) pw.SizedBox(height: 8),
            _pdfScoreLegendRow(scores[i]),
          ],
        ],
      ),
    );
  }

  pw.Widget _pdfScoreLegendRow(
    ({String label, double score, Color color, String hint}) m,
  ) {
    final accent = _pdfAccentBar(m.color);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 8,
          height: 8,
          margin: const pw.EdgeInsets.only(top: 2),
          decoration: pw.BoxDecoration(color: accent, shape: pw.BoxShape.circle),
        ),
        pw.SizedBox(width: 8),
        pw.SizedBox(
          width: 72,
          child: pw.Text(m.label, style: _pdfBody()),
        ),
        pw.SizedBox(
          width: 36,
          child: pw.Text(
            m.score.toStringAsFixed(0),
            style: pw.TextStyle(font: _bold, fontSize: 11, color: _onSurface),
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Text(
            m.hint,
            style: _pdfCaption(),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfHeaderBanner(String appTitle, String period, String dateStr) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(_radius),
        gradient: const pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [
            _primary,
            _primaryDark,
            _surfaceLight,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: pw.Row(
        children: [
          pw.ClipRRect(
            horizontalRadius: 12,
            verticalRadius: 12,
            child: _logoBytes != null &&
                    _logoBytes!.isNotEmpty &&
                    _isRecognizedRasterImage(_logoBytes!)
                ? pw.Image(
                    pw.MemoryImage(_logoBytes!),
                    width: 44,
                    height: 44,
                    fit: pw.BoxFit.cover,
                  )
                : pw.Container(
                    width: 44,
                    height: 44,
                    color: const PdfColor.fromInt(0x33FFFFFF),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'P',
                      style: pw.TextStyle(
                        font: _bold,
                        fontSize: 22,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  appTitle,
                  style: pw.TextStyle(
                    font: _bold,
                    fontSize: 12,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'İstatistik Raporu',
                  style: pw.TextStyle(
                    font: _bold,
                    fontSize: 20,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF1A1D26),
                  borderRadius: pw.BorderRadius.circular(20),
                  border: pw.Border.all(
                    color: const PdfColor.fromInt(0x66FFFFFF),
                  ),
                ),
                child: pw.Text(
                  period,
                  style: pw.TextStyle(
                    font: _bold,
                    fontSize: 11,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                dateStr,
                style: pw.TextStyle(
                  font: _regular,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfScoreRing(int score) {
    const outer = 92.0;
    const diameter = 76.0;
    const borderW = 3.0;
    final clamped = score.clamp(0, 100);

    return pw.SizedBox(
      width: outer,
      height: outer,
      child: pw.Center(
        child: pw.Container(
          width: diameter,
          height: diameter,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: _surfaceVariant,
            border: pw.Border.all(color: _primary, width: borderW),
          ),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                '$clamped',
                style: pw.TextStyle(
                  font: _bold,
                  fontSize: 24,
                  color: _onSurface,
                ),
              ),
              pw.Text(
                'skor',
                style: pw.TextStyle(
                  font: _regular,
                  fontSize: 9,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  pw.Widget _pdfMiniStat(String label, String value, {PdfColor? accentBorder}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _surfaceVariant,
        borderRadius: pw.BorderRadius.circular(10),
        border: accentBorder != null
            ? pw.Border(left: pw.BorderSide(color: accentBorder, width: 3))
            : null,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: _pdfCaption()),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(font: _bold, fontSize: 13, color: _onSurface),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _pdfModuleBars(
    List<({String label, double score, Color color, String hint})> scores,
  ) {
    return [
      for (final m in scores)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 64,
                child: pw.Text(
                  m.label,
                  style: _pdfBody(),
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  height: 14,
                  decoration: pw.BoxDecoration(
                    color: _surfaceVariant,
                    borderRadius: pw.BorderRadius.circular(7),
                  ),
                  child: pw.Row(
                    children: [
                      if (m.score > 0)
                        pw.Expanded(
                          flex: m.score.clamp(0, 100).round(),
                          child: pw.Container(
                            height: 14,
                            decoration: pw.BoxDecoration(
                              color: _pdfAccentBar(m.color),
                              borderRadius: pw.BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      pw.Expanded(
                        flex: (100 - m.score.clamp(0, 100)).round().clamp(1, 100),
                        child: pw.Container(
                          height: 14,
                          decoration: pw.BoxDecoration(
                            color: _surfaceVariant,
                            borderRadius: pw.BorderRadius.circular(7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.SizedBox(
                width: 28,
                child: pw.Text(
                  m.score.toStringAsFixed(0),
                  style: pw.TextStyle(font: _bold, fontSize: 10, color: _onSurface),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  pw.Widget _pdfOverviewGrid(List<_ExportSection> sections) {
    const cols = 2;
    final rows = <pw.TableRow>[];

    for (var i = 0; i < sections.length; i += cols) {
      rows.add(
        pw.TableRow(
          children: [
            for (var c = 0; c < cols; c++)
              pw.Padding(
                padding: const pw.EdgeInsets.only(
                  right: 6,
                  bottom: 8,
                  left: 2,
                ),
                child: i + c < sections.length
                    ? _pdfModuleOverviewCard(sections[i + c])
                    : pw.SizedBox(height: 118),
              ),
          ],
        ),
      );
    }

    return pw.Table(
      columnWidths: {
        for (var i = 0; i < cols; i++) i: const pw.FlexColumnWidth(),
      },
      children: rows,
    );
  }

  pw.Widget _pdfModuleOverviewCard(_ExportSection section) {
    final accentBar = _pdfAccentBar(section.moduleColor);
    final accentBorder = _pdfAccentBorder(section.moduleColor);
    final headline = section.headline;
    final subtitle = section.subtitle;

    final pieLegend = _formatPieLegend(section.pie, maxItems: 3);

    return pw.Container(
      height: 118,
      decoration: pw.BoxDecoration(
        color: _surfaceLight,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: accentBorder),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            width: 4,
            decoration: pw.BoxDecoration(
              color: accentBar,
              borderRadius: const pw.BorderRadius.horizontal(
                left: pw.Radius.circular(14),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 8,
                        height: 8,
                        decoration: pw.BoxDecoration(
                          color: accentBar,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Expanded(
                        child: pw.Text(
                          section.title,
                          style: pw.TextStyle(
                            font: _bold,
                            fontSize: 11,
                            color: _onSurface,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  if (headline != null)
                    pw.Text(
                      headline,
                      style: pw.TextStyle(
                        font: _bold,
                        fontSize: 20,
                        color: _onSurface,
                      ),
                      maxLines: 1,
                    ),
                  if (subtitle != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      subtitle,
                      style: _pdfCaption(),
                      maxLines: 2,
                    ),
                  ],
                  if (pieLegend.isNotEmpty) ...[
                    pw.Spacer(),
                    pw.Text(
                      pieLegend,
                      style: pw.TextStyle(
                        font: _regular,
                        fontSize: 8,
                        color: _muted,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfModuleDetailBlock(_ExportSection section) {
    final accent = _pdfAccentBar(section.moduleColor);
    final accentBorder = _pdfAccentBorder(section.moduleColor);
    final metrics = section.metrics;
    // Tam sayfa tek modül — 2 sütun yeterli, okunaklı kalır.
    final colCount = metrics.length > 8 ? 3 : 2;
    final rows = <pw.TableRow>[];

    for (var i = 0; i < metrics.length; i += colCount) {
      rows.add(
        pw.TableRow(
          children: [
            for (var c = 0; c < colCount; c++)
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: i + c < metrics.length
                    ? _pdfMetricTile(metrics[i + c], accent)
                    : pw.SizedBox(),
              ),
          ],
        ),
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _surfaceLight,
        borderRadius: pw.BorderRadius.circular(_radius),
        border: pw.Border.all(color: accentBorder),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: pw.BoxDecoration(
              color: _surfaceVariant,
              border: pw.Border(
                left: pw.BorderSide(color: accent, width: 4),
                bottom: const pw.BorderSide(color: _border, width: 0.5),
              ),
              borderRadius: const pw.BorderRadius.vertical(
                top: pw.Radius.circular(_radius - 1),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 10,
                  height: 10,
                  decoration: pw.BoxDecoration(color: accent, shape: pw.BoxShape.circle),
                ),
                pw.SizedBox(width: 8),
                pw.Text(section.title, style: _pdfTitle(size: 13)),
                if (section.headline != null) ...[
                  pw.Expanded(child: pw.SizedBox()),
                  pw.Text(
                    section.headline!,
                    style: pw.TextStyle(
                      font: _bold,
                      fontSize: 13,
                      color: _onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: pw.Table(
              columnWidths: {
                for (var i = 0; i < colCount; i++) i: const pw.FlexColumnWidth(),
              },
              children: rows,
            ),
          ),
          if (section.pie.isNotEmpty)
            pw.Container(
              margin: const pw.EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: pw.BoxDecoration(
                color: _surfaceVariant,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Text(
                'Dağılım: ${_formatPieLegend(section.pie)}',
                style: _pdfCaption(),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _pdfMetricTile(StatMetric metric, PdfColor _) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _surfaceVariant,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            metric.label,
            style: _pdfCaption(),
            maxLines: 2,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            metric.value,
            style: pw.TextStyle(
              font: _bold,
              fontSize: 12,
              color: _onSurface,
              lineSpacing: 1.2,
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Future<Uint8List> buildExcelBytes(
    StatisticsSnapshot snap, {
    required String appTitle,
  }) async {
    final sections = _sectionsFor(snap);
    final excel = Excel.createExcel();
    final defaultName = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultName, 'Özet');

    _writeExcelSummarySheet(
      excel['Özet'],
      snap: snap,
      appTitle: appTitle,
      sections: sections,
    );
    _writeExcelDetailSheet(
      excel['Detay'],
      sections: sections,
    );

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('Excel encode failed');
    }
    return Uint8List.fromList(encoded);
  }

  void _writeExcelSummarySheet(
    Sheet sheet, {
    required StatisticsSnapshot snap,
    required String appTitle,
    required List<_ExportSection> sections,
  }) {
    final w = _ExcelRowWriter(sheet);
    final dateStr = DateFormat('d MMMM yyyy, HH:mm').format(snap.computedAt);
    const colSpan = 6;

    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 20);
    sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 26);
    sheet.setColumnWidth(4, 28);
    sheet.setColumnWidth(5, 22);

    w.titleRow('$appTitle — İstatistik Raporu', colspan: colSpan);
    sheet.setRowHeight(0, 32);
    w.subtitleRow('${snap.period.label} dönemi · $dateStr', colspan: colSpan);
    w.blank();

    w.sectionTitle('Genel aktivite');
    w.summaryRow('Genel skor', '${snap.globalActivityScore} / 100');
    w.summaryRow('Toplam eylem', '${snap.totalActions}');
    w.summaryRow('Dönem', snap.period.label);
    w.summaryRow('Oluşturulma', dateStr);
    w.blank();

    w.sectionTitle('Modül performansı (0–100)');
    w.tableHeader(['', 'Modül', 'Skor', 'Açıklama', 'Özet']);
    var rowIndex = 0;
    for (final m in snap.moduleScores) {
      w.modulePerformanceRow(
        moduleColor: m.color,
        label: m.label,
        score: m.score,
        hint: m.hint,
        summary: _headlineForModule(m.label, sections),
        zebra: rowIndex.isOdd,
      );
      rowIndex++;
    }
    w.blank();

    w.sectionTitle('Modül özeti');
    w.tableHeader(['', 'Modül', 'Ana değer', 'Alt bilgi']);
    rowIndex = 0;
    for (final s in sections) {
      w.moduleSummaryRow(
        moduleColor: s.moduleColor,
        title: s.title,
        headline: s.headline ?? '—',
        subtitle: s.subtitle ?? '—',
        zebra: rowIndex.isOdd,
      );
      rowIndex++;
    }
  }

  void _writeExcelDetailSheet(
    Sheet sheet, {
    required List<_ExportSection> sections,
  }) {
    final w = _ExcelRowWriter(sheet);
    const colSpan = 3;

    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 34);

    w.titleRow('Detaylı metrikler', colspan: colSpan);
    sheet.setRowHeight(0, 30);
    w.blank(count: 2);

    var sectionIndex = 0;
    for (final section in sections) {
      w.moduleSectionTitle(
        section.title,
        headline: section.headline,
        moduleColor: section.moduleColor,
        colspan: colSpan,
      );

      w.tableHeader(['', 'Metrik', 'Değer']);
      var metricIndex = 0;
      for (final m in section.metrics) {
        w.metricRow(
          moduleColor: section.moduleColor,
          label: m.label,
          value: m.value,
          zebra: metricIndex.isOdd,
        );
        metricIndex++;
      }

      if (section.pie.isNotEmpty) {
        w.blank();
        w.pieSectionHeader(section.moduleColor);
        var pieIndex = 0;
        for (final e in section.pie.entries) {
          w.pieRow(
            moduleColor: section.moduleColor,
            label: e.key,
            percent: e.value,
            zebra: pieIndex.isOdd,
          );
          pieIndex++;
        }
      }

      if (sectionIndex < sections.length - 1) {
        w.blank(count: 2);
      }
      sectionIndex++;
    }
  }

  // Excel tema — PDF ile aynı palet (yüzey + vurgu, düşük kontrastlı metin yok).
  static const _xlsSurface = '#1A1D26';
  static const _xlsSurfaceVariant = '#252A35';
  static const _xlsOnSurface = '#F1F5F9';
  static const _xlsMuted = '#94A3B8';
  static const _xlsPrimaryDark = '#6D28D9';
  static const _xlsBorder = '#3D4556';
  static const _xlsRow = '#FFFFFF';
  static const _xlsRowAlt = '#F1F5F9';
  static const _xlsText = '#0F172A';
  static const _xlsTextSecondary = '#475569';

  static ExcelColor _xc(String hex) => ExcelColor.fromHexString(hex);

  static Border _xlsEdge({
    BorderStyle style = BorderStyle.Thin,
    String color = _xlsBorder,
  }) =>
      Border(borderStyle: style, borderColorHex: _xc(color));

  static String _mixHex(Color c, double whiteWeight) {
    final argb = c.value;
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    final w = whiteWeight.clamp(0.0, 1.0);
    final lr = (r + (255 - r) * w).round().clamp(0, 255);
    final lg = (g + (255 - g) * w).round().clamp(0, 255);
    final lb = (b + (255 - b) * w).round().clamp(0, 255);
    return '#${((lr << 16) | (lg << 8) | lb).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static String _xlsAccentHex(Color c) => _mixHex(c, 0.25);

  static String _xlsAccentFillHex(Color c) => _mixHex(c, 0.88);

  static CellStyle _xlsBase({
    required String bg,
    required String fg,
    bool bold = false,
    int fontSize = 11,
    HorizontalAlign align = HorizontalAlign.Left,
    VerticalAlign valign = VerticalAlign.Center,
    Border? left,
    Border? top,
    Border? right,
    Border? bottom,
    NumFormat? numberFormat,
  }) =>
      CellStyle(
        bold: bold,
        fontSize: fontSize,
        backgroundColorHex: _xc(bg),
        fontColorHex: _xc(fg),
        horizontalAlign: align,
        verticalAlign: valign,
        leftBorder: left,
        topBorder: top,
        rightBorder: right,
        bottomBorder: bottom,
        numberFormat: numberFormat ?? NumFormat.standard_0,
      );

  static final _xlsTitleStyle = _xlsBase(
    bg: _xlsPrimaryDark,
    fg: _xlsOnSurface,
    bold: true,
    fontSize: 14,
    align: HorizontalAlign.Center,
  );

  static final _xlsSubtitleStyle = _xlsBase(
    bg: _xlsSurfaceVariant,
    fg: _xlsMuted,
    align: HorizontalAlign.Center,
  );

  static final _xlsSectionStyle = _xlsBase(
    bg: _xlsSurface,
    fg: _xlsOnSurface,
    bold: true,
    left: _xlsEdge(color: _xlsPrimaryDark, style: BorderStyle.Medium),
  );

  static CellStyle _xlsTableHeaderStyle() => _xlsBase(
        bg: _xlsSurfaceVariant,
        fg: _xlsOnSurface,
        bold: true,
        fontSize: 10,
        align: HorizontalAlign.Center,
        left: _xlsEdge(),
        top: _xlsEdge(),
        right: _xlsEdge(),
        bottom: _xlsEdge(),
      );

  static CellStyle _xlsSummaryLabelStyle() => _xlsBase(
        bg: _xlsRowAlt,
        fg: _xlsTextSecondary,
        bold: true,
        fontSize: 10,
        left: _xlsEdge(),
        top: _xlsEdge(),
        bottom: _xlsEdge(),
      );

  static CellStyle _xlsSummaryValueStyle() => _xlsBase(
        bg: _xlsRow,
        fg: _xlsText,
        left: _xlsEdge(),
        top: _xlsEdge(),
        right: _xlsEdge(),
        bottom: _xlsEdge(),
      );

  static CellStyle _xlsDataStyle({required bool zebra}) => _xlsBase(
        bg: zebra ? _xlsRowAlt : _xlsRow,
        fg: _xlsText,
        left: _xlsEdge(),
        right: _xlsEdge(),
        bottom: _xlsEdge(),
      );

  static CellStyle _xlsScoreStyle({required bool zebra}) => _xlsBase(
        bg: zebra ? _xlsRowAlt : _xlsRow,
        fg: _xlsText,
        bold: true,
        align: HorizontalAlign.Center,
        left: _xlsEdge(),
        right: _xlsEdge(),
        bottom: _xlsEdge(),
        numberFormat: NumFormat.standard_1,
      );

  static CellStyle _xlsAccentDotStyle(Color moduleColor) => _xlsBase(
        bg: _xlsAccentFillHex(moduleColor),
        fg: _xlsAccentHex(moduleColor),
        bold: true,
        align: HorizontalAlign.Center,
        left: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: _xc(_xlsAccentHex(moduleColor)),
        ),
        top: _xlsEdge(),
        bottom: _xlsEdge(),
      );

  static CellStyle _xlsModuleNameStyle(Color moduleColor, {required bool zebra}) =>
      _xlsBase(
        bg: _xlsAccentFillHex(moduleColor),
        fg: _xlsText,
        bold: true,
        left: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: _xc(_xlsAccentHex(moduleColor)),
        ),
        top: _xlsEdge(),
        bottom: _xlsEdge(),
      );

  static CellStyle _xlsModuleSectionStyle(Color moduleColor) => _xlsBase(
        bg: _xlsSurface,
        fg: _xlsOnSurface,
        bold: true,
        fontSize: 12,
        left: Border(
          borderStyle: BorderStyle.Thick,
          borderColorHex: _xc(_xlsAccentHex(moduleColor)),
        ),
        top: _xlsEdge(),
        bottom: _xlsEdge(),
      );

  static CellStyle _xlsPieCaptionStyle(Color moduleColor) => _xlsBase(
        bg: _xlsRowAlt,
        fg: _xlsTextSecondary,
        bold: true,
        fontSize: 10,
        left: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: _xc(_xlsAccentHex(moduleColor)),
        ),
      );

  Future<void> _ensureFonts() async {
    if (_regular != null) {
      _logoBytes ??= Uint8List(0);
      return;
    }
    try {
      final data = await rootBundle.load('assets/fonts/Outfit-Regular.ttf');
      final dataBold = await rootBundle.load('assets/fonts/Outfit-Bold.ttf');
      _regular = pw.Font.ttf(
        data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes),
      );
      _bold = pw.Font.ttf(
        dataBold.buffer.asByteData(
          dataBold.offsetInBytes,
          dataBold.lengthInBytes,
        ),
      );
    } catch (e) {
      debugPrint('PDF font load failed, using Helvetica: $e');
      _regular = pw.Font.helvetica();
      _bold = pw.Font.helveticaBold();
    }
    try {
      final logo = await rootBundle.load('assets/icon/icon.png');
      final bytes = logo.buffer.asUint8List(
        logo.offsetInBytes,
        logo.lengthInBytes,
      );
      _logoBytes = _isRecognizedRasterImage(bytes) ? bytes : Uint8List(0);
    } catch (_) {
      _logoBytes = Uint8List(0);
    }
  }

  /// PNG / JPEG magic bytes — [pw.MemoryImage] throws if format is unknown.
  static bool _isRecognizedRasterImage(Uint8List bytes) {
    if (bytes.length < 4) return false;
    final isPng = bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
    return isPng || isJpeg;
  }

  List<_ExportSection> _sectionsFor(StatisticsSnapshot snap) {
    final t = snap.tasks;
    final b = snap.budget;
    final catPie = _normalizePie(b.categoryBreakdown);

    return [
      _ExportSection(
        'Görevler',
        StatsModulePalette.tasks,
        t.primaryMetrics,
        _normalizePie(t.statusPie),
        '${t.completed}',
        '%${t.completionRate.toStringAsFixed(0)} tamamlanma',
      ),
      _ExportSection(
        'Alışkanlık',
        StatsModulePalette.habits,
        snap.habits.metrics,
        _normalizePie(snap.habits.activityPie),
        '${snap.habits.completedInPeriod}',
        '${snap.habits.maxStreak} gün seri',
      ),
      _ExportSection(
        'Bütçe',
        StatsModulePalette.budget,
        snap.budget.metrics,
        catPie.isEmpty ? b.incomeExpensePie : catPie,
        '₺${b.net.toStringAsFixed(0)}',
        '${b.transactionCount} işlem',
      ),
      _ExportSection(
        'Notlar',
        StatsModulePalette.notes,
        snap.notes.metrics,
        _normalizePie(snap.notes.engagementPie),
        '${snap.notes.created}',
        '${snap.notes.favorites} favori',
      ),
      _ExportSection(
        'Randevu',
        StatsModulePalette.appointments,
        snap.appointments.metrics,
        _normalizePie(snap.appointments.statusPie),
        '${snap.appointments.completed}',
        '₺${snap.appointments.totalRevenue.toStringAsFixed(0)}',
      ),
      _ExportSection(
        'İlaç',
        StatsModulePalette.medications,
        snap.medications.metrics,
        _normalizePie(snap.medications.adherencePie),
        '%${snap.medications.adherenceRate.toStringAsFixed(0)}',
        '${snap.medications.dosesTaken} doz',
      ),
      _ExportSection(
        'Kitap',
        StatsModulePalette.books,
        snap.books.metrics,
        _normalizePie(snap.books.statusBreakdown),
        '${snap.books.reading}',
        '${snap.books.finishedInPeriod} biten',
      ),
      if (snap.teams.teamCount > 0)
        _ExportSection(
          'Ekip',
          StatsModulePalette.teams,
          snap.teams.metrics,
          _normalizePie(snap.teams.memberByTeam),
          '${snap.teams.teamCount}',
          '${snap.teams.totalMembers} üye',
        ),
      if (snap.corkboard.notes > 0 || snap.corkboard.connections > 0)
        _ExportSection(
          'Plan Panosu',
          StatsModulePalette.corkboard,
          snap.corkboard.metrics,
          _normalizePie(
            snap.corkboard.typePie.isNotEmpty
                ? snap.corkboard.typePie
                : snap.corkboard.compositionPie,
          ),
          '${snap.corkboard.notes}',
          '${snap.corkboard.connections} bağ',
        ),
    ];
  }

  Map<String, double> _normalizePie(Map<String, double> raw) {
    if (raw.isEmpty) return {};
    final total = raw.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return {};
    return raw.map((k, v) => MapEntry(k, (v / total) * 100));
  }

  static String _headlineForModule(String label, List<_ExportSection> sections) {
    final key = label.toLowerCase();
    for (final s in sections) {
      final title = s.title.toLowerCase();
      if (title.startsWith(key) || key.startsWith(title.substring(0, 2))) {
        return s.headline ?? '—';
      }
    }
    return '—';
  }
}

class _ExcelRowWriter {
  final Sheet sheet;
  int row = 0;

  _ExcelRowWriter(this.sheet);

  void cell(int col, CellValue? value, {CellStyle? style}) {
    final c = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    c.value = value;
    if (style != null) c.cellStyle = style;
  }

  void blank({int count = 1}) => row += count;

  void _mergeRow(int colspan) {
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: colspan - 1, rowIndex: row),
    );
  }

  void titleRow(String text, {required int colspan}) {
    _mergeRow(colspan);
    cell(0, TextCellValue(text), style: StatisticsExportService._xlsTitleStyle);
    sheet.setMergedCellStyle(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      StatisticsExportService._xlsTitleStyle,
    );
    blank();
  }

  void subtitleRow(String text, {required int colspan}) {
    _mergeRow(colspan);
    cell(0, TextCellValue(text), style: StatisticsExportService._xlsSubtitleStyle);
    sheet.setMergedCellStyle(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      StatisticsExportService._xlsSubtitleStyle,
    );
    blank();
  }

  void sectionTitle(String text) {
    _mergeRow(6);
    cell(0, TextCellValue(text), style: StatisticsExportService._xlsSectionStyle);
    sheet.setMergedCellStyle(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      StatisticsExportService._xlsSectionStyle,
    );
    blank();
  }

  void summaryRow(String label, String value) {
    cell(0, TextCellValue(label), style: StatisticsExportService._xlsSummaryLabelStyle());
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
    );
    cell(1, TextCellValue(value), style: StatisticsExportService._xlsSummaryValueStyle());
    sheet.setMergedCellStyle(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
      StatisticsExportService._xlsSummaryValueStyle(),
    );
    blank();
  }

  void tableHeader(List<String> columns) {
    final style = StatisticsExportService._xlsTableHeaderStyle();
    for (var i = 0; i < columns.length; i++) {
      cell(i, TextCellValue(columns[i]), style: style);
    }
    blank();
  }

  void modulePerformanceRow({
    required Color moduleColor,
    required String label,
    required double score,
    required String hint,
    required String summary,
    required bool zebra,
  }) {
    final data = StatisticsExportService._xlsDataStyle(zebra: zebra);
    cell(0, TextCellValue('●'), style: StatisticsExportService._xlsAccentDotStyle(moduleColor));
    cell(1, TextCellValue(label), style: StatisticsExportService._xlsModuleNameStyle(moduleColor, zebra: zebra));
    cell(2, DoubleCellValue(score), style: StatisticsExportService._xlsScoreStyle(zebra: zebra));
    cell(3, TextCellValue(hint), style: data);
    cell(4, TextCellValue(summary), style: data);
    cell(5, TextCellValue(''), style: data);
    blank();
  }

  void moduleSummaryRow({
    required Color moduleColor,
    required String title,
    required String headline,
    required String subtitle,
    required bool zebra,
  }) {
    final data = StatisticsExportService._xlsDataStyle(zebra: zebra);
    cell(0, TextCellValue('●'), style: StatisticsExportService._xlsAccentDotStyle(moduleColor));
    cell(1, TextCellValue(title), style: StatisticsExportService._xlsModuleNameStyle(moduleColor, zebra: zebra));
    cell(2, TextCellValue(headline), style: data.copyWith(boldVal: true));
    cell(3, TextCellValue(subtitle), style: data);
    cell(4, TextCellValue(''), style: data);
    cell(5, TextCellValue(''), style: data);
    blank();
  }

  void moduleSectionTitle(
    String title, {
    String? headline,
    required Color moduleColor,
    required int colspan,
  }) {
    _mergeRow(colspan);
    final text = headline != null ? '$title · $headline' : title;
    final style = StatisticsExportService._xlsModuleSectionStyle(moduleColor);
    cell(0, TextCellValue(text), style: style);
    sheet.setMergedCellStyle(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      style,
    );
    blank();
  }

  void metricRow({
    required Color moduleColor,
    required String label,
    required String value,
    required bool zebra,
  }) {
    final data = StatisticsExportService._xlsDataStyle(zebra: zebra);
    cell(0, TextCellValue('●'), style: StatisticsExportService._xlsAccentDotStyle(moduleColor));
    cell(1, TextCellValue(label), style: data);
    cell(2, TextCellValue(value), style: data.copyWith(boldVal: true));
    blank();
  }

  void pieSectionHeader(Color moduleColor) {
    _mergeRow(3);
    final style = StatisticsExportService._xlsPieCaptionStyle(moduleColor);
    cell(0, TextCellValue('Dağılım (%)'), style: style);
    sheet.setMergedCellStyle(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      style,
    );
    blank();
  }

  void pieRow({
    required Color moduleColor,
    required String label,
    required double percent,
    required bool zebra,
  }) {
    final data = StatisticsExportService._xlsDataStyle(zebra: zebra);
    cell(0, TextCellValue('●'), style: StatisticsExportService._xlsAccentDotStyle(moduleColor));
    cell(1, TextCellValue(label), style: data);
    cell(
      2,
      DoubleCellValue(percent),
      style: StatisticsExportService._xlsScoreStyle(zebra: zebra).copyWith(
        numberFormat: NumFormat.standard_10,
      ),
    );
    blank();
  }
}

class _ExportSection {
  final String title;
  final Color moduleColor;
  final List<StatMetric> metrics;
  final Map<String, double> pie;
  final String? headline;
  final String? subtitle;

  const _ExportSection(
    this.title,
    this.moduleColor,
    this.metrics,
    this.pie,
    this.headline,
    this.subtitle,
  );
}
