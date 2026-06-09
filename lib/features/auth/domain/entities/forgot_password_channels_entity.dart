class ForgotPasswordChannelsEntity {
  final String maskedEmail;
  final String? maskedPhone;

  const ForgotPasswordChannelsEntity({
    required this.maskedEmail,
    this.maskedPhone,
  });

  bool get hasSms => maskedPhone != null;
}
