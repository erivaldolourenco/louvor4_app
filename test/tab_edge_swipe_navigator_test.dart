import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/core/ui/widgets/tab_edge_swipe_navigator.dart';

void main() {
  Widget buildHarness({
    required TabController controller,
    VoidCallback? onSwipePastLast,
    VoidCallback? onSwipePastFirst,
    Object? arrivalToken,
    bool arrivalLandOnLast = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: TabEdgeSwipeNavigator(
          controller: controller,
          onSwipePastLast: onSwipePastLast,
          onSwipePastFirst: onSwipePastFirst,
          arrivalToken: arrivalToken,
          arrivalLandOnLast: arrivalLandOnLast,
          child: TabBarView(
            controller: controller,
            children: const [
              Center(child: Text('Tab 0')),
              Center(child: Text('Tab 1')),
              Center(child: Text('Tab 2')),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets(
    'dispara onSwipePastLast ao arrastar além da última aba',
    (tester) async {
      final controller = TabController(
        length: 3,
        vsync: const TestVSync(),
        initialIndex: 2,
      );
      addTearDown(controller.dispose);
      var calledNext = false;

      await tester.pumpWidget(
        buildHarness(controller: controller, onSwipePastLast: () => calledNext = true),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(TabBarView), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(calledNext, isTrue);
    },
  );

  testWidgets(
    'dispara onSwipePastFirst ao arrastar além da primeira aba',
    (tester) async {
      final controller = TabController(length: 3, vsync: const TestVSync());
      addTearDown(controller.dispose);
      var calledPrevious = false;

      await tester.pumpWidget(
        buildHarness(
          controller: controller,
          onSwipePastFirst: () => calledPrevious = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(TabBarView), const Offset(600, 0));
      await tester.pumpAndSettle();

      expect(calledPrevious, isTrue);
    },
  );

  testWidgets(
    'não dispara nenhum callback quando ainda há abas internas pra navegar',
    (tester) async {
      final controller = TabController(length: 3, vsync: const TestVSync());
      addTearDown(controller.dispose);
      var calledNext = false;
      var calledPrevious = false;

      await tester.pumpWidget(
        buildHarness(
          controller: controller,
          onSwipePastLast: () => calledNext = true,
          onSwipePastFirst: () => calledPrevious = true,
        ),
      );
      await tester.pumpAndSettle();

      // Do índice 0, arrastar pra esquerda deve só trocar de aba interna
      // (ainda há a aba 1 e 2 à frente), sem acionar o callback de página.
      await tester.drag(find.byType(TabBarView), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(calledNext, isFalse);
      expect(calledPrevious, isFalse);
    },
  );

  testWidgets(
    'anima para a última aba quando arrivalToken muda com landOnLast',
    (tester) async {
      final controller = TabController(length: 3, vsync: const TestVSync());
      addTearDown(controller.dispose);

      await tester.pumpWidget(buildHarness(controller: controller));
      await tester.pumpAndSettle();
      expect(controller.index, 0);

      await tester.pumpWidget(
        buildHarness(
          controller: controller,
          arrivalToken: 1,
          arrivalLandOnLast: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.index, 2);
    },
  );

  testWidgets(
    'anima para a primeira aba quando arrivalToken muda sem landOnLast',
    (tester) async {
      final controller = TabController(
        length: 3,
        vsync: const TestVSync(),
        initialIndex: 2,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(buildHarness(controller: controller));
      await tester.pumpAndSettle();
      expect(controller.index, 2);

      await tester.pumpWidget(
        buildHarness(controller: controller, arrivalToken: 1),
      );
      await tester.pumpAndSettle();

      expect(controller.index, 0);
    },
  );

  // O app hospedeiro (root_page.dart) recria a página inteira — inclusive
  // o TabController — a cada navegação, em vez de reaproveitar o mesmo
  // widget. Isso significa que o arrivalToken já vem preenchido logo na
  // primeira montagem (via initState), não numa atualização posterior
  // (didUpdateWidget) — é esse caminho que os dois testes abaixo cobrem.
  testWidgets(
    'já aplica o arrivalToken na primeira montagem (landOnLast)',
    (tester) async {
      final controller = TabController(length: 3, vsync: const TestVSync());
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildHarness(controller: controller, arrivalToken: 1, arrivalLandOnLast: true),
      );
      await tester.pumpAndSettle();

      expect(controller.index, 2);
    },
  );

  testWidgets(
    'já aplica o arrivalToken na primeira montagem (primeira aba)',
    (tester) async {
      final controller = TabController(
        length: 3,
        vsync: const TestVSync(),
        initialIndex: 2,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildHarness(controller: controller, arrivalToken: 1),
      );
      await tester.pumpAndSettle();

      expect(controller.index, 0);
    },
  );
}
