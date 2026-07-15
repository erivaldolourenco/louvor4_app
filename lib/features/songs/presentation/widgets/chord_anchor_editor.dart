import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../domain/entities/chord_sheet_entity.dart';
import 'chord_line_editor.dart';
import 'chord_sheet_editor.dart';

/// Modo "Cifrar": mostra a letra já salva (somente leitura) organizada por
/// seção; tocar em qualquer ponto do texto de uma linha abre o diálogo para
/// ancorar um acorde naquela posição. Não permite editar texto, seções ou
/// estrutura — isso é feito no modo "Editar letra" ([LyricsSectionsEditor]).
class ChordAnchorEditor extends StatelessWidget {
  final EditableChordSheet draft;
  final VoidCallback onChanged;

  const ChordAnchorEditor({super.key, required this.draft, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < draft.sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _ChordAnchorSectionCard(section: draft.sections[i], onChanged: onChanged),
        ],
      ],
    );
  }
}

class _ChordAnchorSectionCard extends StatelessWidget {
  final EditableSection section;
  final VoidCallback onChanged;

  const _ChordAnchorSectionCard({required this.section, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final label = section.labelController.text;

    return AppCardSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  section.type.ptLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (section.type == ChordSectionType.chordSequence) ...[
            const SizedBox(height: 10),
            ChordSequenceEditor(section: section, onChanged: onChanged),
          ] else if (section.lines.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final line in section.lines)
              Padding(
                key: ValueKey(line.localId),
                padding: const EdgeInsets.only(bottom: 4),
                child: ChordAnchorLineRow(line: line, onChanged: onChanged),
              ),
          ],
        ],
      ),
    );
  }
}
