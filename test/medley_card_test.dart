import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/medleys/domain/entities/medley_entity.dart';
import 'package:louvor4_app/features/medleys/domain/entities/medley_item_entity.dart';
import 'package:louvor4_app/features/medleys/presentation/widgets/medley_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

MedleyEntity _medley({
  String name = 'Abertura',
  String? description,
  int itemCount = 0,
}) {
  return MedleyEntity(
    id: 'm1',
    name: name,
    description: description,
    items: List.generate(itemCount, (i) => MedleyItemEntity(sequence: i)),
  );
}

void main() {
  group('MedleyCard', () {
    testWidgets('exibe o nome do medley', (tester) async {
      await tester.pumpWidget(
        _wrap(MedleyCard(
          medley: _medley(name: 'Culto de Louvor'),
          onEdit: () {},
          onDelete: () {},
        )),
      );

      expect(find.text('Culto de Louvor'), findsOneWidget);
    });

    testWidgets('exibe a descrição quando presente', (tester) async {
      await tester.pumpWidget(
        _wrap(MedleyCard(
          medley: _medley(description: 'Músicas de abertura'),
          onEdit: () {},
          onDelete: () {},
        )),
      );

      expect(find.text('Músicas de abertura'), findsOneWidget);
    });

    testWidgets('não exibe descrição quando null', (tester) async {
      await tester.pumpWidget(
        _wrap(MedleyCard(
          medley: _medley(description: null),
          onEdit: () {},
          onDelete: () {},
        )),
      );

      // Only the name and item count should be visible — no description text.
      expect(find.text('Músicas de abertura'), findsNothing);
    });

    testWidgets('exibe contagem no singular: "1 música"', (tester) async {
      await tester.pumpWidget(
        _wrap(MedleyCard(
          medley: _medley(itemCount: 1),
          onEdit: () {},
          onDelete: () {},
        )),
      );

      expect(find.text('1 música'), findsOneWidget);
    });

    testWidgets('exibe contagem no plural: "N músicas"', (tester) async {
      await tester.pumpWidget(
        _wrap(MedleyCard(
          medley: _medley(itemCount: 4),
          onEdit: () {},
          onDelete: () {},
        )),
      );

      expect(find.text('4 músicas'), findsOneWidget);
    });

    testWidgets('dispara onEdit ao tocar no botão de editar', (tester) async {
      var editCalled = false;

      await tester.pumpWidget(
        _wrap(MedleyCard(
          medley: _medley(),
          onEdit: () => editCalled = true,
          onDelete: () {},
        )),
      );

      await tester.tap(find.byIcon(Icons.edit_outlined));
      expect(editCalled, isTrue);
    });

    testWidgets('dispara onDelete ao tocar no botão de excluir', (tester) async {
      var deleteCalled = false;

      await tester.pumpWidget(
        _wrap(MedleyCard(
          medley: _medley(),
          onEdit: () {},
          onDelete: () => deleteCalled = true,
        )),
      );

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(deleteCalled, isTrue);
    });

    testWidgets('exibe "0 músicas" quando não há itens', (tester) async {
      await tester.pumpWidget(
        _wrap(MedleyCard(
          medley: _medley(itemCount: 0),
          onEdit: () {},
          onDelete: () {},
        )),
      );

      expect(find.text('0 músicas'), findsOneWidget);
    });
  });
}
