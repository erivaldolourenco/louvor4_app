import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../domain/entities/chord_sheet_entity.dart';
import '../pages/full_lyrics_text_page.dart';
import 'chord_line_editor.dart';

int _localIdCounter = 0;
String newEditableId() => 'e${_localIdCounter++}';

/// Um acorde ancorado numa posição de caractere dentro do texto da linha.
class EditableChordAnchor {
  final String localId;
  int position;
  String chord;

  EditableChordAnchor({
    required this.localId,
    required this.position,
    required this.chord,
  });
}

/// Estado mutável de uma linha da cifra, usado só para alimentar o editor.
class EditableLine {
  final String localId;
  final TextEditingController textController;
  List<EditableChordAnchor> chords;
  int? repeat;

  EditableLine({
    required this.localId,
    required this.textController,
    required this.chords,
    this.repeat,
  });

  factory EditableLine.newEmpty() => EditableLine(
    localId: newEditableId(),
    textController: TextEditingController(),
    chords: [],
  );

  factory EditableLine.fromEntity(ChordLineEntity entity) => EditableLine(
    localId: newEditableId(),
    textController: TextEditingController(text: entity.text),
    chords: entity.chords
        .map(
          (c) => EditableChordAnchor(
            localId: newEditableId(),
            position: c.position,
            chord: c.chord,
          ),
        )
        .toList(),
    repeat: entity.repeat,
  );

  ChordLineEntity toEntity() {
    final text = textController.text;
    return ChordLineEntity(
      text: text,
      chords: chords
          .map(
            (c) => ChordEntity(
              position: c.position.clamp(0, text.length),
              chord: c.chord,
            ),
          )
          .toList(),
      repeat: repeat,
    );
  }

  void dispose() => textController.dispose();
}

/// Estado mutável de uma seção da cifra, usado só para alimentar o editor.
class EditableSection {
  final String localId;
  ChordSectionType type;
  final TextEditingController labelController;
  List<EditableLine> lines;

  EditableSection({
    required this.localId,
    required this.type,
    required this.labelController,
    required this.lines,
  });

  factory EditableSection.newEmpty() => EditableSection(
    localId: newEditableId(),
    type: ChordSectionType.verse,
    labelController: TextEditingController(),
    lines: [EditableLine.newEmpty()],
  );

  factory EditableSection.fromEntity(ChordSectionEntity entity) => EditableSection(
    localId: newEditableId(),
    type: entity.type,
    labelController: TextEditingController(text: entity.label),
    lines: entity.lines.map(EditableLine.fromEntity).toList(),
  );

  ChordSectionEntity toEntity() {
    if (type == ChordSectionType.chordSequence) {
      final chords = lines.expand((l) => l.chords).toList();
      return ChordSectionEntity(
        type: type,
        label: labelController.text.trim(),
        lines: [
          ChordLineEntity(
            text: '',
            chords: [
              for (int i = 0; i < chords.length; i++)
                ChordEntity(position: i, chord: chords[i].chord),
            ],
          ),
        ],
      );
    }
    return ChordSectionEntity(
      type: type,
      label: labelController.text.trim(),
      lines: lines.map((l) => l.toEntity()).toList(),
    );
  }

  void dispose() {
    labelController.dispose();
    for (final line in lines) {
      line.dispose();
    }
  }
}

/// Estado mutável da cifra inteira, manipulado pelo [ChordSheetEditor] e
/// serializado para [ChordSheetEntity] ao salvar.
class EditableChordSheet {
  final TextEditingController originalKeyController;
  final TextEditingController bpmController;
  List<EditableSection> sections;

  EditableChordSheet({
    required this.originalKeyController,
    required this.bpmController,
    required this.sections,
  });

  factory EditableChordSheet.fromEntity(ChordSheetEntity entity) => EditableChordSheet(
    originalKeyController: TextEditingController(text: entity.song.originalKey ?? ''),
    bpmController: TextEditingController(text: entity.song.bpm?.toString() ?? ''),
    sections: entity.sections.map(EditableSection.fromEntity).toList(),
  );

  ChordSheetEntity toEntity() => ChordSheetEntity(
    schemaVersion: 1,
    song: ChordSheetSongInfo(
      originalKey: originalKeyController.text.trim().isEmpty
          ? null
          : originalKeyController.text.trim(),
      bpm: int.tryParse(bpmController.text.trim()),
    ),
    sections: sections.map((s) => s.toEntity()).toList(),
  );

  void dispose() {
    originalKeyController.dispose();
    bpmController.dispose();
    for (final section in sections) {
      section.dispose();
    }
  }
}

/// Adiciona uma seção vazia ao draft. Chamado pelo FAB de [ChordSheetPage]
/// quando o modo "Editar letra" ([LyricsSectionsEditor]) está ativo.
void addLyricsSection(EditableChordSheet draft, VoidCallback onChanged) {
  draft.sections.add(EditableSection.newEmpty());
  onChanged();
}

/// Abre [FullLyricsTextPage] com o texto corrido atual do draft e, ao
/// concluir, reconstrói as seções a partir dos blocos separados por linha
/// em branco — preservando tipo/nome das seções que já existiam na mesma
/// posição. Chamado pelo FAB de [ChordSheetPage].
Future<void> editFullLyricsText(
  BuildContext context,
  EditableChordSheet draft,
  VoidCallback onChanged,
) async {
  final currentText = draft.sections
      .map((section) => section.lines.map((l) => l.textController.text).join('\n'))
      .join('\n\n');

  final result = await Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => FullLyricsTextPage(initialText: currentText),
    ),
  );
  if (result == null) return;
  final blocks = _splitLyricsIntoBlocks(result);
  final previousSections = draft.sections;

  draft.sections = [
    for (int i = 0; i < blocks.length; i++)
      EditableSection(
        localId: newEditableId(),
        type: i < previousSections.length
            ? previousSections[i].type
            : ChordSectionType.other,
        labelController: TextEditingController(
          text: i < previousSections.length
              ? previousSections[i].labelController.text
              : '',
        ),
        lines: [
          for (final line in blocks[i])
            EditableLine(
              localId: newEditableId(),
              textController: TextEditingController(text: line),
              chords: [],
            ),
        ],
      ),
  ];
  for (final section in previousSections) {
    section.dispose();
  }
  onChanged();
}

List<List<String>> _splitLyricsIntoBlocks(String text) {
  final lines = text.replaceAll('\r\n', '\n').split('\n');
  final blocks = <List<String>>[];
  var current = <String>[];
  for (final line in lines) {
    if (line.trim().isEmpty) {
      if (current.isNotEmpty) {
        blocks.add(current);
        current = [];
      }
    } else {
      current.add(line);
    }
  }
  if (current.isNotEmpty) blocks.add(current);
  return blocks;
}

/// Editor da letra da música, organizada por seções reordenáveis, cada uma
/// com tipo, nome e linhas de texto. Não lida com acordes — isso fica a
/// cargo do modo "Cifrar" ([ChordAnchorEditor]). Adicionar seção e editar a
/// letra completa ficam no FAB de [ChordSheetPage].
class LyricsSectionsEditor extends StatelessWidget {
  final EditableChordSheet draft;
  final VoidCallback onChanged;

  const LyricsSectionsEditor({super.key, required this.draft, required this.onChanged});

  void _removeSection(EditableSection section) {
    section.dispose();
    draft.sections.remove(section);
    onChanged();
  }

  void _reorderSections(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final section = draft.sections.removeAt(oldIndex);
    draft.sections.insert(newIndex, section);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (draft.sections.isEmpty)
          const _EmptyEditorHint()
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: _reorderSections,
            children: [
              for (int i = 0; i < draft.sections.length; i++)
                Padding(
                  key: ValueKey(draft.sections[i].localId),
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _SectionCard(
                    index: i,
                    section: draft.sections[i],
                    onChanged: onChanged,
                    onRemove: () => _removeSection(draft.sections[i]),
                  ),
                ),
            ],
          ),
        // Espaço extra para o conteúdo não ficar escondido atrás do FAB.
        const SizedBox(height: 72),
      ],
    );
  }
}

class _EmptyEditorHint extends StatelessWidget {
  const _EmptyEditorHint();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Adicione uma seção para começar.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final int index;
  final EditableSection section;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _SectionCard({
    required this.index,
    required this.section,
    required this.onChanged,
    required this.onRemove,
  });

  void _addLine() {
    section.lines.add(EditableLine.newEmpty());
    onChanged();
  }

  void _removeLine(EditableLine line) {
    line.dispose();
    section.lines.remove(line);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppCardSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Icon(Icons.drag_indicator_rounded, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<ChordSectionType>(
                  initialValue: section.type,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tipo', isDense: true),
                  items: [
                    for (final type in ChordSectionType.values)
                      DropdownMenuItem(value: type, child: Text(type.ptLabel)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    section.type = value;
                    if (value == ChordSectionType.chordSequence &&
                        section.lines.isEmpty) {
                      section.lines.add(EditableLine.newEmpty());
                    }
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: section.labelController,
                  decoration: const InputDecoration(labelText: 'Nome', isDense: true),
                ),
              ),
              IconButton(
                tooltip: 'Remover seção',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (section.type == ChordSectionType.chordSequence)
            ChordSequenceEditor(section: section, onChanged: onChanged)
          else ...[
            for (final line in section.lines)
              Padding(
                key: ValueKey(line.localId),
                padding: const EdgeInsets.only(top: 8),
                child: LyricsLineRow(
                  line: line,
                  onRemove: () => _removeLine(line),
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adicionar linha'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
