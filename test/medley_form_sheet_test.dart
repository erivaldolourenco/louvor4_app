import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/medleys/data/medley_repository.dart';
import 'package:louvor4_app/features/medleys/domain/entities/create_medley_input_entity.dart';
import 'package:louvor4_app/features/medleys/domain/entities/medley_entity.dart';
import 'package:louvor4_app/features/medleys/domain/entities/medley_item_entity.dart';
import 'package:louvor4_app/features/medleys/presentation/cubit/medley_cubit.dart';
import 'package:louvor4_app/features/medleys/presentation/widgets/medley_form_sheet.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeMedleyRepository implements MedleyRepository {
  @override
  Future<List<MedleyEntity>> getUserMedleys() async => [];

  @override
  Future<MedleyEntity> createMedley(CreateMedleyInputEntity input) async =>
      MedleyEntity(id: 'new', name: input.name);

  @override
  Future<MedleyEntity> updateMedley(
    String id,
    CreateMedleyInputEntity input,
  ) async => MedleyEntity(id: id, name: input.name);

  @override
  Future<void> deleteMedley(String id) async {}
}

// ---------------------------------------------------------------------------
// Test app builder
// ---------------------------------------------------------------------------

Widget _buildApp({MedleyEntity? medley}) {
  return MaterialApp(
    home: BlocProvider<MedleyCubit>(
      create: (_) => MedleyCubit(_FakeMedleyRepository()),
      child: Builder(
        builder: (ctx) => Scaffold(
          body: ElevatedButton(
            onPressed: () =>
                showMedleyFormSheet(ctx, songs: const [], medley: medley),
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester, {MedleyEntity? medley}) async {
  await tester.pumpWidget(_buildApp(medley: medley));
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MedleyFormSheet — modo criação', () {
    testWidgets('exibe título "Novo Medley"', (tester) async {
      await _openSheet(tester);

      expect(find.text('Novo Medley'), findsOneWidget);
    });

    testWidgets('exibe botão "Criar Medley"', (tester) async {
      await _openSheet(tester);

      expect(find.text('Criar Medley'), findsOneWidget);
    });

    testWidgets('rejeita nome com menos de 3 caracteres', (tester) async {
      await _openSheet(tester);

      await tester.enterText(find.byType(TextFormField).first, 'ab');
      final saveFinder = find.text('Criar Medley');
      await tester.ensureVisible(saveFinder);
      await tester.tap(saveFinder);
      await tester.pump();

      expect(find.text('Mínimo de 3 caracteres.'), findsOneWidget);
    });

    testWidgets('aceita nome com 3 ou mais caracteres', (tester) async {
      await _openSheet(tester);

      await tester.enterText(find.byType(TextFormField).first, 'abc');
      final saveFinder = find.text('Criar Medley');
      await tester.ensureVisible(saveFinder);
      await tester.tap(saveFinder);
      await tester.pump();

      expect(find.text('Mínimo de 3 caracteres.'), findsNothing);
    });

    testWidgets(
      'exibe snackbar quando salva sem adicionar músicas',
      (tester) async {
        await _openSheet(tester);

        await tester.enterText(
          find.byType(TextFormField).first,
          'Medley válido',
        );
        final saveFinder = find.text('Criar Medley');
        await tester.ensureVisible(saveFinder);
        await tester.tap(saveFinder);
        await tester.pump();

        expect(
          find.text('Adicione pelo menos uma música ao medley.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'campo de nome começa vazio no modo criação',
      (tester) async {
        await _openSheet(tester);

        final nameField = tester.widget<TextFormField>(
          find.byType(TextFormField).first,
        );
        expect(nameField.controller?.text, isEmpty);
      },
    );
  });

  group('MedleyFormSheet — modo edição', () {
    MedleyEntity _editMedley() => MedleyEntity(
      id: 'm1',
      name: 'Abertura',
      description: 'Músicas de início',
      items: [
        MedleyItemEntity(
          id: 'item1',
          songId: 's1',
          songTitle: 'Oceans',
          songArtist: 'Hillsong',
          key: 'G',
          sequence: 1,
        ),
      ],
    );

    testWidgets('exibe título "Editar Medley"', (tester) async {
      await _openSheet(tester, medley: _editMedley());

      expect(find.text('Editar Medley'), findsOneWidget);
    });

    testWidgets('exibe botão "Salvar alterações"', (tester) async {
      await _openSheet(tester, medley: _editMedley());

      expect(find.text('Salvar alterações'), findsOneWidget);
    });

    testWidgets('pré-preenche o campo de nome', (tester) async {
      await _openSheet(tester, medley: _editMedley());

      final nameField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(nameField.controller?.text, 'Abertura');
    });

    testWidgets('pré-preenche o campo de descrição', (tester) async {
      await _openSheet(tester, medley: _editMedley());

      final descField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(1),
      );
      expect(descField.controller?.text, 'Músicas de início');
    });

    testWidgets('exibe o item de música existente na lista', (tester) async {
      await _openSheet(tester, medley: _editMedley());

      expect(find.text('Oceans'), findsOneWidget);
    });
  });
}
