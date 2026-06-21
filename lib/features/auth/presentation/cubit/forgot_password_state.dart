import 'package:equatable/equatable.dart';

import '../../domain/entities/forgot_password_channels_entity.dart';

enum ForgotPasswordStatus { initial, loading, channelsLoaded, codeSent, success, failure }

class ForgotPasswordState extends Equatable {
  final ForgotPasswordStatus status;
  final int step; // 1: email, 2: escolha do canal, 3: código + nova senha
  final String identifier;
  final ForgotPasswordChannelsEntity? channels;
  final String selectedChannel; // 'EMAIL' ou 'SMS'
  final String code;
  final String newPassword;
  final String? errorMessage;

  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.initial,
    this.step = 1,
    this.identifier = '',
    this.channels,
    this.selectedChannel = 'EMAIL',
    this.code = '',
    this.newPassword = '',
    this.errorMessage,
  });

  bool get isLoading => status == ForgotPasswordStatus.loading;

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    int? step,
    String? identifier,
    ForgotPasswordChannelsEntity? channels,
    String? selectedChannel,
    String? code,
    String? newPassword,
    String? errorMessage,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      step: step ?? this.step,
      identifier: identifier ?? this.identifier,
      channels: channels ?? this.channels,
      selectedChannel: selectedChannel ?? this.selectedChannel,
      code: code ?? this.code,
      newPassword: newPassword ?? this.newPassword,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status, step, identifier, channels, selectedChannel, code, newPassword, errorMessage,
  ];
}
