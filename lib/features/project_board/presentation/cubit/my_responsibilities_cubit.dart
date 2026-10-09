import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/responsibilities_repository.dart';
import '../../domain/entities/my_responsibility_entity.dart';

/// Responsabilidades do usuário para o card da tela de Início.
/// Falhas são silenciosas: o card só não aparece (não atrapalha os eventos).
class MyResponsibilitiesCubit extends Cubit<List<MyResponsibilityEntity>> {
  final ResponsibilitiesRepository _repository;

  MyResponsibilitiesCubit(this._repository) : super(const []);

  Future<void> load() async {
    try {
      final items = await _repository.getMyResponsibilities();
      if (!isClosed) emit(items);
    } catch (_) {
      // Mantém o último estado conhecido
    }
  }
}
