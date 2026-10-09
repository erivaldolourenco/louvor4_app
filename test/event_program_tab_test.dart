import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/events/data/event_program_repository.dart';
import 'package:louvor4_app/features/events/domain/entities/program_item_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/program_item_input_entity.dart';
import 'package:louvor4_app/features/events/presentation/cubit/event_program_cubit.dart';
import 'package:louvor4_app/features/events/presentation/widgets/event_program_tab.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

TextProgramItemEntity _text(
  String id,
  int position, {
  String title = 'Item',
  String? description,
}) => TextProgramItemEntity(
  id: id,
  position: position,
  title: title,
  description: description,
);

MusicProgramItemEntity _music(String id, int position) =>
    MusicProgramItemEntity(
      id: id,
      position: position,
      songId: 's1',
      songTitle: 'Oceans',
      songArtist: 'Hillsong',
    );

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeRepo implements EventProgramRepository {
  _FakeRepo({
    this.items = const [],
    this.throwOnLoad = false,
  });

  final List<ProgramItemEntity> items;
  final bool throwOnLoad;

  int loadCalls = 0;
  String? deletedId;
  List<String>? lastReorderIds;
  CreateTextProgramItemInputEntity? lastCreateInput;
  UpdateTextProgramItemInputEntity? lastUpdateInput;

  @override
  Future<List<ProgramItemEntity>> getProgram(String eventId) async {
    loadCalls++;
    if (throwOnLoad) throw Exception('erro ao carregar');
    return items;
  }

  @override
  Future<ProgramItemEntity> createTextItem(
    String eventId,
    CreateTextProgramItemInputEntity input,
  ) async {
    lastCreateInput = input;
    return _text('new', 99, title: input.title);
  }

  @override
  Future<ProgramItemEntity> updateTextItem(
    String eventId,
    String itemId,
    UpdateTextProgramItemInputEntity input,
  ) async {
    lastUpdateInput = input;
    return _text(itemId, 0, title: input.title);
  }

  @override
  Future<void> deleteItem(String eventId, String itemId) async {
    deletedId = itemId;
  }

  @override
  Future<void> reorder(String eventId, List<String> orderedIds) async {
    lastReorderIds = orderedIds;
  }

  @override
  Future<Uint8List> downloadRoteiroPdf(String eventId) async {
    return Uint8List(0);
  }
}

// ---------------------------------------------------------------------------
// Widget factory
// ---------------------------------------------------------------------------

Widget _buildTab(EventProgramCubit cubit, {bool isAdmin = false}) {
  return MaterialApp(
    home: BlocProvider<EventProgramCubit>.value(
      value: cubit,
      child: Scaffold(body: EventProgramTab(isAdmin: isAdmin)),
    ),
  );
}

// A criação de itens é disparada pelo FAB da tela de evento (fora do
// EventProgramTab). Nos testes, simulamos esse gatilho com um FAB próprio
// que chama a mesma função pública `showProgramTextItemDialog`.
Widget _buildTabWithAddFab(EventProgramCubit cubit) {
  return MaterialApp(
    home: BlocProvider<EventProgramCubit>.value(
      value: cubit,
      child: Builder(
        builder: (context) => Scaffold(
          body: const EventProgramTab(isAdmin: true),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showProgramTextItemDialog(context),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    ),
  );
}

/// Ícones do programa são SVGs de `assets/icons/` (não mais `Icons.*`).
Finder _svgAsset(String assetName) => find.byWidgetPredicate(
  (w) =>
      w is SvgPicture &&
      w.bytesLoader is SvgAssetLoader &&
      (w.bytesLoader as SvgAssetLoader).assetName == assetName,
);

Future<EventProgramCubit> _loadedCubit(_FakeRepo repo) async {
  final cubit = EventProgramCubit(repo, eventId: 'e1');
  await cubit.loadProgram();
  return cubit;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('EventProgramTab — estados de carregamento', () {
    testWidgets('exibe AppLoadingState no estado initial', (tester) async {
      final cubit = EventProgramCubit(_FakeRepo(), eventId: 'e1');
      // Do not load — stays in initial state.
      await tester.pumpWidget(_buildTab(cubit));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await cubit.close();
    });

    testWidgets(
      'exibe mensagem de erro quando status é failure e lista está vazia',
      (tester) async {
        final repo = _FakeRepo(throwOnLoad: true);
        final cubit = await _loadedCubit(repo);

        await tester.pumpWidget(_buildTab(cubit));
        await tester.pump();

        expect(find.text('erro ao carregar'), findsOneWidget);
        expect(find.text('Tentar novamente'), findsOneWidget);

        await cubit.close();
      },
    );

    testWidgets('"Tentar novamente" chama loadProgram', (tester) async {
      final repo = _FakeRepo(throwOnLoad: true);
      final cubit = await _loadedCubit(repo);

      await tester.pumpWidget(_buildTab(cubit));
      await tester.pump();

      final callsBefore = repo.loadCalls;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      expect(repo.loadCalls, greaterThan(callsBefore));

      await cubit.close();
    });
  });

  group('EventProgramTab — estado vazio (success + sem itens)', () {
    testWidgets('exibe texto "Sem programação"', (tester) async {
      final cubit = await _loadedCubit(_FakeRepo());

      await tester.pumpWidget(_buildTab(cubit));
      await tester.pump();

      expect(find.text('Sem programação'), findsOneWidget);

      await cubit.close();
    });

    // Adicionar item agora é pelo FAB da tela do evento, então nem o admin
    // vê um botão de adicionar dentro do estado vazio.
    testWidgets('admin não vê botão de adicionar no estado vazio', (
      tester,
    ) async {
      final cubit = await _loadedCubit(_FakeRepo());

      await tester.pumpWidget(_buildTab(cubit, isAdmin: true));
      await tester.pump();

      expect(find.text('Sem programação'), findsOneWidget);
      expect(find.text('Adicionar item de texto'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);

      await cubit.close();
    });

    testWidgets('não-admin não vê botão "Adicionar item de texto"', (tester) async {
      final cubit = await _loadedCubit(_FakeRepo());

      await tester.pumpWidget(_buildTab(cubit, isAdmin: false));
      await tester.pump();

      expect(find.text('Adicionar item de texto'), findsNothing);

      await cubit.close();
    });
  });

  group('EventProgramTab — renderização de itens', () {
    testWidgets('exibe título e artista de item MUSIC', (tester) async {
      final repo = _FakeRepo(items: [_music('m1', 0)]);
      final cubit = await _loadedCubit(repo);

      await tester.pumpWidget(_buildTab(cubit));
      await tester.pump();

      // Título e artista ficam no mesmo Text.rich ("Oceans  •  Hillsong").
      expect(find.textContaining('Oceans', findRichText: true), findsOneWidget);
      expect(
        find.textContaining('Hillsong', findRichText: true),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('item MUSIC usa o ícone music.svg', (tester) async {
      final repo = _FakeRepo(items: [_music('m1', 0)]);
      final cubit = await _loadedCubit(repo);

      await tester.pumpWidget(_buildTab(cubit));
      await tester.pump();

      expect(_svgAsset('assets/icons/music.svg'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('exibe título de item TEXT', (tester) async {
      final repo = _FakeRepo(items: [_text('t1', 0, title: 'Oração')]);
      final cubit = await _loadedCubit(repo);

      await tester.pumpWidget(_buildTab(cubit));
      await tester.pump();

      expect(find.text('Oração'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('item TEXT usa o ícone type-outline.svg', (tester) async {
      final repo = _FakeRepo(items: [_text('t1', 0, title: 'Texto')]);
      final cubit = await _loadedCubit(repo);

      await tester.pumpWidget(_buildTab(cubit));
      await tester.pump();

      expect(_svgAsset('assets/icons/type-outline.svg'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('exibe descrição de item TEXT quando presente', (tester) async {
      final repo = _FakeRepo(
        items: [_text('t1', 0, title: 'Avisos', description: 'Comunicados')],
      );
      final cubit = await _loadedCubit(repo);

      await tester.pumpWidget(_buildTab(cubit));
      await tester.pump();

      expect(find.text('Comunicados'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('não exibe descrição quando null', (tester) async {
      final repo = _FakeRepo(
        items: [_text('t1', 0, title: 'Avisos')],
      );
      final cubit = await _loadedCubit(repo);

      await tester.pumpWidget(_buildTab(cubit));
      await tester.pump();

      expect(find.text('Comunicados'), findsNothing);

      await cubit.close();
    });

    testWidgets('exibe número de posição no badge', (tester) async {
      final repo = _FakeRepo(items: [
        _text('t1', 0, title: 'A'),
        _text('t2', 1, title: 'B'),
      ]);
      final cubit = await _loadedCubit(repo);

      await tester.pumpWidget(_buildTab(cubit));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await cubit.close();
    });
  });

  group('EventProgramTab — visibilidade para admin', () {
    testWidgets('admin vê editar e excluir em item TEXT', (tester) async {
      final repo = _FakeRepo(items: [_text('t1', 0, title: 'Texto')]);
      final cubit = await _loadedCubit(repo);

      await tester.pumpWidget(_buildTab(cubit, isAdmin: true));
      await tester.pump();

      expect(find.byTooltip('Editar item'), findsOneWidget);
      expect(find.byTooltip('Remover item'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('admin não vê editar/excluir em item MUSIC', (tester) async {
      final repo = _FakeRepo(items: [_music('m1', 0)]);
      final cubit = await _loadedCubit(repo);

      await tester.pumpWidget(_buildTab(cubit, isAdmin: true));
      await tester.pump();

      expect(find.byTooltip('Editar item'), findsNothing);
      expect(find.byTooltip('Remover item'), findsNothing);

      await cubit.close();
    });

    testWidgets('não-admin não vê editar/excluir em item TEXT', (tester) async {
      final repo = _FakeRepo(items: [_text('t1', 0, title: 'Texto')]);
      final cubit = await _loadedCubit(repo);

      await tester.pumpWidget(_buildTab(cubit, isAdmin: false));
      await tester.pump();

      expect(find.byTooltip('Editar item'), findsNothing);
      expect(find.byTooltip('Remover item'), findsNothing);

      await cubit.close();
    });
  });

  group('EventProgramTab — diálogo de criação (TEXT)', () {
    testWidgets(
      '"Adicionar" abre diálogo com título "Adicionar item"',
      (tester) async {
        final repo = _FakeRepo(items: [_text('t1', 0, title: 'Existente')]);
        final cubit = await _loadedCubit(repo);

        await tester.pumpWidget(_buildTabWithAddFab(cubit));
        await tester.pump();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.text('Adicionar item'), findsOneWidget);

        await cubit.close();
      },
    );

    testWidgets('validação: título vazio exibe "Informe um título"', (tester) async {
      final repo = _FakeRepo(items: [_text('t1', 0, title: 'A')]);
      final cubit = await _loadedCubit(repo);

      await tester.pumpWidget(_buildTabWithAddFab(cubit));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Tap save without entering title
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(find.text('Informe um título'), findsOneWidget);

      await cubit.close();
    });

    testWidgets(
      'submeter com título válido chama createTextItem e fecha o diálogo',
      (tester) async {
        final repo = _FakeRepo(items: [_text('t1', 0, title: 'A')]);
        final cubit = await _loadedCubit(repo);

        await tester.pumpWidget(_buildTabWithAddFab(cubit));
        await tester.pump();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).first,
          'Nova oração',
        );
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(repo.lastCreateInput?.title, 'Nova oração');
        // Dialog dismissed
        expect(find.text('Adicionar item'), findsNothing);

        await cubit.close();
      },
    );

    testWidgets('"Cancelar" fecha o diálogo sem chamar createTextItem', (tester) async {
      final repo = _FakeRepo(items: [_text('t1', 0, title: 'A')]);
      final cubit = await _loadedCubit(repo);

      await tester.pumpWidget(_buildTabWithAddFab(cubit));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repo.lastCreateInput, isNull);
      expect(find.text('Adicionar item'), findsNothing);

      await cubit.close();
    });
  });

  group('EventProgramTab — diálogo de edição (TEXT)', () {
    testWidgets(
      'editar abre diálogo "Editar item" com campos pré-preenchidos',
      (tester) async {
        final repo = _FakeRepo(
          items: [
            _text('t1', 0, title: 'Avisos', description: 'Comunicados'),
          ],
        );
        final cubit = await _loadedCubit(repo);

        await tester.pumpWidget(_buildTab(cubit, isAdmin: true));
        await tester.pump();

        await tester.tap(find.byTooltip('Editar item'));
        await tester.pumpAndSettle();

        expect(find.text('Editar item'), findsOneWidget);

        final titleField = tester.widget<TextFormField>(
          find.byType(TextFormField).first,
        );
        expect(titleField.controller?.text, 'Avisos');

        final descField = tester.widget<TextFormField>(
          find.byType(TextFormField).at(1),
        );
        expect(descField.controller?.text, 'Comunicados');

        await cubit.close();
      },
    );

    testWidgets(
      'submeter edição chama updateTextItem com o novo título',
      (tester) async {
        final repo = _FakeRepo(
          items: [_text('t1', 0, title: 'Original')],
        );
        final cubit = await _loadedCubit(repo);

        await tester.pumpWidget(_buildTab(cubit, isAdmin: true));
        await tester.pump();

        await tester.tap(find.byTooltip('Editar item'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).first,
          'Atualizado',
        );
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(repo.lastUpdateInput?.title, 'Atualizado');

        await cubit.close();
      },
    );
  });

  group('EventProgramTab — exclusão de item', () {
    testWidgets('confirmar exclusão chama deleteItem', (tester) async {
      final repo = _FakeRepo(items: [_text('t1', 0, title: 'Para excluir')]);
      final cubit = await _loadedCubit(repo);

      await tester.pumpWidget(_buildTab(cubit, isAdmin: true));
      await tester.pump();

      await tester.tap(find.byTooltip('Remover item'));
      await tester.pumpAndSettle();

      // Confirm dialog appeared
      expect(find.text('Remover item'), findsOneWidget);

      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();

      expect(repo.deletedId, 't1');
      expect(cubit.state.items, isEmpty);

      await cubit.close();
    });

    testWidgets('cancelar exclusão não chama deleteItem', (tester) async {
      final repo = _FakeRepo(items: [_text('t1', 0, title: 'Manter')]);
      final cubit = await _loadedCubit(repo);

      await tester.pumpWidget(_buildTab(cubit, isAdmin: true));
      await tester.pump();

      await tester.tap(find.byTooltip('Remover item'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repo.deletedId, isNull);
      expect(cubit.state.items, hasLength(1));

      await cubit.close();
    });
  });
}
