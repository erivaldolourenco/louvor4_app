import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/responsibilities_repository.dart';
import '../../domain/entities/responsibility_entity.dart';
import 'project_board_state.dart';

class ProjectBoardCubit extends Cubit<ProjectBoardState> {
  static const maxNameLength = 80;
  static const maxDescriptionLength = 500;

  final ResponsibilitiesRepository _repository;
  final String projectId;

  ProjectBoardCubit(this._repository, {required this.projectId})
    : super(const ProjectBoardState());

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(
        state.copyWith(
          status: ProjectBoardStatus.loading,
          clearErrorMessage: true,
        ),
      );
    }
    try {
      final items = await _repository.getResponsibilities(projectId);
      emit(
        state.copyWith(
          status: ProjectBoardStatus.success,
          responsibilities: items,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ProjectBoardStatus.failure,
          errorMessage: _message(e),
        ),
      );
    }
  }

  /// Cria ou edita o nome/descrição da responsabilidade. Responsáveis e
  /// períodos são adicionados pelo histórico. Retorna a responsabilidade
  /// salva, ou `null` em caso de erro (mensagem em `actionErrorMessage`).
  Future<ResponsibilityEntity?> save({
    ResponsibilityEntity? existing,
    required String name,
    String? description,
  }) async {
    final normalizedName = name.trim();
    final normalizedDescription = (description ?? '').trim().isEmpty
        ? null
        : description!.trim();

    if (existing != null &&
        existing.name == normalizedName &&
        existing.description == normalizedDescription) {
      return existing;
    }

    emit(state.copyWith(isSaving: true, clearActionErrorMessage: true));
    try {
      final saved = existing == null
          ? await _repository.createResponsibility(
              projectId,
              name: normalizedName,
              description: normalizedDescription,
            )
          : await _repository.updateResponsibility(
              projectId,
              existing.id,
              name: normalizedName,
              description: normalizedDescription,
            );
      emit(state.copyWith(isSaving: false));
      await load(silent: true);
      return saved;
    } catch (e) {
      emit(state.copyWith(isSaving: false, actionErrorMessage: _message(e)));
      return null;
    }
  }

  Future<bool> delete(ResponsibilityEntity responsibility) async {
    emit(
      state.copyWith(
        deletingId: responsibility.id,
        clearActionErrorMessage: true,
      ),
    );
    try {
      await _repository.deleteResponsibility(projectId, responsibility.id);
      emit(
        state.copyWith(
          clearDeletingId: true,
          responsibilities: state.responsibilities
              .where((r) => r.id != responsibility.id)
              .toList(),
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(clearDeletingId: true, actionErrorMessage: _message(e)),
      );
      return false;
    }
  }

  String _message(Object e) => e.toString().replaceFirst('Exception: ', '');
}
