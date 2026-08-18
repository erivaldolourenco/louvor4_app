import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/song_categories/data/song_categories_repository.dart';
import 'package:louvor4_app/features/song_categories/domain/entities/song_category_entity.dart';
import 'package:louvor4_app/features/song_categories/presentation/cubit/song_categories_cubit.dart';
import 'package:louvor4_app/features/song_categories/presentation/cubit/song_categories_state.dart';

class _FakeSongCategoriesRepository implements SongCategoriesRepository {
  _FakeSongCategoriesRepository({
    this.categories = const [],
    this.throwOnCreate,
    this.throwOnUpdate,
    this.throwOnDelete,
  });

  List<SongCategoryEntity> categories;
  Exception? throwOnCreate;
  Exception? throwOnUpdate;
  Exception? throwOnDelete;
  String? lastCreatedName;
  String? lastUpdatedName;
  String? deletedCategoryId;

  @override
  Future<List<SongCategoryEntity>> getSongCategories() async => categories;

  @override
  Future<SongCategoryEntity> createSongCategory(String name) async {
    if (throwOnCreate != null) throw throwOnCreate!;
    lastCreatedName = name;
    final created = SongCategoryEntity(id: 'new-category', name: name);
    categories = [...categories, created];
    return created;
  }

  @override
  Future<SongCategoryEntity> updateSongCategory(
    String categoryId,
    String name,
  ) async {
    if (throwOnUpdate != null) throw throwOnUpdate!;
    lastUpdatedName = name;
    final updated = SongCategoryEntity(id: categoryId, name: name);
    categories = categories
        .map((item) => item.id == categoryId ? updated : item)
        .toList();
    return updated;
  }

  @override
  Future<void> deleteSongCategory(String categoryId) async {
    if (throwOnDelete != null) throw throwOnDelete!;
    deletedCategoryId = categoryId;
    categories = categories.where((item) => item.id != categoryId).toList();
  }
}

void main() {
  group('SongCategoriesCubit', () {
    test('carrega categorias ordenadas por nome', () async {
      final repo = _FakeSongCategoriesRepository(
        categories: const [
          SongCategoryEntity(id: '2', name: 'Natal'),
          SongCategoryEntity(id: '1', name: 'Adoração'),
        ],
      );

      final cubit = SongCategoriesCubit(repo);
      await cubit.load();

      expect(cubit.state.status, SongCategoriesStatus.success);
      expect(cubit.state.categories.map((c) => c.name), ['Adoração', 'Natal']);

      await cubit.close();
    });

    test('estado fica vazio quando não há categorias', () async {
      final cubit = SongCategoriesCubit(_FakeSongCategoriesRepository());
      await cubit.load();

      expect(cubit.state.isEmpty, isTrue);

      await cubit.close();
    });

    test('cria categoria e recarrega a lista', () async {
      final repo = _FakeSongCategoriesRepository(
        categories: const [SongCategoryEntity(id: '1', name: 'Adoração')],
      );
      final cubit = SongCategoriesCubit(repo);
      await cubit.load();

      final created = await cubit.createCategory('Natal');

      expect(created, isTrue);
      expect(repo.lastCreatedName, 'Natal');
      expect(
        cubit.state.categories.map((c) => c.name),
        containsAll(['Adoração', 'Natal']),
      );

      await cubit.close();
    });

    test('não cria categoria com nome vazio', () async {
      final repo = _FakeSongCategoriesRepository();
      final cubit = SongCategoriesCubit(repo);
      await cubit.load();

      final created = await cubit.createCategory('   ');

      expect(created, isFalse);
      expect(repo.lastCreatedName, isNull);
      expect(cubit.state.actionErrorMessage, contains('nome'));

      await cubit.close();
    });

    test('não cria categoria com nome maior que 50 caracteres', () async {
      final repo = _FakeSongCategoriesRepository();
      final cubit = SongCategoriesCubit(repo);
      await cubit.load();

      final created = await cubit.createCategory('a' * 51);

      expect(created, isFalse);
      expect(repo.lastCreatedName, isNull);
      expect(cubit.state.actionErrorMessage, contains('50'));

      await cubit.close();
    });

    test('propaga mensagem da API ao tentar criar categoria duplicada', () async {
      final repo = _FakeSongCategoriesRepository(
        throwOnCreate: Exception('Você já tem uma categoria com esse nome.'),
      );
      final cubit = SongCategoriesCubit(repo);
      await cubit.load();

      final created = await cubit.createCategory('Adoração');

      expect(created, isFalse);
      expect(
        cubit.state.actionErrorMessage,
        'Você já tem uma categoria com esse nome.',
      );

      await cubit.close();
    });

    test('atualiza (renomeia) categoria e recarrega a lista', () async {
      final repo = _FakeSongCategoriesRepository(
        categories: const [SongCategoryEntity(id: '1', name: 'Adoração')],
      );
      final cubit = SongCategoriesCubit(repo);
      await cubit.load();

      final updated = await cubit.updateCategory(
        const SongCategoryEntity(id: '1', name: 'Adoração'),
        'Louvor',
      );

      expect(updated, isTrue);
      expect(repo.lastUpdatedName, 'Louvor');
      expect(cubit.state.categories.single.name, 'Louvor');

      await cubit.close();
    });

    test('exclui categoria', () async {
      final repo = _FakeSongCategoriesRepository(
        categories: const [SongCategoryEntity(id: '1', name: 'Adoração')],
      );
      final cubit = SongCategoriesCubit(repo);
      await cubit.load();

      final deleted = await cubit.deleteCategory(
        const SongCategoryEntity(id: '1', name: 'Adoração'),
      );

      expect(deleted, isTrue);
      expect(repo.deletedCategoryId, '1');
      expect(cubit.state.categories, isEmpty);

      await cubit.close();
    });

    test('propaga erro de permissão ao excluir categoria de outro usuário', () async {
      final repo = _FakeSongCategoriesRepository(
        categories: const [SongCategoryEntity(id: '1', name: 'Adoração')],
        throwOnDelete: Exception('Acesso negado.'),
      );
      final cubit = SongCategoriesCubit(repo);
      await cubit.load();

      final deleted = await cubit.deleteCategory(
        const SongCategoryEntity(id: '1', name: 'Adoração'),
      );

      expect(deleted, isFalse);
      expect(cubit.state.actionErrorMessage, 'Acesso negado.');
      expect(cubit.state.categories, isNotEmpty);

      await cubit.close();
    });
  });
}
