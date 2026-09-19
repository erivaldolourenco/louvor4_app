import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/core/utils/skill_icon.dart';

void main() {
  group('skillIconAsset — novos ícones de mídia', () {
    const expectedAssetByKey = {
      'CAMERA': 'assets/icons/skills-icons/camera.svg',
      'COMPUTER': 'assets/icons/skills-icons/computer.svg',
      'MOBILE_PHONE': 'assets/icons/skills-icons/mobile-phone.svg',
      'NOTEBOOK_MUSIC': 'assets/icons/skills-icons/notebook-music.svg',
    };

    expectedAssetByKey.forEach((key, expectedAsset) {
      test('mapeia $key para $expectedAsset', () {
        expect(skillIconAsset(key), expectedAsset);
      });

      test('tem label cadastrado para $key', () {
        expect(skillIconLabels.containsKey(key), isTrue);
      });
    });

    test('usa exatamente as chaves UPPER_SNAKE_CASE da API, não slugs kebab-case', () {
      const kebabSlugs = ['camera', 'computer', 'mobile-phone', 'notebook-music'];
      for (final slug in kebabSlugs) {
        expect(skillIconAssets.containsKey(slug), isFalse);
      }
    });
  });
}
