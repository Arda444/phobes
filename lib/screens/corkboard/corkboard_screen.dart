import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/module_info_catalog.dart';
import '../../core/phobes_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/corkboard_board_model.dart';
import '../../models/corkboard_connection_model.dart';
import '../../models/corkboard_item_model.dart';
import '../../services/corkboard_service.dart';
import '../../widgets/phobes_module_header.dart';
import '../../widgets/phobes_widgets.dart';
import 'corkboard_constants.dart';
import 'corkboard_link_geometry.dart';
import 'widgets/cork_item_widget.dart';

/// Connection line style for the planning board.
class LinkStyle {
  final int value;
  final String label;
  final IconData icon;
  const LinkStyle(this.value, this.label, this.icon);
}

List<LinkStyle> corkboardLinkStyles(AppLocalizations l10n) => [
      LinkStyle(0xFF5C6BC0, l10n.corkboardLinkRelated, Icons.link_rounded),
      LinkStyle(
        0xFFFFB74D,
        l10n.corkboardLinkNext,
        Icons.arrow_forward_rounded,
      ),
      LinkStyle(
        0xFFAB47BC,
        l10n.corkboardLinkDepends,
        Icons.account_tree_outlined,
      ),
      LinkStyle(
        0xFF66BB6A,
        l10n.corkboardLinkIdea,
        Icons.lightbulb_outline_rounded,
      ),
      LinkStyle(0xFFEF5350, l10n.corkboardLinkImportant, Icons.flag_outlined),
      LinkStyle(
        0xFF90A4AE,
        l10n.corkboardLinkReference,
        Icons.bookmark_outline_rounded,
      ),
    ];

class CorkboardScreen extends StatefulWidget {
  final String? teamId;
  const CorkboardScreen({super.key, this.teamId});

  @override
  State<CorkboardScreen> createState() => _CorkboardScreenState();
}

class _CorkboardScreenState extends State<CorkboardScreen> {
  final CorkboardService _svc = CorkboardService();
  final TransformationController _tfCtrl = TransformationController();

  bool _connecting = false;
  String? _firstId;
  String? _boardId;
  int? _linkColor;
  int _paperColor = kPaperTones.first.base;
  final Map<String, Offset> _dragPositions = {};
  String? _frontItemId;
  String? _highlightConnectionId;

  bool _toolsOpen = false;
  bool _canManageTeamBoards = true;
  Size? _viewportSize;
  bool _needsFitView = true;
  String? _lastFitBoardId;
  double _viewScale = 1.0;

  static const double _kMinZoom = 0.04;
  static const double _kMaxZoom = 4.0;

  @override
  void initState() {
    super.initState();
    _tfCtrl.addListener(_onTransformChanged);
    _loadTeamBoardPermission();
  }

  Future<void> _loadTeamBoardPermission() async {
    final teamId = widget.teamId;
    if (teamId == null) return;
    final uid = _svc.currentUserId;
    if (uid == null) {
      if (mounted) setState(() => _canManageTeamBoards = false);
      return;
    }
    final doc =
        await FirebaseFirestore.instance.collection('teams').doc(teamId).get();
    if (!mounted || !doc.exists) return;
    final data = doc.data()!;
    final adminIds = List<String>.from(data['adminIds'] ?? []);
    final isAdmin = data['ownerId'] == uid || adminIds.contains(uid);
    setState(() => _canManageTeamBoards = isAdmin);
  }

  void _onTransformChanged() {
    final s = _tfCtrl.value.getMaxScaleOnAxis();
    if (s > 0 && (s - _viewScale).abs() > 0.0005) {
      _viewScale = s;
    }
  }

  String? _activeBoardId(List<CorkboardBoard> boards) {
    if (boards.isEmpty) return null;
    if (_boardId != null && boards.any((b) => b.id == _boardId)) {
      return _boardId;
    }
    return boards.first.id;
  }

  @override
  void dispose() {
    _tfCtrl.dispose();
    super.dispose();
  }

  /// Scale so the full board fits in the visible canvas (with small margin).
  int _activeLinkColor(AppLocalizations l10n) =>
      _linkColor ?? corkboardLinkStyles(l10n).first.value;

  double _minFitScale(Size viewport, {double margin = 0.94}) {
    if (viewport.width <= 0 || viewport.height <= 0) return 1.0;
    return math.min(
          viewport.width / kCorkBoardSize,
          viewport.height / kCorkBoardSize,
        ) *
        margin;
  }

  void _applyFitView([Size? viewport]) {
    if (!mounted) return;
    final vp = viewport ?? _viewportSize;
    if (vp == null || vp.width <= 0 || vp.height <= 0) return;
    final scale = _minFitScale(vp);
    final dx = (vp.width - kCorkBoardSize * scale) / 2;
    final dy = (vp.height - kCorkBoardSize * scale) / 2;
    _tfCtrl.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
    _viewScale = scale;
    _needsFitView = false;
    _lastFitBoardId = _boardId;
  }

  void _centerView() {
    _needsFitView = true;
    _applyFitView();
  }

  void _selectBoard(String id) {
    setState(() {
      _boardId = id;
      _needsFitView = true;
    });
  }

  void _scheduleFitIfNeeded(Size viewport) {
    _viewportSize = viewport;
    final boardChanged = _boardId != null && _boardId != _lastFitBoardId;
    if (!_needsFitView && !boardChanged) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyFitView(viewport);
    });
  }

  void _toggleTools() => setState(() => _toolsOpen = !_toolsOpen);

  void _addNote() {
    final boardId = _boardId;
    if (boardId == null) return;
    final s = MediaQuery.sizeOf(context);
    final center = MatrixUtils.transformPoint(
      Matrix4.inverted(_tfCtrl.value),
      Offset(s.width / 2, s.height / 2),
    );
    final rng = math.Random();
    const half = kCorkDefaultSize / 2;
    _svc
        .addItem(CorkboardItem(
          userId: _svc.currentUserId ?? '',
          teamId: widget.teamId,
          boardId: boardId,
          type: CorkItemType.note,
          content: '',
          posX: center.dx - half + (rng.nextDouble() - .5) * 60,
          posY: center.dy - half + (rng.nextDouble() - .5) * 60,
          rotation: (rng.nextDouble() - .5) * 0.08,
          color: _paperColor,
        ))
        .then((_) {
      if (!mounted) return;
      _svc
          .getItemsStream(teamId: widget.teamId, boardId: boardId)
          .first
          .then((items) {
        if (!mounted || items.isEmpty) return;
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _showEdit(items.first);
      });
    });
  }

  Future<void> _startConnect(String id) async {
    if (!_connecting) {
      setState(() {
        _connecting = true;
        _firstId = id;
      });
      return;
    }
    if (_firstId == null) {
      setState(() => _firstId = id);
      return;
    }
    if (_firstId == id) {
      _cancelConnect();
      return;
    }
    if (_boardId == null) return;
    final l10n = AppLocalizations.of(context)!;
    final fromId = _firstId!;
    try {
      final created = await _svc.addConnection(
        fromId,
        id,
        _activeLinkColor(l10n),
        teamId: widget.teamId,
        boardId: _boardId!,
      );
      if (!created) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.localeName.startsWith('tr')
                    ? 'Bu notlar arasında zaten bir bağlantı var.'
                    : 'A link already exists between these notes.',
                style: GoogleFonts.outfit(),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.errorGeneric(e.toString()),
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _connecting = false;
      _firstId = null;
    });
  }

  void _enterConnectMode() => setState(() {
        _connecting = true;
        _firstId = null;
      });

  void _cancelConnect() => setState(() {
        _connecting = false;
        _firstId = null;
      });

  void _onCanvasBackgroundTap() {
    setState(() => _highlightConnectionId = null);
    // Bağlantı modunda arka plana dokunma iptal etmesin; kullanıcı İptal ile çıksın.
  }

  void _bringItemToFront(String id) {
    if (_frontItemId == id) return;
    setState(() => _frontItemId = id);
  }

  void _onItemDragUpdate(String id, double x, double y) {
    setState(() => _dragPositions[id] = Offset(x, y));
  }

  void _onItemDragEnd(String id) {
    setState(() => _dragPositions.remove(id));
  }

  List<CorkboardItem> _sortedItems(List<CorkboardItem> items) {
    final list = List<CorkboardItem>.from(items);
    list.sort((a, b) {
      int layer(CorkboardItem i) {
        if (i.id == _frontItemId || _dragPositions.containsKey(i.id)) {
          return 1;
        }
        return 0;
      }

      final layerCmp = layer(a).compareTo(layer(b));
      if (layerCmp != 0) return layerCmp;
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  String _itemPreviewLabel(CorkboardItem item) {
    final text = item.content.trim();
    if (text.isEmpty) return AppLocalizations.of(context)!.corkboardNotePlaceholder;
    return text.length > 48 ? '${text.substring(0, 48)}…' : text;
  }

  Future<void> _deleteConnection(String connectionId) async {
    await _svc.deleteConnection(connectionId);
    if (!mounted) return;
    setState(() => _highlightConnectionId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.corkboardConnectionDeleted,
          style: GoogleFonts.outfit(),
        ),
      ),
    );
  }

  void _onLinkTap(
    Offset localPosition,
    List<CorkboardItem> items,
    List<CorkboardConnection> conns,
  ) {
    if (_connecting) return;
    final hit = hitTestCorkConnection(
      localPosition,
      items: items,
      connections: conns,
      dragOverrides: _dragPositions,
    );
    if (hit == null) return;
    setState(() => _highlightConnectionId = hit);
    _showConnectionActions(hit, items, conns);
  }

  void _showConnectionActions(
    String connectionId,
    List<CorkboardItem> items,
    List<CorkboardConnection> conns,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final conn = conns.where((c) => c.id == connectionId).firstOrNull;
    if (conn == null) return;

    final from = items.where((i) => i.id == conn.fromId).firstOrNull;
    final to = items.where((i) => i.id == conn.toId).firstOrNull;
    final fromLabel = from != null ? _itemPreviewLabel(from) : '?';
    final toLabel = to != null ? _itemPreviewLabel(to) : '?';

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: '$fromLabel → $toLabel',
        child: ListTile(
          leading: Icon(
            Icons.link_off_outlined,
            color: Theme.of(ctx).colorScheme.error,
          ),
          title: Text(
            l10n.corkboardDeleteConnection,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          onTap: () {
            Navigator.pop(ctx);
            _deleteConnection(connectionId);
          },
        ),
      ),
    );
  }

  void _showManageConnections(
    CorkboardItem item,
    List<CorkboardItem> items,
    List<CorkboardConnection> conns,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final id = item.id;
    if (id == null) return;

    final related = conns.where((c) => c.fromId == id || c.toId == id).toList();
    if (related.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.corkboardNoConnections, style: GoogleFonts.outfit()),
        ),
      );
      return;
    }

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: l10n.corkboardManageConnections,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: related.map((c) {
            final otherId = c.fromId == id ? c.toId : c.fromId;
            final other = items.where((i) => i.id == otherId).firstOrNull;
            final label =
                other != null ? _itemPreviewLabel(other) : otherId;
            return ListTile(
              leading: Icon(
                Icons.link_rounded,
                color: Color(c.color),
              ),
              title: Text(
                l10n.corkboardConnectionTo(label),
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (c.id != null) _deleteConnection(c.id!);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showEdit(CorkboardItem item) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: item.content);
    int selColor = item.color;

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => PhobesBottomSheet(
          title: l10n.edit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              PhobesTextField(
                controller: ctrl,
                hintText: l10n.corkboardEditHint,
                prefixIcon: Icons.notes_rounded,
                maxLines: 6,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.corkboardCardColor,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: kPaperTones.map((t) {
                  final sel = selColor == t.base;
                  return GestureDetector(
                    onTap: () => setS(() => selColor = t.base),
                    child: AnimatedContainer(
                      duration: PhobesTheme.animFast,
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(t.base),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel ? t.accent : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: t.accent.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              PhobesButton(
                text: l10n.save,
                width: double.infinity,
                onPressed: () {
                  _svc.updateItem(
                    item.copyWith(content: ctrl.text.trim(), color: selColor),
                  );
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _zoom(double factor) {
    if (!mounted || _viewportSize == null) return;
    final vp = _viewportSize!;
    final minS = _minFitScale(vp);
    final current = _tfCtrl.value.getMaxScaleOnAxis();
    final base = current > 0.001 ? current : _viewScale;
    final next = (base * factor).clamp(minS, _kMaxZoom);
    if ((next - base).abs() < 0.001) return;

    final focal = Offset(vp.width / 2, vp.height / 2);
    final ratio = next / base;
    _tfCtrl.value = Matrix4.copy(_tfCtrl.value)
      ..translate(focal.dx, focal.dy)
      ..scale(ratio)
      ..translate(-focal.dx, -focal.dy);
    _viewScale = next;
  }

  Future<void> _createBoard(List<CorkboardBoard> boards) async {
    final l10n = AppLocalizations.of(context)!;
    final title = await _promptBoardTitle(
      l10n.corkboardNewBoard,
      l10n.corkboardDefaultBoardName(boards.length + 1),
    );
    if (title == null || title.trim().isEmpty || !mounted) return;
    final id = await _svc.createBoard(
      title: title.trim(),
      teamId: widget.teamId,
      sortOrder: boards.length,
    );
    if (boards.isEmpty) {
      await _svc.migrateLegacyItems(id, teamId: widget.teamId);
    }
    if (!mounted) return;
    setState(() {
      _boardId = id;
      _needsFitView = true;
    });
  }

  Future<void> _createFirstBoard() async {
    if (_svc.currentUserId == null) return;
    final l10n = AppLocalizations.of(context)!;
    final id = await _svc.createBoard(
      title: l10n.corkboardFirstBoardName,
      teamId: widget.teamId,
    );
    await _svc.migrateLegacyItems(id, teamId: widget.teamId);
    if (!mounted) return;
    setState(() {
      _boardId = id;
      _needsFitView = true;
    });
  }

  Future<void> _renameBoard(CorkboardBoard board) async {
    final l10n = AppLocalizations.of(context)!;
    final title =
        await _promptBoardTitle(l10n.corkboardRenameBoard, board.title);
    if (title == null || title.trim().isEmpty) return;
    await _svc.renameBoard(board.id!, title.trim());
  }

  Future<void> _deleteBoard(CorkboardBoard board, List<CorkboardBoard> all) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.corkboardDeleteBoardTitle(board.title),
          style: GoogleFonts.outfit(),
        ),
        content: Text(
          l10n.corkboardDeleteBoardBody,
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true || board.id == null) return;
    try {
      await _svc.deleteBoard(board.id!, teamId: widget.teamId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.corkboardDeleteBoardFailed('$e'),
            style: GoogleFonts.outfit(),
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    final remaining = all.where((b) => b.id != board.id).toList();
    setState(() {
      _boardId = remaining.isEmpty ? null : remaining.first.id;
      _needsFitView = true;
    });
  }

  Future<String?> _promptBoardTitle(String dialogTitle, String initial) async {
    final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dialogTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.corkboardBoardNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value && isDark;

    return Scaffold(
      backgroundColor: isAmoled ? Colors.black : cs.surface,
      body: StreamBuilder<List<CorkboardBoard>>(
        stream: _svc.getBoardsStream(teamId: widget.teamId),
        builder: (context, boardSnap) {
          final boards = boardSnap.data;
          final boardsLoading =
              boardSnap.connectionState == ConnectionState.waiting &&
                  boards == null;
          final boardsList = boards ?? [];
          final activeBoardId = _activeBoardId(boardsList);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StreamBuilder<List<CorkboardItem>>(
                stream: activeBoardId == null
                    ? Stream.value([])
                    : _svc.getItemsStream(
                        teamId: widget.teamId,
                        boardId: activeBoardId,
                      ),
                builder: (context, itemSnap) {
                  final count = itemSnap.data?.length ?? 0;
                  final currentBoard = boardsList
                      .where((b) => b.id == activeBoardId)
                      .cast<CorkboardBoard?>()
                      .firstOrNull;

                  return PhobesModuleHeaderBar(
                    title: widget.teamId != null
                        ? l10n.corkboardTeamTitle
                        : l10n.corkboardPersonalTitle,
                    icon: Icons.dashboard_customize_rounded,
                    subtitle: currentBoard != null
                        ? l10n.corkboardBoardNotes(
                            currentBoard.title,
                            count,
                          )
                        : l10n.corkboardSubtitleDefault,
                    onAdd: activeBoardId == null ? null : _addNote,
                    addTooltip: l10n.corkboardAddNote,
                    info: ModuleInfoCatalog.forCorkboard(l10n),
                    useExtendedHeight: boardsList.isNotEmpty,
                    customContent: boardsList.isEmpty
                        ? null
                        : _BoardPageStrip(
                            l10n: l10n,
                            boards: boardsList,
                            selectedId: activeBoardId,
                            canManageBoards: widget.teamId == null ||
                                _canManageTeamBoards,
                            onSelect: _selectBoard,
                            onAdd: () => _createBoard(boardsList),
                            onRename: _renameBoard,
                            onDelete: (b) => _deleteBoard(b, boardsList),
                          ),
                    extraActions: activeBoardId == null
                        ? null
                        : [
                            PhobesModuleHeaderIconButton(
                              icon: _connecting
                                  ? Icons.close_rounded
                                  : Icons.hub_outlined,
                              iconColor: _connecting
                                  ? Colors.tealAccent.shade100
                                  : null,
                              onTap: _connecting
                                  ? _cancelConnect
                                  : _enterConnectMode,
                            ),
                            PhobesModuleHeaderIconButton(
                              icon: Icons.tune_rounded,
                              iconColor: _toolsOpen
                                  ? Colors.tealAccent.shade100
                                  : null,
                              onTap: _toggleTools,
                            ),
                            PhobesModuleHeaderIconButton(
                              icon: Icons.zoom_out_rounded,
                              onTap: () => _zoom(0.88),
                            ),
                            PhobesModuleHeaderIconButton(
                              icon: Icons.zoom_in_rounded,
                              onTap: () => _zoom(1.15),
                            ),
                            PhobesModuleHeaderIconButton(
                              icon: Icons.fit_screen_rounded,
                              onTap: _centerView,
                            ),
                          ],
                  );
                },
              ),
              Expanded(
                child: boardsLoading
                    ? Center(
                        child: PhobesLoadingIndicator(color: cs.primary),
                      )
                    : boardSnap.hasError
                        ? _NoBoardEmptyState(
                            l10n: l10n,
                            onCreate: _createFirstBoard,
                            error: boardSnap.error,
                          )
                        : boardsList.isEmpty
                        ? _NoBoardEmptyState(
                            l10n: l10n,
                            onCreate: _createFirstBoard,
                          )
                        : activeBoardId == null
                            ? Center(
                                child: PhobesLoadingIndicator(
                                  color: cs.primary,
                                ),
                              )
                            : _buildCanvas(
                                context,
                                cs: cs,
                                isDark: isDark,
                                isAmoled: isAmoled,
                                boardId: activeBoardId,
                              ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCanvas(
    BuildContext context, {
    required ColorScheme cs,
    required bool isDark,
    required bool isAmoled,
    required String boardId,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final linkStyles = corkboardLinkStyles(l10n);
    final activeLinkColor = _activeLinkColor(l10n);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        _scheduleFitIfNeeded(viewport);

        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _tfCtrl,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(48),
              minScale: _kMinZoom,
              maxScale: _kMaxZoom,
              panEnabled: !_connecting,
              scaleEnabled: !_connecting,
              trackpadScrollCausesScale: !_connecting,
              child: StreamBuilder<List<dynamic>>(
                stream: Rx.combineLatest2(
                  _svc.getItemsStream(
                    teamId: widget.teamId,
                    boardId: boardId,
                  ),
                  _svc.getConnectionsStream(
                    teamId: widget.teamId,
                    boardId: boardId,
                  ),
                  (a, b) => [a, b],
                ),
                builder: (context, snap) {
                  final items =
                      (snap.data?[0] as List<CorkboardItem>?) ?? [];
                  final conns =
                      (snap.data?[1] as List<CorkboardConnection>?) ?? [];
                  final sorted = _sortedItems(items);

                  return SizedBox(
                    width: kCorkBoardSize,
                    height: kCorkBoardSize,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _PlanningGridPainter(
                              isDark: isDark,
                              colorScheme: cs,
                              isAmoled: isAmoled,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _connecting ? null : _onCanvasBackgroundTap,
                          ),
                        ),
                        if (items.isEmpty) Center(child: _EmptyBoard(l10n: l10n)),
                        IgnorePointer(
                          ignoring: _connecting,
                          child: Listener(
                            behavior: HitTestBehavior.translucent,
                            onPointerUp: (e) =>
                                _onLinkTap(e.localPosition, items, conns),
                            child: CustomPaint(
                              size: const Size(kCorkBoardSize, kCorkBoardSize),
                              painter: _LinkPainter(
                                items: items,
                                conns: conns,
                                dragOverrides: _dragPositions,
                                highlightConnectionId: _highlightConnectionId,
                              ),
                            ),
                          ),
                        ),
                        ...sorted.map(
                          (it) => CorkItemWidget(
                            key: ValueKey(it.id),
                            item: it,
                            isConnecting: _connecting,
                            isSelectedForConnection: _firstId == it.id,
                            onDragStart: it.id != null
                                ? () => _bringItemToFront(it.id!)
                                : null,
                            onDragUpdate: it.id != null
                                ? (x, y) => _onItemDragUpdate(it.id!, x, y)
                                : null,
                            onPositionChanged: (x, y) {
                              if (it.id != null) {
                                _onItemDragEnd(it.id!);
                                _svc.updatePosition(
                                  it.id!,
                                  x,
                                  y,
                                  it.rotation,
                                );
                              }
                            },
                            onSizeChanged: (size) {
                              if (it.id != null) {
                                _svc.updateSize(it.id!, size);
                              }
                            },
                            onDelete: () {
                              if (it.id != null) {
                                _svc.deleteItem(
                                  it.id!,
                                  teamId: widget.teamId,
                                );
                              }
                            },
                            onEdit: () => _showEdit(it),
                            onConnect: () => _startConnect(it.id!),
                            onManageConnections: () => _showManageConnections(
                              it,
                              items,
                              conns,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_toolsOpen)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: _ToolsPanel(
                  l10n: l10n,
                  linkStyles: linkStyles,
                  paperColor: _paperColor,
                  linkColor: activeLinkColor,
                  onPaperColor: (c) => setState(() => _paperColor = c),
                  onLinkColor: (c) => setState(() => _linkColor = c),
                ),
              ),
            if (_connecting)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _ConnectBanner(
                  hasFirst: _firstId != null,
                  onCancel: _cancelConnect,
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── No boards empty state ───────────────────────────────────────────────────

class _NoBoardEmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onCreate;
  final Object? error;

  const _NoBoardEmptyState({
    required this.l10n,
    required this.onCreate,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PhobesEmptyState(
        icon: Icons.dashboard_customize_rounded,
        title: l10n.corkboardNoBoardsTitle,
        description: error != null
            ? l10n.corkboardNoBoardsError
            : l10n.corkboardNoBoardsDesc,
        buttonText: l10n.corkboardAddBoard,
        buttonIcon: Icons.add_rounded,
        onButtonTap: onCreate,
      ),
    );
  }
}

// ─── Board page strip ────────────────────────────────────────────────────────

class _BoardPageStrip extends StatelessWidget {
  final AppLocalizations l10n;
  final List<CorkboardBoard> boards;
  final String? selectedId;
  final bool canManageBoards;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final void Function(CorkboardBoard) onRename;
  final void Function(CorkboardBoard) onDelete;

  const _BoardPageStrip({
    required this.l10n,
    required this.boards,
    required this.selectedId,
    this.canManageBoards = true,
    required this.onSelect,
    required this.onAdd,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: boards.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == boards.length) {
            return Material(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: Colors.white.withOpacity(0.95),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.corkboardBoardTab,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final board = boards[i];
          final sel = board.id == selectedId;
          return GestureDetector(
            onTap: () {
              if (board.id != null) onSelect(board.id!);
            },
            onLongPress: canManageBoards
                ? () => _showBoardMenu(context, board, l10n)
                : null,
            child: AnimatedContainer(
              duration: PhobesTheme.animFast,
              padding: EdgeInsets.fromLTRB(14, 8, sel ? 4 : 14, 8),
              decoration: BoxDecoration(
                color: sel
                    ? Colors.white.withOpacity(0.28)
                    : Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel
                      ? Colors.white.withOpacity(0.55)
                      : Colors.white.withOpacity(0.22),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    board.title,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(sel ? 1 : 0.88),
                    ),
                  ),
                  if (sel && canManageBoards) ...[
                    const SizedBox(width: 2),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _showBoardMenu(context, board, l10n),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            size: 18,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBoardMenu(
    BuildContext context,
    CorkboardBoard board,
    AppLocalizations l10n,
  ) {
    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: board.title,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_outlined, color: Theme.of(ctx).colorScheme.primary),
              title: Text(l10n.corkboardRename, style: GoogleFonts.outfit()),
              onTap: () {
                Navigator.pop(ctx);
                onRename(board);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
              title: Text(l10n.corkboardDeleteBoardMenu, style: GoogleFonts.outfit()),
              onTap: () {
                Navigator.pop(ctx);
                onDelete(board);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyBoard extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyBoard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.dashboard_customize_outlined,
              size: 36, color: cs.primary.withOpacity(0.7)),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.corkboardEmptyTitle,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.corkboardEmptySubtitle,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: cs.onSurface.withOpacity(0.45),
          ),
        ),
      ],
    );
  }
}

// ─── Connect banner ────────────────────────────────────────────────────────────

class _ConnectBanner extends StatelessWidget {
  final bool hasFirst;
  final VoidCallback onCancel;

  const _ConnectBanner({required this.hasFirst, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C28) : Colors.white;
    final fg = isDark ? Colors.white : const Color(0xFF1A1A2E);
    return Material(
      color: Colors.transparent,
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: bg.withOpacity(0.97),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withOpacity(0.55), width: 1.5),
          boxShadow: PhobesTheme.getCardShadow(isDark),
        ),
        child: Row(
          children: [
            Icon(Icons.hub_rounded, color: cs.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasFirst
                    ? AppLocalizations.of(context)!.corkboardConnectSecond
                    : AppLocalizations.of(context)!.corkboardConnectFirst,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  height: 1.35,
                ),
              ),
            ),
            TextButton(
              onPressed: onCancel,
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: GoogleFonts.outfit(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tools panel ─────────────────────────────────────────────────────────────

class _ToolsPanel extends StatelessWidget {
  final AppLocalizations l10n;
  final List<LinkStyle> linkStyles;
  final int paperColor;
  final int linkColor;
  final ValueChanged<int> onPaperColor;
  final ValueChanged<int> onLinkColor;

  const _ToolsPanel({
    required this.l10n,
    required this.linkStyles,
    required this.paperColor,
    required this.linkColor,
    required this.onPaperColor,
    required this.onLinkColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(isDark ? 0.92 : 0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
        boxShadow: PhobesTheme.getCardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.corkboardNewNoteColor,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: kPaperTones.map((t) {
              final sel = paperColor == t.base;
              return GestureDetector(
                onTap: () => onPaperColor(t.base),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color(t.base),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel ? t.accent : cs.outline.withOpacity(0.2),
                      width: sel ? 2.5 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.corkboardLinkType,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.corkboardTapLinkToDelete,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withOpacity(0.62),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: linkStyles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final style = linkStyles[i];
                final sel = linkColor == style.value;
                return GestureDetector(
                  onTap: () => onLinkColor(style.value),
                  child: AnimatedContainer(
                    duration: PhobesTheme.animFast,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? Color(style.value).withOpacity(0.15)
                          : cs.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel
                            ? Color(style.value)
                            : cs.outline.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          style.icon,
                          size: 16,
                          color: sel
                              ? Color(style.value)
                              : cs.onSurface.withOpacity(0.9),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          style.label,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w600,
                            color: sel
                                ? Color(style.value)
                                : cs.onSurface.withOpacity(0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Canvas grid ─────────────────────────────────────────────────────────────

class _PlanningGridPainter extends CustomPainter {
  final bool isDark;
  final bool isAmoled;
  final ColorScheme colorScheme;

  const _PlanningGridPainter({
    required this.isDark,
    required this.colorScheme,
    this.isAmoled = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final base = isDark
        ? (isAmoled ? const Color(0xFF2A2F3A) : const Color(0xFF2E3440))
        : const Color(0xFFF3F5F8);
    canvas.drawRect(Offset.zero & size, Paint()..color = base);

    const spacing = 28.0;
    final dot = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.14)
          : colorScheme.outline.withOpacity(0.22);

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), isDark ? 1.4 : 1.2, dot);
      }
    }

    // Light border frame so board edges read against scaffold
    canvas.drawRect(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      Paint()
        ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_PlanningGridPainter old) =>
      old.isDark != isDark ||
      old.isAmoled != isAmoled ||
      old.colorScheme != colorScheme;
}

// ─── Connection lines ──────────────────────────────────────────────────────────

class _LinkPainter extends CustomPainter {
  final List<CorkboardItem> items;
  final List<CorkboardConnection> conns;
  final Map<String, Offset> dragOverrides;
  final String? highlightConnectionId;

  const _LinkPainter({
    required this.items,
    required this.conns,
    this.dragOverrides = const {},
    this.highlightConnectionId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in conns) {
      final from = items.where((i) => i.id == c.fromId).firstOrNull;
      final to = items.where((i) => i.id == c.toId).firstOrNull;
      if (from == null || to == null) continue;

      final p1 = corkItemLinkAnchor(from, dragOverrides: dragOverrides);
      final p2 = corkItemLinkAnchor(to, dragOverrides: dragOverrides);
      final path = corkLinkPath(p1, p2);
      final color = Color(c.color);
      final highlighted = c.id == highlightConnectionId;

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withOpacity(0.12)
          ..strokeWidth = highlighted ? 6 : 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(highlighted ? 1 : 0.75)
          ..strokeWidth = highlighted ? 4 : 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      for (final pt in [p1, p2]) {
        canvas.drawCircle(
          pt,
          5,
          Paint()..color = color.withOpacity(0.9),
        );
        canvas.drawCircle(
          pt,
          2,
          Paint()..color = Colors.white.withOpacity(0.85),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LinkPainter old) =>
      old.items != items ||
      old.conns != conns ||
      old.dragOverrides != dragOverrides ||
      old.highlightConnectionId != highlightConnectionId;
}
