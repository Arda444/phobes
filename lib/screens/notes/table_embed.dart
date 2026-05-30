import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_form_wrapper.dart';
import 'embed_utils.dart';

// ─────────────────────────────── Enums ───────────────────────────────────────

enum TableTheme { classic, ocean, forest, rose, sunset, midnight, coffee, slate }

enum TableAlignment { left, center, fullWidth }

enum TableDensity { compact, normal, comfortable }

// ─────────────────────────── Theme Specs ─────────────────────────────────────

class TableThemeSpec {
  final String name;
  final Color headerBg;
  final Color headerText;
  final Color stripeBg;
  final Color cellBg;
  final Color outerBorder;
  final Color innerBorder;
  final Color dot;

  const TableThemeSpec({
    required this.name,
    required this.headerBg,
    required this.headerText,
    required this.stripeBg,
    required this.cellBg,
    required this.outerBorder,
    required this.innerBorder,
    required this.dot,
  });
}

const Map<TableTheme, TableThemeSpec> _kSpecs = {
  TableTheme.classic: TableThemeSpec(
    name: 'Klasik',
    headerBg: Color(0xFFF1F3F4),
    headerText: Color(0xFF1A1A1A),
    stripeBg: Color(0xFFF8FAFC),
    cellBg: Color(0xFFFFFFFF),
    outerBorder: Color(0xFFE2E8F0),
    innerBorder: Color(0xFFF1F5F9),
    dot: Color(0xFF64748B),
  ),
  TableTheme.ocean: TableThemeSpec(
    name: 'Okyanus',
    headerBg: Color(0xFF1E3A5F),
    headerText: Color(0xFFFFFFFF),
    stripeBg: Color(0xFFEFF6FF),
    cellBg: Color(0xFFFFFFFF),
    outerBorder: Color(0xFFBFDBFE),
    innerBorder: Color(0xFFDBEAFE),
    dot: Color(0xFF2563EB),
  ),
  TableTheme.forest: TableThemeSpec(
    name: 'Orman',
    headerBg: Color(0xFF14532D),
    headerText: Color(0xFFFFFFFF),
    stripeBg: Color(0xFFF0FDF4),
    cellBg: Color(0xFFFFFFFF),
    outerBorder: Color(0xFFBBF7D0),
    innerBorder: Color(0xFFDCFCE7),
    dot: Color(0xFF16A34A),
  ),
  TableTheme.rose: TableThemeSpec(
    name: 'Gül',
    headerBg: Color(0xFF881337),
    headerText: Color(0xFFFFFFFF),
    stripeBg: Color(0xFFFFF1F2),
    cellBg: Color(0xFFFFFFFF),
    outerBorder: Color(0xFFFECDD3),
    innerBorder: Color(0xFFFFE4E6),
    dot: Color(0xFFE11D48),
  ),
  TableTheme.sunset: TableThemeSpec(
    name: 'Gün Batımı',
    headerBg: Color(0xFF9A3412),
    headerText: Color(0xFFFFFFFF),
    stripeBg: Color(0xFFFFF7ED),
    cellBg: Color(0xFFFFFFFF),
    outerBorder: Color(0xFFFDBA74),
    innerBorder: Color(0xFFFED7AA),
    dot: Color(0xFFEA580C),
  ),
  TableTheme.midnight: TableThemeSpec(
    name: 'Gece',
    headerBg: Color(0xFF1E1B4B),
    headerText: Color(0xFFFFFFFF),
    stripeBg: Color(0xFFEEF2FF),
    cellBg: Color(0xFFFFFFFF),
    outerBorder: Color(0xFFC7D2FE),
    innerBorder: Color(0xFFE0E7FF),
    dot: Color(0xFF4F46E5),
  ),
  TableTheme.coffee: TableThemeSpec(
    name: 'Kahve',
    headerBg: Color(0xFF431407),
    headerText: Color(0xFFFFFFFF),
    stripeBg: Color(0xFFFEF3C7),
    cellBg: Color(0xFFFFFFFF),
    outerBorder: Color(0xFFFDE68A),
    innerBorder: Color(0xFFFEF9C3),
    dot: Color(0xFFD97706),
  ),
  TableTheme.slate: TableThemeSpec(
    name: 'Çelik',
    headerBg: Color(0xFF1E293B),
    headerText: Color(0xFFFFFFFF),
    stripeBg: Color(0xFFF8FAFC),
    cellBg: Color(0xFFFFFFFF),
    outerBorder: Color(0xFFCBD5E1),
    innerBorder: Color(0xFFE2E8F0),
    dot: Color(0xFF475569),
  ),
};

TableThemeSpec specOf(TableTheme t) => _kSpecs[t]!;

String tableThemeDisplayName(TableTheme theme, AppLocalizations l10n) {
  switch (theme) {
    case TableTheme.classic:
      return l10n.noteTableThemeClassic;
    case TableTheme.ocean:
      return l10n.noteTableThemeOcean;
    case TableTheme.forest:
      return l10n.noteTableThemeForest;
    case TableTheme.rose:
      return l10n.noteTableThemeRose;
    case TableTheme.sunset:
      return l10n.noteTableThemeSunset;
    case TableTheme.midnight:
      return l10n.noteTableThemeMidnight;
    case TableTheme.coffee:
      return l10n.noteTableThemeCoffee;
    case TableTheme.slate:
      return l10n.noteTableThemeSlate;
  }
}

// ──────────────────────────── TableData ──────────────────────────────────────

class TableData {
  final int rows;
  final int cols;
  final List<List<String>> cells;
  final TableTheme theme;
  final TableAlignment alignment;
  final TableDensity density;
  final bool hasHeaderRow;
  final bool hasHeaderCol;
  final List<List<int?>> cellColors;

  TableData({
    required this.rows,
    required this.cols,
    required this.cells,
    this.theme = TableTheme.classic,
    this.alignment = TableAlignment.fullWidth,
    this.density = TableDensity.normal,
    this.hasHeaderRow = true,
    this.hasHeaderCol = false,
    List<List<int?>>? cellColors,
  }) : cellColors =
            cellColors ?? List.generate(rows, (_) => List.filled(cols, null));

  factory TableData.empty(int rows, int cols,
      {TableTheme theme = TableTheme.classic}) {
    return TableData(
      rows: rows,
      cols: cols,
      cells: List.generate(rows, (_) => List.generate(cols, (_) => '')),
      theme: theme,
    );
  }

  Map<String, dynamic> toJson() => {
        'rows': rows,
        'cols': cols,
        'cells': cells,
        'theme': theme.name,
        'alignment': alignment.name,
        'density': density.name,
        'hasHeaderRow': hasHeaderRow,
        'hasHeaderCol': hasHeaderCol,
        'cellColors': cellColors,
      };

  factory TableData.fromJson(Map<String, dynamic> json) {
    final rows = (json['rows'] as int?) ?? 3;
    final cols = (json['cols'] as int?) ?? 3;

    final cellsRaw = (json['cells'] as List<dynamic>?) ?? [];
    final cells = cellsRaw
        .map((row) =>
            (row as List<dynamic>).map((c) => c.toString()).toList())
        .toList();

    // Support both new 'theme' field and old 'style' field.
    TableTheme theme = TableTheme.classic;
    final themeStr = json['theme'] as String?;
    final styleStr = json['style'] as String?;
    if (themeStr != null) {
      theme = TableTheme.values.firstWhere(
        (e) => e.name == themeStr,
        orElse: () => TableTheme.classic,
      );
    } else if (styleStr != null) {
      theme = switch (styleStr) {
        'darkHeader' => TableTheme.midnight,
        'striped' => TableTheme.slate,
        'colorful' => TableTheme.sunset,
        _ => TableTheme.classic,
      };
    }

    TableAlignment alignment = TableAlignment.fullWidth;
    final alignStr = json['alignment'] as String?;
    if (alignStr != null) {
      alignment = TableAlignment.values.firstWhere(
        (e) => e.name == alignStr,
        orElse: () => TableAlignment.fullWidth,
      );
    }

    TableDensity density = TableDensity.normal;
    final densityStr = json['density'] as String?;
    if (densityStr != null) {
      density = TableDensity.values.firstWhere(
        (e) => e.name == densityStr,
        orElse: () => TableDensity.normal,
      );
    }

    List<List<int?>> cellColors;
    final rawColors = json['cellColors'];
    if (rawColors is List) {
      cellColors = rawColors
          .map((row) => (row as List).map((v) => v as int?).toList())
          .toList();
    } else {
      cellColors = List.generate(rows, (_) => List.filled(cols, null));
    }

    return TableData(
      rows: rows,
      cols: cols,
      cells: cells,
      theme: theme,
      alignment: alignment,
      density: density,
      hasHeaderRow: json['hasHeaderRow'] as bool? ?? true,
      hasHeaderCol: json['hasHeaderCol'] as bool? ?? false,
      cellColors: cellColors,
    );
  }

  TableData copyWith({
    int? rows,
    int? cols,
    List<List<String>>? cells,
    TableTheme? theme,
    TableAlignment? alignment,
    TableDensity? density,
    bool? hasHeaderRow,
    bool? hasHeaderCol,
    List<List<int?>>? cellColors,
  }) {
    return TableData(
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      cells: cells ?? this.cells,
      theme: theme ?? this.theme,
      alignment: alignment ?? this.alignment,
      density: density ?? this.density,
      hasHeaderRow: hasHeaderRow ?? this.hasHeaderRow,
      hasHeaderCol: hasHeaderCol ?? this.hasHeaderCol,
      cellColors: cellColors ?? this.cellColors,
    );
  }

  TableData addRow() {
    final newCells =
        cells.map((r) => List<String>.from(r)).toList()
          ..add(List.generate(cols, (_) => ''));
    final newColors =
        cellColors.map((r) => List<int?>.from(r)).toList()
          ..add(List.filled(cols, null));
    return copyWith(rows: rows + 1, cells: newCells, cellColors: newColors);
  }

  TableData addColumn() {
    final newCells = cells.map((r) => [...r, '']).toList();
    final newColors = cellColors.map((r) => [...r, null]).toList();
    return copyWith(cols: cols + 1, cells: newCells, cellColors: newColors);
  }

  TableData removeRow(int index) {
    if (rows <= 1) return this;
    final newCells =
        cells.map((r) => List<String>.from(r)).toList()..removeAt(index);
    final newColors =
        cellColors.map((r) => List<int?>.from(r)).toList()..removeAt(index);
    return copyWith(rows: rows - 1, cells: newCells, cellColors: newColors);
  }

  TableData removeColumn(int index) {
    if (cols <= 1) return this;
    final newCells = cells.map((r) {
      final copy = List<String>.from(r)..removeAt(index);
      return copy;
    }).toList();
    final newColors = cellColors.map((r) {
      final copy = List<int?>.from(r)..removeAt(index);
      return copy;
    }).toList();
    return copyWith(cols: cols - 1, cells: newCells, cellColors: newColors);
  }

  TableData updateCell(int row, int col, String value) {
    final newCells = cells.map((r) => List<String>.from(r)).toList();
    newCells[row][col] = value;
    return copyWith(cells: newCells);
  }
}

// ─────────────────────── TableBlockEmbed ─────────────────────────────────────

class TableBlockEmbed extends CustomBlockEmbed {
  const TableBlockEmbed(String value) : super(tableType, value);
  static const String tableType = 'table';

  static TableBlockEmbed fromDocument(Document document) =>
      TableBlockEmbed(jsonEncode(document.toDelta().toJson()));

  Document get document =>
      Document.fromJson(jsonDecode(data) as List<dynamic>);

  static TableBlockEmbed fromTableData(TableData tableData) =>
      TableBlockEmbed(jsonEncode(tableData.toJson()));

  TableData get tableData => TableData.fromJson(jsonDecode(data));
}

// ─────────────────────── TableEmbedBuilder ───────────────────────────────────

class TableEmbedBuilder extends EmbedBuilder {
  final Function(TableData)? onTableUpdated;

  TableEmbedBuilder({this.onTableUpdated});

  @override
  String get key => TableBlockEmbed.tableType;

  @override
  bool get expanded => true;

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    final TableData tableData;
    try {
      tableData = TableData.fromJson(jsonDecode(node.value.data));
    } catch (_) {
      return embedError(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: _TableWidget(
        data: tableData,
        readOnly: readOnly,
        onUpdate: (updatedData) {
          if (readOnly) return;
          final result =
              getCustomEmbedNode(controller, controller.selection.start);
          if (result != null) {
            controller.replaceText(
              result.offset,
              1,
              TableBlockEmbed.fromTableData(updatedData),
              null,
            );
          }
          onTableUpdated?.call(updatedData);
        },
      ),
    );
  }
}

// ─────────────────────── _TableWidget ────────────────────────────────────────

class _TableWidget extends StatefulWidget {
  final TableData data;
  final bool readOnly;
  final ValueChanged<TableData> onUpdate;

  const _TableWidget({
    required this.data,
    required this.readOnly,
    required this.onUpdate,
  });

  @override
  State<_TableWidget> createState() => _TableWidgetState();
}

class _TableWidgetState extends State<_TableWidget> {
  late TableData _data;
  bool _showToolbar = false;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
  }

  @override
  void didUpdateWidget(_TableWidget old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) _data = widget.data;
  }

  void _update(TableData newData) {
    setState(() => _data = newData);
    widget.onUpdate(newData);
  }

  @override
  Widget build(BuildContext context) {
    final spec = specOf(_data.theme);

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toolbar trigger (edit mode only)
        if (!widget.readOnly) _buildTrigger(spec),

        // Collapsible toolbar
        if (!widget.readOnly)
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: _showToolbar
                ? _buildToolbar(spec)
                : const SizedBox.shrink(),
          ),

        // Table itself
        _buildTableContainer(spec),
      ],
    );

    return _wrapAlignment(content);
  }

  // ── Toolbar trigger pill ──────────────────────────────────────────────────

  Widget _buildTrigger(TableThemeSpec spec) {
    final l10n = AppLocalizations.of(context)!;
    final themeName = tableThemeDisplayName(_data.theme, l10n);
    return GestureDetector(
      onTap: () => setState(() => _showToolbar = !_showToolbar),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: spec.headerBg.withOpacity(0.09),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: spec.dot.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration:
                  BoxDecoration(color: spec.headerBg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              themeName,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: spec.headerBg,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              _showToolbar
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: spec.dot.withOpacity(0.55),
            ),
          ],
        ),
      ),
    );
  }

  // ── Toolbar ───────────────────────────────────────────────────────────────

  Widget _buildToolbar(TableThemeSpec spec) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE9ECF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Theme dots ──────────────────────────────────────────────────
            ...TableTheme.values.map(
              (t) => _ThemeDot(
                theme: t,
                selected: _data.theme == t,
                onTap: () => _update(_data.copyWith(theme: t)),
              ),
            ),
            _vSep(),

            // ── Alignment ───────────────────────────────────────────────────
            _TbBtn(
              icon: Icons.format_align_left_rounded,
              tooltip: l10n.noteTableAlignLeft,
              active: _data.alignment == TableAlignment.left,
              onTap: () =>
                  _update(_data.copyWith(alignment: TableAlignment.left)),
            ),
            const SizedBox(width: 2),
            _TbBtn(
              icon: Icons.format_align_center_rounded,
              tooltip: l10n.noteTableAlignCenter,
              active: _data.alignment == TableAlignment.center,
              onTap: () =>
                  _update(_data.copyWith(alignment: TableAlignment.center)),
            ),
            const SizedBox(width: 2),
            _TbBtn(
              icon: Icons.swap_horiz_rounded,
              tooltip: l10n.noteTableAlignFullWidth,
              active: _data.alignment == TableAlignment.fullWidth,
              onTap: () =>
                  _update(_data.copyWith(alignment: TableAlignment.fullWidth)),
            ),
            _vSep(),

            // ── Density ──────────────────────────────────────────────────────
            _DensBtn(
              label: 'S',
              tooltip: l10n.noteTableDensityCompact,
              active: _data.density == TableDensity.compact,
              onTap: () =>
                  _update(_data.copyWith(density: TableDensity.compact)),
            ),
            const SizedBox(width: 2),
            _DensBtn(
              label: 'M',
              tooltip: l10n.noteTableDensityNormal,
              active: _data.density == TableDensity.normal,
              onTap: () =>
                  _update(_data.copyWith(density: TableDensity.normal)),
            ),
            const SizedBox(width: 2),
            _DensBtn(
              label: 'L',
              tooltip: l10n.noteTableDensityComfortable,
              active: _data.density == TableDensity.comfortable,
              onTap: () =>
                  _update(_data.copyWith(density: TableDensity.comfortable)),
            ),
            _vSep(),

            // ── Header toggles ────────────────────────────────────────────────
            _TbBtn(
              icon: Icons.view_headline_rounded,
              tooltip: l10n.noteTableHeaderRowTooltip,
              active: _data.hasHeaderRow,
              label: l10n.noteTableHeaderRowShort,
              onTap: () =>
                  _update(_data.copyWith(hasHeaderRow: !_data.hasHeaderRow)),
            ),
            const SizedBox(width: 3),
            _TbBtn(
              icon: Icons.view_week_outlined,
              tooltip: l10n.noteTableHeaderColTooltip,
              active: _data.hasHeaderCol,
              label: l10n.noteTableHeaderColShort,
              onTap: () =>
                  _update(_data.copyWith(hasHeaderCol: !_data.hasHeaderCol)),
            ),
            _vSep(),

            // ── Rows / Cols ───────────────────────────────────────────────────
            _TbTextBtn(
              icon: Icons.add_rounded,
              label: l10n.noteTableAddRow,
              onTap: () => _update(_data.addRow()),
            ),
            const SizedBox(width: 3),
            _TbTextBtn(
              icon: Icons.add_rounded,
              label: l10n.noteTableAddColumn,
              onTap: () => _update(_data.addColumn()),
            ),
            _vSep(),

            // ── Delete ────────────────────────────────────────────────────────
            _TbTextBtn(
              icon: Icons.delete_outline_rounded,
              label: AppLocalizations.of(context)!.delete,
              danger: true,
              onTap: _confirmDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _vSep() => Container(
        width: 1,
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 7),
        color: const Color(0xFFDDE1E7),
      );

  // ── Table container ───────────────────────────────────────────────────────

  Widget _buildTableContainer(TableThemeSpec spec) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: spec.outerBorder, width: 1.2),
        color: spec.cellBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _buildTable(spec),
      ),
    );
  }

  Widget _buildTable(TableThemeSpec spec) {
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: TableBorder(
        verticalInside: BorderSide(color: spec.innerBorder),
        horizontalInside: BorderSide(color: spec.innerBorder),
      ),
      children: List.generate(_data.rows, (row) {
        final isHeaderRow = _data.hasHeaderRow && row == 0;
        final isStripe = !isHeaderRow && row % 2 == 0;

        final rowBg = isHeaderRow
            ? spec.headerBg
            : isStripe
                ? spec.stripeBg
                : spec.cellBg;

        return TableRow(
          decoration: BoxDecoration(color: rowBg),
          children: List.generate(
            _data.cols,
            (col) {
              final isHeaderCol = _data.hasHeaderCol && col == 0;
              return _buildCell(row, col, isHeaderRow, isHeaderCol, spec);
            },
          ),
        );
      }),
    );
  }

  Widget _buildCell(
    int row,
    int col,
    bool isHeaderRow,
    bool isHeaderCol,
    TableThemeSpec spec,
  ) {
    final text = _data.cells[row][col];

    final colorVal =
        _data.cellColors.length > row && _data.cellColors[row].length > col
            ? _data.cellColors[row][col]
            : null;

    final (padH, padV, fontSize, minH) = switch (_data.density) {
      TableDensity.compact => (8.0, 5.0, 11.0, 26.0),
      TableDensity.normal => (12.0, 9.0, 12.5, 34.0),
      TableDensity.comfortable => (16.0, 13.0, 13.5, 46.0),
    };

    final isHeader = isHeaderRow || isHeaderCol;
    final textColor = isHeaderRow
        ? spec.headerText
        : isHeaderCol
            ? spec.headerBg
            : const Color(0xFF1A1A1A);

    final l10n = AppLocalizations.of(context)!;
    final placeholder = isHeaderRow && text.isEmpty && !widget.readOnly
        ? (col == 0
            ? l10n.noteTableHeaderPlaceholder
            : l10n.noteTableHeaderPlaceholderN(col + 1))
        : '...';

    return GestureDetector(
      onTap: widget.readOnly ? null : () => _editCell(row, col, spec),
      child: Container(
        color: colorVal != null ? Color(colorVal).withOpacity(0.55) : null,
        constraints: BoxConstraints(minHeight: minH),
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        child: text.isEmpty && !widget.readOnly
            ? Text(
                placeholder,
                style: GoogleFonts.outfit(
                  fontSize: fontSize,
                  fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
                  color: textColor.withOpacity(isHeaderRow ? 0.35 : 0.22),
                  fontStyle: FontStyle.italic,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.outfit(
                  fontSize: fontSize,
                  fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
                  color: textColor,
                  height: 1.45,
                ),
              ),
      ),
    );
  }

  // ── Alignment wrapper ─────────────────────────────────────────────────────

  Widget _wrapAlignment(Widget child) {
    switch (_data.alignment) {
      case TableAlignment.fullWidth:
        return LayoutBuilder(builder: (ctx, constraints) {
          final w = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(ctx).size.width;
          return SizedBox(width: w, child: child);
        });
      case TableAlignment.center:
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: child,
          ),
        );
      case TableAlignment.left:
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: child,
        );
    }
  }

  // ── Cell editor dialog ────────────────────────────────────────────────────

  void _editCell(int row, int col, TableThemeSpec spec) {
    final ctrl = TextEditingController(text: _data.cells[row][col]);
    int? selectedColor =
        _data.cellColors.length > row && _data.cellColors[row].length > col
            ? _data.cellColors[row][col]
            : null;

    const palette = <int?>[
      null,
      0xFFFFE4E6,
      0xFFFFF9C4,
      0xFFDCFCE7,
      0xFFDBEAFE,
      0xFFEDE9FE,
      0xFFFED7AA,
      0xFFCCFBF1,
      0xFFFCE7F3,
      0xFFF1F5F9,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final cs = Theme.of(ctx).colorScheme;
          final dlgL10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            backgroundColor: cs.surface,
            titlePadding:
                const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding:
                const EdgeInsets.fromLTRB(20, 16, 20, 0),
            actionsPadding:
                const EdgeInsets.fromLTRB(16, 8, 16, 16),
            title: Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: spec.headerBg, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                dlgL10n.noteTableCellPosition(row + 1, col + 1),
                style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  maxLines: 4,
                  minLines: 1,
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.noteTableCellHint,
                    hintStyle: GoogleFonts.outfit(
                        fontSize: 14,
                        color: cs.onSurface.withOpacity(0.3)),
                    filled: true,
                    fillColor: cs.surfaceVariant.withOpacity(0.25),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  dlgL10n.noteTableCellBackground,
                  style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withOpacity(0.38),
                      letterSpacing: 0.8),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: palette.map((c) {
                    final sel = c == selectedColor;
                    return GestureDetector(
                      onTap: () => setDlg(() => selectedColor = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 130),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c != null ? Color(c) : Colors.white,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: sel
                                ? cs.primary
                                : cs.outline.withOpacity(0.2),
                            width: sel ? 2 : 1,
                          ),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                      color:
                                          cs.primary.withOpacity(0.18),
                                      blurRadius: 4)
                                ]
                              : null,
                        ),
                        child: c == null
                            ? Icon(Icons.block_rounded,
                                size: 13,
                                color: cs.outline.withOpacity(0.4))
                            : sel
                                ? Icon(Icons.check_rounded,
                                    size: 13,
                                    color:
                                        Colors.black.withOpacity(0.5))
                                : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(ctx)!.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: spec.dot,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9))),
                onPressed: () {
                  var updated = _data.updateCell(row, col, ctrl.text);
                  final newColors = updated.cellColors
                      .map((r) => List<int?>.from(r))
                      .toList();
                  if (newColors.length > row &&
                      newColors[row].length > col) {
                    newColors[row][col] = selectedColor;
                  }
                  updated = updated.copyWith(cellColors: newColors);
                  _update(updated);
                  Navigator.pop(ctx);
                },
                child: Text(AppLocalizations.of(ctx)!.ok),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Delete confirm ────────────────────────────────────────────────────────

  void _confirmDelete() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.noteTableDeleteTitle,
            style:
                GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(AppLocalizations.of(context)!.noteTableDeleteBody,
            style: GoogleFonts.outfit(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(ctx)!.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: cs.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onUpdate(TableData.empty(0, 0));
            },
            child: Text(AppLocalizations.of(ctx)!.delete),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Toolbar sub-widgets ─────────────────────────────────

class _ThemeDot extends StatelessWidget {
  final TableTheme theme;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeDot(
      {required this.theme, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final spec = specOf(theme);
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tableThemeDisplayName(theme, l10n),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: selected ? 22 : 17,
          height: selected ? 22 : 17,
          decoration: BoxDecoration(
            color: spec.headerBg,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(color: spec.dot, width: 2.5)
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: spec.headerBg.withOpacity(0.45),
                        blurRadius: 7,
                        spreadRadius: 1)
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class _TbBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final String? label;
  final VoidCallback onTap;

  const _TbBtn({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = active ? cs.primary : const Color(0xFF6B7280);
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: label != null ? 7 : 5, vertical: 4),
          decoration: BoxDecoration(
            color: active ? cs.primary.withOpacity(0.11) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: active
                ? Border.all(color: cs.primary.withOpacity(0.25))
                : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: color),
            if (label != null) ...[
              const SizedBox(width: 3),
              Text(label!,
                  style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      color: color)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _DensBtn extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _DensBtn({
    required this.label,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? cs.primary.withOpacity(0.11)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight:
                  active ? FontWeight.w800 : FontWeight.w500,
              color: active ? cs.primary : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

class _TbTextBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _TbTextBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = danger
        ? Theme.of(context).colorScheme.error
        : const Color(0xFF374151);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: danger
              ? baseColor.withOpacity(0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 13, color: baseColor.withOpacity(0.75)),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: baseColor.withOpacity(0.75)),
          ),
        ]),
      ),
    );
  }
}

// ──────────────────── Insert Table Dialog ────────────────────────────────────

Future<TableData?> showInsertTableDialog(BuildContext context) {
  int rows = 3;
  int cols = 3;
  TableTheme selectedTheme = TableTheme.ocean;

  return PhobesFormWrapper.show<TableData>(
    context,
    title: AppLocalizations.of(context)!.noteTableCreate,
    panelWidth: 420,
    form: StatefulBuilder(
      builder: (ctx, setState) {
        final cs = Theme.of(ctx).colorScheme;
        final dlgL10n = AppLocalizations.of(ctx)!;
        final spec = specOf(selectedTheme);
        final bottomPad = MediaQuery.of(ctx).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, bottomPad + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dlgL10n.noteTableChooseThemeSize,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: cs.onSurface.withOpacity(0.45),
                ),
              ),
              const SizedBox(height: 20),

              // ── Theme label ────────────────────────────────────────────
                _sectionLabel(dlgL10n.noteTableSectionTheme, cs),
                const SizedBox(height: 10),

                // ── Theme grid (2×4) ───────────────────────────────────────
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: TableTheme.values.length,
                  itemBuilder: (_, i) {
                    final t = TableTheme.values[i];
                    final s = specOf(t);
                    final sel = selectedTheme == t;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => selectedTheme = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: sel
                                ? s.dot
                                : cs.outline.withOpacity(0.18),
                            width: sel ? 2.2 : 1,
                          ),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                      color:
                                          s.dot.withOpacity(0.18),
                                      blurRadius: 8)
                                ]
                              : null,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(children: [
                          // Mini header row
                          Container(
                            height: 26,
                            color: s.headerBg,
                            alignment: Alignment.center,
                            child: Text(
                              tableThemeDisplayName(t, dlgL10n),
                              style: GoogleFonts.outfit(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: s.headerText,
                              ),
                            ),
                          ),
                          // Mini body rows
                          Expanded(
                            child: Container(
                              color: s.cellBg,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 3),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _miniRow(s.stripeBg,
                                      s.innerBorder),
                                  _miniRow(s.cellBg,
                                      s.innerBorder),
                                ],
                              ),
                            ),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),

                // ── Size label ─────────────────────────────────────────────
                _sectionLabel(dlgL10n.noteTableSectionSize, cs),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(
                    child: _StepperField(
                      label: dlgL10n.noteTableRowLabel,
                      value: rows,
                      min: 1,
                      max: 15,
                      onChanged: (v) => setState(() => rows = v),
                      cs: cs,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StepperField(
                      label: dlgL10n.noteTableColLabel,
                      value: cols,
                      min: 1,
                      max: 8,
                      onChanged: (v) => setState(() => cols = v),
                      cs: cs,
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Preview ────────────────────────────────────────────────
                _sectionLabel(dlgL10n.noteTableSectionPreview, cs),
                const SizedBox(height: 8),
                _TablePreview(
                    rows: rows, cols: cols, theme: selectedTheme),
                const SizedBox(height: 22),

                // ── Actions ────────────────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                            color: cs.outline.withOpacity(0.3)),
                      ),
                      child: Text(dlgL10n.cancel,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        ctx,
                        TableData.empty(rows, cols, theme: selectedTheme),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: spec.dot,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_rounded, size: 17),
                          const SizedBox(width: 7),
                          Text(dlgL10n.noteTableCreate,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ]),
            ],
          ),
        );
      },
    ),
  );
}

Widget _sectionLabel(String text, ColorScheme cs) => Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: cs.onSurface.withOpacity(0.38),
        letterSpacing: 0.9,
      ),
    );

Widget _miniRow(Color bg, Color border) => Container(
      height: 7,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: border, width: 0.5),
      ),
    );

// ──────────────────── Table Preview ──────────────────────────────────────────

class _TablePreview extends StatelessWidget {
  final int rows;
  final int cols;
  final TableTheme theme;

  const _TablePreview(
      {required this.rows, required this.cols, required this.theme});

  @override
  Widget build(BuildContext context) {
    final spec = specOf(theme);
    final dr = rows.clamp(1, 5);
    final dc = cols.clamp(1, 6);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: spec.outerBorder, width: 1.2),
        color: spec.cellBg,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(dr, (r) {
          final isHeader = r == 0;
          final isStripe = !isHeader && r % 2 == 0;
          final rowBg = isHeader
              ? spec.headerBg
              : isStripe
                  ? spec.stripeBg
                  : spec.cellBg;
          return Container(
            color: r > 0
                ? null
                : null, // border handled below
            decoration: r > 0
                ? BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: spec.innerBorder)),
                    color: rowBg,
                  )
                : BoxDecoration(color: rowBg),
            child: Row(
              children: List.generate(dc, (c) {
                return Expanded(
                  child: Container(
                    height: isHeader ? 22 : 16,
                    decoration: BoxDecoration(
                      border: c > 0
                          ? Border(
                              left: BorderSide(
                                  color: spec.innerBorder))
                          : null,
                    ),
                    alignment: Alignment.centerLeft,
                    padding:
                        const EdgeInsets.only(left: 5),
                    child: isHeader
                        ? Container(
                            width: 28,
                            height: 6,
                            decoration: BoxDecoration(
                              color:
                                  spec.headerText.withOpacity(0.35),
                              borderRadius:
                                  BorderRadius.circular(3),
                            ),
                          )
                        : Container(
                            width: c == 0 ? 32 : 20,
                            height: 4,
                            decoration: BoxDecoration(
                              color: spec.dot.withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(2),
                            ),
                          ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

// ──────────────────── Stepper Field ──────────────────────────────────────────

class _StepperField extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final ColorScheme cs;

  const _StepperField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.5))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outline.withOpacity(0.18)),
            color: cs.surfaceVariant.withOpacity(0.2),
          ),
          child: Row(children: [
            _stepBtn(Icons.remove_rounded,
                value > min ? () => onChanged(value - 1) : null, cs),
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            _stepBtn(Icons.add_rounded,
                value < max ? () => onChanged(value + 1) : null, cs),
          ]),
        ),
      ],
    );
  }
}

Widget _stepBtn(
    IconData icon, VoidCallback? onTap, ColorScheme cs) {
  return GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Icon(
        icon,
        size: 17,
        color: onTap != null
            ? cs.primary
            : cs.onSurface.withOpacity(0.2),
      ),
    ),
  );
}
