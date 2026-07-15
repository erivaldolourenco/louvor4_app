import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../domain/entities/chord_sheet_entity.dart';

/// Renderização somente leitura de uma cifra, com acordes alinhados acima
/// da letra usando fonte monoespaçada. As seções são separadas por linhas
/// discretas em vez de cards, para aproveitar melhor o espaço da tela.
class ChordSheetView extends StatelessWidget {
  final ChordSheetEntity chordSheet;

  const ChordSheetView({super.key, required this.chordSheet});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasSongInfo =
        chordSheet.song.originalKey != null || chordSheet.song.bpm != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasSongInfo) ...[
          _ChordSheetInfoHeader(song: chordSheet.song),
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: cs.outlineVariant),
          const SizedBox(height: 14),
        ],
        for (int i = 0; i < chordSheet.sections.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: 14),
            Divider(height: 1, thickness: 1, color: cs.outlineVariant),
            const SizedBox(height: 14),
          ],
          _ChordSectionContent(section: chordSheet.sections[i]),
        ],
      ],
    );
  }
}

class _ChordSheetInfoHeader extends StatelessWidget {
  final ChordSheetSongInfo song;

  const _ChordSheetInfoHeader({required this.song});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Row(
      children: [
        if (song.originalKey != null) ...[
          Icon(Icons.piano_rounded, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('Tom ${song.originalKey}', style: style),
        ],
        if (song.originalKey != null && song.bpm != null) const SizedBox(width: 16),
        if (song.bpm != null) ...[
          Icon(Icons.speed_rounded, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('${song.bpm} BPM', style: style),
        ],
      ],
    );
  }
}

class _ChordSectionContent extends StatelessWidget {
  final ChordSectionEntity section;

  const _ChordSectionContent({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.label.isNotEmpty ? section.label : section.type.ptLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (section.type == ChordSectionType.chordSequence) ...[
          if (section.lines.isNotEmpty && section.lines.first.chords.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ChordSequenceRow(chords: section.lines.first.chords),
          ],
        ] else if (section.lines.isNotEmpty) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in section.lines) _ChordLine(line: line),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Linha de acordes de uma seção [ChordSectionType.chordSequence]: sem
/// letra, só os acordes em sequência.
class _ChordSequenceRow extends StatelessWidget {
  final List<ChordEntity> chords;

  const _ChordSequenceRow({required this.chords});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sorted = [...chords]..sort((a, b) => a.position.compareTo(b.position));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final chord in sorted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.badge),
            ),
            child: Text(
              chord.chord,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
      ],
    );
  }
}

class _ChordLine extends StatelessWidget {
  final ChordLineEntity line;

  const _ChordLine({required this.line});

  static String _buildChordLine(String text, List<ChordEntity> chords) {
    final sorted = [...chords]..sort((a, b) => a.position.compareTo(b.position));
    final buf = StringBuffer();
    var cursor = 0;
    for (final c in sorted) {
      final pos = c.position.clamp(cursor, text.length);
      if (pos > cursor) buf.write(' ' * (pos - cursor));
      buf.write(c.chord);
      cursor = pos + c.chord.length;
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final monoStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 15,
      height: 1.4,
      color: cs.onSurface,
    );

    final chordLine = _buildChordLine(line.text, line.chords);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chordLine.isNotEmpty)
            Text(
              chordLine,
              style: monoStyle.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          Text(
            line.text.isEmpty ? '(instrumental)' : line.text,
            style: line.text.isEmpty
                ? monoStyle.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  )
                : monoStyle,
          ),
        ],
      ),
    );
  }
}
