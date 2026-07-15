import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/standard_section_app_bar.dart';

/// Tela de edição da letra completa em texto corrido, no mesmo formato da
/// tela de letra (LyricsPage). Usada tanto para colar a letra pela primeira
/// vez quanto para reeditar o texto completo depois. Ao concluir, devolve o
/// texto cru via Navigator.pop — quem chamou é responsável por quebrá-lo em
/// seções (por linha em branco).
class FullLyricsTextPage extends StatefulWidget {
  final String initialText;

  const FullLyricsTextPage({super.key, required this.initialText});

  @override
  State<FullLyricsTextPage> createState() => _FullLyricsTextPageState();
}

class _FullLyricsTextPageState extends State<FullLyricsTextPage> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text);

  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: StandardSectionAppBar(
        title: 'Letra completa',
        subtitle: 'Separe os trechos com uma linha em branco',
        actions: [
          IconButton.filledTonal(
            tooltip: 'Cancelar',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: cs.surfaceContainerHighest,
              foregroundColor: cs.onSurfaceVariant,
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: _cancel,
          ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            tooltip: 'Concluir',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            onPressed: _save,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            expands: true,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyle(color: cs.onSurface, fontSize: 16, height: 1.6),
            decoration: const InputDecoration(
              hintText: 'Cole ou digite a letra completa da música...',
              filled: false,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
