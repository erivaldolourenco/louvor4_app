import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/widgets/spring_tap.dart';
import '../../domain/entities/chord_sheet_entity.dart';
import 'chord_sheet_editor.dart';

const _monoStyle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 15,
  height: 1.4,
);

/// Linha da cifra no modo "Cifrar": texto somente leitura com os acordes já
/// ancorados exibidos acima; tocar em qualquer ponto do texto abre o diálogo
/// pra adicionar/editar/remover o acorde naquela posição.
class ChordAnchorLineRow extends StatefulWidget {
  final EditableLine line;
  final VoidCallback onChanged;

  const ChordAnchorLineRow({
    super.key,
    required this.line,
    required this.onChanged,
  });

  @override
  State<ChordAnchorLineRow> createState() => _ChordAnchorLineRowState();
}

/// Deslocamento mínimo (em pixels) que um gesto precisa percorrer antes de
/// ser tratado como arraste de reposicionamento em vez de um toque simples.
const _dragSlackPx = 4.0;

class _ChordAnchorLineRowState extends State<ChordAnchorLineRow> {
  int? _highlightedPosition;

  /// Acorde sendo arrastado no momento (null quando nenhum arraste ativo).
  EditableChordAnchor? _draggingAnchor;
  double _dragStartX = 0;
  double _dragDeltaX = 0;
  int _dragFromPosition = 0;
  bool _dragCrossedSlack = false;

  EditableLine get line => widget.line;

  double _charWidth() {
    final painter = TextPainter(
      text: const TextSpan(text: 'M', style: _monoStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  /// Faixa tocável antes do início do texto, pra dar espaço pra ancorar um
  /// acorde que soa antes da primeira palavra da frase (posição 0).
  double _leadingWidth() => _charWidth() * 1.5;

  /// Acha o acorde cujo badge cobre o toque em [dx], considerando a largura
  /// visual inteira do badge (não só o ponto onde ele foi ancorado) — o
  /// nome do acorde pode ter vários caracteres e o toque pode cair em
  /// qualquer parte dele, não só bem no início.
  EditableChordAnchor? _hitTestAnchor(double dx) {
    const horizontalPadding = 8.0; // Container(padding: horizontal: 4) * 2
    const slack = 6.0; // folga extra pra facilitar o toque
    final charWidth = _charWidth();
    final leadingWidth = _leadingWidth();

    for (final anchor in line.chords) {
      final left = leadingWidth + anchor.position * charWidth;
      final width = anchor.chord.length * charWidth + horizontalPadding;
      if (dx >= left - slack && dx <= left + width + slack) {
        return anchor;
      }
    }
    return null;
  }

  Future<void> _handleTap(
    BuildContext context,
    TapUpDetails details,
    String text,
  ) async {
    final dx = details.localPosition.dx - _leadingWidth();
    final int position;
    if (dx < 0) {
      // Toque na faixa extra antes do texto: acorde soa antes da frase.
      position = -1;
    } else {
      final painter = TextPainter(
        text: TextSpan(text: text.isEmpty ? ' ' : text, style: _monoStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final rawOffset = painter.getPositionForOffset(Offset(dx, 0)).offset;
      position = rawOffset.clamp(0, text.length);
    }

    final existing = _hitTestAnchor(details.localPosition.dx);

    setState(() => _highlightedPosition = existing?.position ?? position);
    final result = await _showChordAnchorPopover(
      context,
      globalPosition: details.globalPosition,
      initialChord: existing?.chord,
    );
    if (mounted) setState(() => _highlightedPosition = null);
    if (result == null) return;
    if (result.remove) {
      if (existing != null) line.chords.remove(existing);
    } else if (existing != null) {
      existing.chord = result.chord!;
    } else {
      line.chords.add(
        EditableChordAnchor(
          localId: newEditableId(),
          position: position,
          chord: result.chord!,
        ),
      );
    }
    widget.onChanged();
  }

  void _handleChordDragStart(
    EditableChordAnchor anchor,
    DragStartDetails details,
  ) {
    _draggingAnchor = anchor;
    _dragStartX = details.globalPosition.dx;
    _dragFromPosition = anchor.position;
    _dragDeltaX = 0;
    _dragCrossedSlack = false;
  }

  void _handleChordDragUpdate(DragUpdateDetails details) {
    if (_draggingAnchor == null) return;
    final delta = details.globalPosition.dx - _dragStartX;
    if (!_dragCrossedSlack && delta.abs() <= _dragSlackPx) return;
    setState(() {
      _dragCrossedSlack = true;
      _dragDeltaX = delta;
    });
  }

  void _handleChordDragEnd(DragEndDetails details) {
    final anchor = _draggingAnchor;
    if (anchor == null) return;
    final wasDragging = _dragCrossedSlack;
    final deltaPx = _dragDeltaX;

    setState(() {
      _draggingAnchor = null;
      _dragDeltaX = 0;
      _dragCrossedSlack = false;
    });

    if (!wasDragging) return;

    final charWidth = _charWidth();
    final deltaColumns = (deltaPx / charWidth).round();
    if (deltaColumns == 0) return;
    final direction = deltaColumns > 0 ? 1 : -1;
    final maxPos = line.textController.text.length - 1;
    final requestedPosition = (_dragFromPosition + deltaColumns).clamp(
      -1,
      maxPos,
    );

    final resolvedPosition = _resolveChordDropPosition(
      line,
      _dragFromPosition,
      requestedPosition,
      direction,
    );

    if (resolvedPosition == anchor.position) return;
    setState(() => anchor.position = resolvedPosition);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = line.textController.text;
    final charWidth = _charWidth();
    final leadingWidth = _leadingWidth();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => _handleTap(context, details, text),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (_highlightedPosition != null)
              Positioned(
                left: leadingWidth + _highlightedPosition! * charWidth,
                top: 20,
                width: charWidth,
                height: _monoStyle.fontSize! * (_monoStyle.height ?? 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: 20, left: leadingWidth),
              child: Text(
                text.isEmpty
                    ? '(instrumental — toque para ancorar acordes)'
                    : text,
                style: text.isEmpty
                    ? _monoStyle.copyWith(
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      )
                    : _monoStyle.copyWith(color: cs.onSurface),
              ),
            ),
            for (final anchor in line.chords)
              Positioned(
                left: leadingWidth + anchor.position * charWidth,
                top: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) =>
                      _handleChordDragStart(anchor, details),
                  onHorizontalDragUpdate: _handleChordDragUpdate,
                  onHorizontalDragEnd: _handleChordDragEnd,
                  child: Transform.translate(
                    offset: identical(anchor, _draggingAnchor)
                        ? Offset(_dragDeltaX, 0)
                        : Offset.zero,
                    child: Opacity(
                      opacity: identical(anchor, _draggingAnchor) ? 0.7 : 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.badge),
                        ),
                        child: Text(
                          anchor.chord,
                          style: _monoStyle.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Resolve a posição final de um acorde arrastado a partir de [fromPosition]
/// até [requested], "empurrando" na direção [direction] quando a posição
/// pedida já está ocupada por outro acorde ancorado — a própria posição de
/// origem não conta como ocupada, já que é o acorde sendo movido.
int _resolveChordDropPosition(
  EditableLine line,
  int fromPosition,
  int requested,
  int direction,
) {
  final maxPos = line.textController.text.length - 1;
  bool isOccupied(int p) =>
      p != fromPosition && line.chords.any((c) => c.position == p);

  var pos = requested;
  while (isOccupied(pos)) {
    final next = pos + direction;
    if (next < -1 || next > maxPos) return pos;
    pos = next;
  }
  return pos;
}

/// Editor de uma seção do tipo [ChordSectionType.chordSequence]: lista de
/// acordes em sequência (sem texto/letra), reordenável por arraste. Os
/// acordes ficam armazenados na primeira linha da seção; a posição de cada
/// [ChordEntity] é só a ordem na lista (ver [EditableSection.toEntity]).
class ChordSequenceEditor extends StatelessWidget {
  final EditableSection section;
  final VoidCallback onChanged;

  const ChordSequenceEditor({
    super.key,
    required this.section,
    required this.onChanged,
  });

  List<EditableChordAnchor> get _chords =>
      section.lines.isEmpty ? const [] : section.lines.first.chords;

  Future<void> _addChord(BuildContext context) async {
    final result = await showDialog<_ChordAnchorResult>(
      context: context,
      builder: (ctx) => const _ChordAnchorDialog(),
    );
    if (result == null || result.chord == null) return;
    if (section.lines.isEmpty) section.lines.add(EditableLine.newEmpty());
    section.lines.first.chords.add(
      EditableChordAnchor(
        localId: newEditableId(),
        position: _chords.length,
        chord: result.chord!,
      ),
    );
    onChanged();
  }

  Future<void> _editChord(
    BuildContext context,
    EditableChordAnchor anchor,
  ) async {
    final result = await showDialog<_ChordAnchorResult>(
      context: context,
      builder: (ctx) => _ChordAnchorDialog(initialChord: anchor.chord),
    );
    if (result == null) return;
    if (result.remove) {
      _chords.remove(anchor);
    } else if (result.chord != null) {
      anchor.chord = result.chord!;
    }
    onChanged();
  }

  void _reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final chord = _chords.removeAt(oldIndex);
    _chords.insert(newIndex, chord);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chords = _chords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chords.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Nenhum acorde adicionado.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          )
        else
          SizedBox(
            height: 44,
            child: ReorderableListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              onReorder: _reorder,
              children: [
                for (int i = 0; i < chords.length; i++)
                  ReorderableDragStartListener(
                    key: ValueKey(chords[i].localId),
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _ChordChip(
                        chord: chords[i].chord,
                        onTap: () => _editChord(context, chords[i]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => _addChord(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Adicionar acorde'),
        ),
      ],
    );
  }
}

/// Chip de acorde de [ChordSequenceEditor], com a mesma resposta elástica ao
/// toque ([SpringTap]) usada nos outros elementos interativos do app.
class _ChordChip extends StatelessWidget {
  final String chord;
  final VoidCallback onTap;

  const _ChordChip({required this.chord, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SpringTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.badge),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.badge),
        ),
        child: Text(
          chord,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cs.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Mostra um popover compacto ancorado perto de [globalPosition] (o ponto
/// tocado na linha), em vez de um dialog modal centralizado — assim o
/// caractere/posição destacada continua visível enquanto o usuário digita o
/// acorde.
Future<_ChordAnchorResult?> _showChordAnchorPopover(
  BuildContext context, {
  required Offset globalPosition,
  String? initialChord,
}) {
  final completer = Completer<_ChordAnchorResult?>();
  final overlay = Overlay.of(context);
  final screenSize = MediaQuery.of(context).size;

  const popoverWidth = 240.0;
  final showBelow = globalPosition.dy < screenSize.height * 0.55;
  final left = (globalPosition.dx - popoverWidth / 2).clamp(
    12.0,
    screenSize.width - popoverWidth - 12.0,
  );

  late OverlayEntry entry;

  void dismiss(_ChordAnchorResult? result) {
    if (completer.isCompleted) return;
    entry.remove();
    completer.complete(result);
  }

  entry = OverlayEntry(
    builder: (ctx) => Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => dismiss(null),
          ),
        ),
        Positioned(
          left: left,
          top: showBelow ? globalPosition.dy + 20 : null,
          bottom: showBelow ? null : screenSize.height - globalPosition.dy + 20,
          width: popoverWidth,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(AppRadius.card),
            color: Theme.of(ctx).colorScheme.surfaceContainerHigh,
            child: _ChordAnchorPopoverContent(
              initialChord: initialChord,
              onResult: dismiss,
            ),
          ),
        ),
      ],
    ),
  );

  overlay.insert(entry);
  return completer.future;
}

class _ChordAnchorPopoverContent extends StatefulWidget {
  final String? initialChord;
  final ValueChanged<_ChordAnchorResult?> onResult;

  const _ChordAnchorPopoverContent({
    required this.initialChord,
    required this.onResult,
  });

  @override
  State<_ChordAnchorPopoverContent> createState() =>
      _ChordAnchorPopoverContentState();
}

class _ChordAnchorPopoverContentState
    extends State<_ChordAnchorPopoverContent> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialChord ?? '',
  );
  String? _error;

  bool get _isEditing => widget.initialChord != null;

  static final _popoverButtonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    minimumSize: const Size(48, 48),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!isValidChordName(_controller.text)) {
      setState(() => _error = 'Acorde inválido (ex: C, Am7, D/F#)');
      return;
    }
    widget.onResult(_ChordAnchorResult(chord: _controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Acorde',
              hintText: 'Ex: C, Am7, D/F#',
              errorText: _error,
            ),
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            runSpacing: 4,
            children: [
              if (_isEditing)
                TextButton(
                  style: _popoverButtonStyle,
                  onPressed: () =>
                      widget.onResult(const _ChordAnchorResult(remove: true)),
                  child: const Text('Remover'),
                ),
              TextButton(
                style: _popoverButtonStyle,
                onPressed: () => widget.onResult(null),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: _popoverButtonStyle,
                onPressed: _submit,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChordAnchorResult {
  final String? chord;
  final bool remove;

  const _ChordAnchorResult({this.chord, this.remove = false});
}

class _ChordAnchorDialog extends StatefulWidget {
  final String? initialChord;

  const _ChordAnchorDialog({this.initialChord});

  @override
  State<_ChordAnchorDialog> createState() => _ChordAnchorDialogState();
}

class _ChordAnchorDialogState extends State<_ChordAnchorDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialChord ?? '',
  );
  String? _error;

  bool get _isValid => isValidChordName(_controller.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialChord != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar acorde' : 'Adicionar acorde'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: 'Acorde',
          hintText: 'Ex: C, Am7, D/F#',
          errorText: _error,
        ),
        onChanged: (_) => setState(() => _error = null),
      ),
      actions: [
        if (isEditing)
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(const _ChordAnchorResult(remove: true)),
            child: const Text('Remover'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isValid
              ? () => Navigator.of(
                  context,
                ).pop(_ChordAnchorResult(chord: _controller.text.trim()))
              : () => setState(
                  () =>
                      _error = 'Formato de acorde inválido (ex: C, Am7, D/F#)',
                ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
