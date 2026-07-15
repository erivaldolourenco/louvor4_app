import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/widgets/spring_tap.dart';
import '../../domain/entities/chord_sheet_entity.dart';
import 'chord_sheet_editor.dart';

const _monoStyle = TextStyle(fontFamily: 'monospace', fontSize: 15, height: 1.4);

/// Linha da cifra no modo "Editar letra": campo de texto sempre editável,
/// repetição e remoção. Não lida com acordes.
class LyricsLineRow extends StatelessWidget {
  final EditableLine line;
  final VoidCallback onRemove;

  const LyricsLineRow({super.key, required this.line, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: line.textController,
            style: _monoStyle,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Texto da linha (pode ficar vazio p/ instrumental)',
            ),
          ),
        ),
        IconButton(
          tooltip: 'Remover linha',
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
          onPressed: onRemove,
        ),
      ],
    );
  }
}

/// Linha da cifra no modo "Cifrar": texto somente leitura com os acordes já
/// ancorados exibidos acima; tocar em qualquer ponto do texto abre o diálogo
/// pra adicionar/editar/remover o acorde naquela posição.
class ChordAnchorLineRow extends StatelessWidget {
  final EditableLine line;
  final VoidCallback onChanged;

  const ChordAnchorLineRow({super.key, required this.line, required this.onChanged});

  double _charWidth() {
    final painter = TextPainter(
      text: const TextSpan(text: 'M', style: _monoStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  Future<void> _handleTap(
    BuildContext context,
    TapUpDetails details,
    String text,
  ) async {
    final painter = TextPainter(
      text: TextSpan(text: text.isEmpty ? ' ' : text, style: _monoStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final rawOffset = painter.getPositionForOffset(details.localPosition).offset;
    final position = rawOffset.clamp(0, text.length);

    final charWidth = _charWidth();
    EditableChordAnchor? nearest;
    var nearestDistance = double.infinity;
    for (final anchor in line.chords) {
      final distance = (anchor.position - position).abs() * charWidth;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = anchor;
      }
    }
    final existing = nearestDistance <= charWidth / 2 ? nearest : null;

    final result = await showDialog<_ChordAnchorResult>(
      context: context,
      builder: (ctx) => _ChordAnchorDialog(initialChord: existing?.chord),
    );
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
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = line.textController.text;
    final charWidth = _charWidth();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => _handleTap(context, details, text),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
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
                left: anchor.position * charWidth,
                top: 0,
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
          ],
        ),
      ),
    );
  }
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

  Future<void> _editChord(BuildContext context, EditableChordAnchor anchor) async {
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
            onPressed: () =>
                Navigator.of(context).pop(const _ChordAnchorResult(remove: true)),
            child: const Text('Remover'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isValid
              ? () => Navigator.of(context).pop(
                  _ChordAnchorResult(chord: _controller.text.trim()),
                )
              : () => setState(
                  () => _error = 'Formato de acorde inválido (ex: C, Am7, D/F#)',
                ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
