import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/events/domain/entities/project_member_entity.dart';
import 'package:louvor4_app/features/events/domain/entities/skill_entity.dart';

void main() {
  test('mapeia skills string do membro para skill ids do projeto', () {
    final member = ProjectMemberEntity.fromJson(
      {
        'id': 'm1',
        'userId': 'u1',
        'firstName': 'Ana',
        'lastName': 'Silva',
        'projectRole': 'VOCAL',
        'skills': ['Vocal', 'Violao'],
      },
      projectSkillsCatalog: const [
        SkillEntity(id: 's1', name: 'Vocal'),
        SkillEntity(id: 's2', name: 'Violao'),
      ],
    );

    expect(member.skills.map((skill) => skill.id), ['s1', 's2']);
    expect(member.skillNames, {'Vocal', 'Violao'});
    expect(member.userId, 'u1');
  });
}
