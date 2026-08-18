import 'package:equatable/equatable.dart';

class SongCategoryEntity extends Equatable {
  final String id;
  final String name;

  const SongCategoryEntity({required this.id, required this.name});

  factory SongCategoryEntity.fromJson(Map<String, dynamic> json) {
    return SongCategoryEntity(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [id, name];
}
