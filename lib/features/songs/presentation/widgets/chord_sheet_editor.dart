import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_async_states.dart';
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
              // -1 é permitido: representa um acorde que soa antes do
              // início da frase (pickup), ancorado na faixa extra do editor.
              position: c.position.clamp(-1, text.length),
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

  factory EditableSection.fromEntity(ChordSectionEntity entity) =>
      EditableSection(
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

  factory EditableChordSheet.fromEntity(ChordSheetEntity entity) =>
      EditableChordSheet(
        originalKeyController: TextEditingController(
          text: entity.song.originalKey ?? '',
        ),
        bpmController: TextEditingController(
          text: entity.song.bpm?.toString() ?? '',
        ),
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
/// quando o modo "Editar letra" ([LyricsSectionsEditor]) está ativo. Se
/// [afterSectionId] corresponder a uma seção existente, a nova seção entra
/// logo abaixo dela; caso contrário vai pro final. Retorna o `localId` da
/// seção criada, pra ela virar a seleção atual.
String addLyricsSection(
  EditableChordSheet draft,
  VoidCallback onChanged, {
  String? afterSectionId,
}) {
  final newSection = EditableSection.newEmpty();
  final afterIndex = afterSectionId == null
      ? -1
      : draft.sections.indexWhere((s) => s.localId == afterSectionId);
  if (afterIndex == -1) {
    draft.sections.add(newSection);
  } else {
    draft.sections.insert(afterIndex + 1, newSection);
  }
  onChanged();
  return newSection.localId;
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
      .map(
        (section) => section.lines.map((l) => l.textController.text).join('\n'),
      )
      .join('\n\n');

  final result = await Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => FullLyricsTextPage(initialText: currentText),
    ),
  );
  if (result == null) return;
  final blocks = _splitLyricsIntoBlocks(result);
  final previousSections = draft.sections;

  // Tipo, nome e acordes são remapeados por posição (seção i, linha j) —
  // se a quantidade de blocos/linhas mudou, esse remapeamento pode não
  // corresponder mais às seções originais. Avisa o usuário nesse caso.
  final hasPreviousContent = previousSections.any(
    (s) =>
        s.lines.any((l) => l.textController.text.trim().isNotEmpty) ||
        s.lines.any((l) => l.chords.isNotEmpty),
  );
  final structureChanged =
      blocks.length != previousSections.length ||
      List.generate(
        blocks.length < previousSections.length
            ? blocks.length
            : previousSections.length,
        (i) => blocks[i].length != previousSections[i].lines.length,
      ).any((changed) => changed);

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
          for (int j = 0; j < blocks[i].length; j++)
            EditableLine(
              localId: newEditableId(),
              textController: TextEditingController(text: blocks[i][j]),
              chords: _preservedChords(previousSections, i, j),
            ),
        ],
      ),
  ];
  for (final section in previousSections) {
    section.dispose();
  }
  onChanged();

  if (hasPreviousContent && structureChanged) {
    AppFeedback.showInfo(
      'A quantidade de linhas/seções mudou — revise o tipo e os acordes '
      'de cada seção, pois podem ter sido reorganizados.',
    );
  }
}

/// Preserva os acordes já ancorados de uma linha enquanto ela continuar
/// existindo na mesma posição (seção [sectionIndex], linha [lineIndex]) —
/// só são descartados quando a linha (ou a seção) deixa de existir.
List<EditableChordAnchor> _preservedChords(
  List<EditableSection> previousSections,
  int sectionIndex,
  int lineIndex,
) {
  if (sectionIndex >= previousSections.length) return [];
  final previousLines = previousSections[sectionIndex].lines;
  if (lineIndex >= previousLines.length) return [];
  final previousLine = previousLines[lineIndex];
  return [
    for (final anchor in previousLine.chords)
      EditableChordAnchor(
        localId: newEditableId(),
        position: anchor.position,
        chord: anchor.chord,
      ),
  ];
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

/// Editor da estrutura da música: seções reordenáveis, cada uma com tipo e
/// nome — a letra de cada seção é só uma prévia somente leitura (editada de
/// verdade via "Editar letra completa", no FAB de [ChordSheetPage]). Não
/// lida com acordes — isso fica a cargo do modo "Cifrar" ([ChordAnchorEditor]).
class LyricsSectionsEditor extends StatelessWidget {
  final EditableChordSheet draft;
  final VoidCallback onChanged;
  final String? selectedSectionId;
  final ValueChanged<String?> onSelectSection;

  const LyricsSectionsEditor({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.selectedSectionId,
    required this.onSelectSection,
  });

  Future<void> _removeSection(
    BuildContext context,
    EditableSection section,
  ) async {
    final hasContent =
        section.lines.any((l) => l.textController.text.trim().isNotEmpty) ||
        section.lines.any((l) => l.chords.isNotEmpty);

    if (hasContent) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remover seção'),
          content: const Text(
            'Essa seção já tem letra (e possivelmente acordes) cadastrados. '
            'Tem certeza que deseja remover?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: const Text('Remover'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    section.dispose();
    draft.sections.remove(section);
    if (selectedSectionId == section.localId) onSelectSection(null);
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
          _EmptyEditorHint(
            onAdd: () => onSelectSection(addLyricsSection(draft, onChanged)),
          )
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: _reorderSections,
            children: [
              for (int i = 0; i < draft.sections.length; i++)
                _SectionCard(
                  key: ValueKey(draft.sections[i].localId),
                  index: i,
                  section: draft.sections[i],
                  onChanged: onChanged,
                  onRemove: () => _removeSection(context, draft.sections[i]),
                  onEditFullLyrics: () =>
                      editFullLyricsText(context, draft, onChanged),
                  showDivider: i < draft.sections.length - 1,
                  isSelected: selectedSectionId == draft.sections[i].localId,
                  onSelect: () => onSelectSection(
                    selectedSectionId == draft.sections[i].localId
                        ? null
                        : draft.sections[i].localId,
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
  final VoidCallback onAdd;

  const _EmptyEditorHint({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: AppEmptyState(
        icon: Icons.lyrics_outlined,
        title: 'Nenhuma seção ainda',
        description: 'Adicione uma seção pra começar a estruturar a letra.',
        action: FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Adicionar seção'),
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
  final VoidCallback onEditFullLyrics;
  final bool showDivider;
  final bool isSelected;
  final VoidCallback onSelect;

  const _SectionCard({
    super.key,
    required this.index,
    required this.section,
    required this.onChanged,
    required this.onRemove,
    required this.onEditFullLyrics,
    required this.showDivider,
    required this.isSelected,
    required this.onSelect,
  });

  Future<void> _editSection(BuildContext context) async {
    final result = await showDialog<({ChordSectionType type, String name})>(
      context: context,
      builder: (_) => _SectionEditDialog(
        initialType: section.type,
        initialName: section.labelController.text,
      ),
    );
    if (result == null) return;

    section.type = result.type;
    if (result.type == ChordSectionType.chordSequence &&
        section.lines.isEmpty) {
      section.lines.add(EditableLine.newEmpty());
    }
    section.labelController.text = result.name;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: isSelected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: onSelect,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                section.type.ptLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: cs.onSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                section.labelController.text.trim().isEmpty
                                    ? 'Sem nome'
                                    : section.labelController.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      section.labelController.text
                                          .trim()
                                          .isEmpty
                                      ? cs.onSurfaceVariant
                                      : cs.onSurface,
                                  fontStyle:
                                      section.labelController.text
                                          .trim()
                                          .isEmpty
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        tooltip: 'Editar tipo e nome',
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          foregroundColor: cs.onSecondaryContainer,
                          backgroundColor: cs.secondaryContainer,
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _editSection(context),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        tooltip: 'Remover seção',
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          foregroundColor: cs.onErrorContainer,
                          backgroundColor: cs.errorContainer,
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        onPressed: onRemove,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (section.type == ChordSectionType.chordSequence)
                    ChordSequenceEditor(section: section, onChanged: onChanged)
                  else if (section.lines.every(
                    (l) => l.textController.text.trim().isEmpty,
                  ))
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                      onTap: onEditFullLyrics,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              size: 18,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Sem letra ainda — toque para editar a letra completa',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.primary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Text(
                      section.lines
                          .map((l) => l.textController.text)
                          .join('\n'),
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }
}

class _SectionEditDialog extends StatefulWidget {
  final ChordSectionType initialType;
  final String initialName;

  const _SectionEditDialog({
    required this.initialType,
    required this.initialName,
  });

  @override
  State<_SectionEditDialog> createState() => _SectionEditDialogState();
}

class _SectionEditDialogState extends State<_SectionEditDialog> {
  late ChordSectionType _type;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar seção'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<ChordSectionType>(
            initialValue: _type,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: [
              for (final type in ChordSectionType.values)
                DropdownMenuItem(
                  value: type,
                  child: Text(
                    type.ptLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _type = value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Nome (opcional)'),
            onFieldSubmitted: (_) => Navigator.of(
              context,
            ).pop((type: _type, name: _nameController.text.trim())),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop((type: _type, name: _nameController.text.trim())),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
