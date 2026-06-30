import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';

class RedeemVoucherPage extends StatefulWidget {
  static const routeName = '/alterar-plano';

  final String? currentPlanName;

  const RedeemVoucherPage({super.key, this.currentPlanName});

  @override
  State<RedeemVoucherPage> createState() => _RedeemVoucherPageState();
}

class _RedeemVoucherPageState extends State<RedeemVoucherPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  String? _fieldError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    if (value.trim().isEmpty) return 'Informe o código do voucher.';
    if (value.trim().length < 4) return 'Código muito curto.';
    return null;
  }

  Future<void> _redeem() async {
    final code = _controller.text.trim().toUpperCase();
    final error = _validate(code);
    if (error != null) {
      setState(() => _fieldError = error);
      return;
    }

    setState(() {
      _isLoading = true;
      _fieldError = null;
    });

    try {
      final response = await ApiClient.dio.post(
        '/vouchers/redeem',
        data: {'code': code},
      );

      final data = response.data;
      final newPlan = (data is Map)
          ? (data['planName'] ?? data['plan_name'] ?? data['plan'])
                ?.toString()
          : null;

      if (!mounted) return;

      final msg = newPlan != null && newPlan.isNotEmpty
          ? 'Seu voucher foi aplicado, sua conta agora é $newPlan'
          : 'Voucher aplicado com sucesso!';

      AppFeedback.showSuccess(msg);
      Navigator.of(context).pop(newPlan ?? true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _fieldError = extractApiErrorMessage(
            e,
            fallback: 'Não foi possível aplicar o voucher.',
          ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: const StandardSectionAppBar(
        title: 'Alterar Plano',
        subtitle: 'Use um voucher para ativar um novo plano',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            children: [
              AppCardSurface(
                padding: const EdgeInsets.all(24),
                radius: 24,
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.confirmation_number_outlined,
                        size: 36,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Usar voucher',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Digite o código do seu voucher para ativar ou alterar seu plano.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (widget.currentPlanName != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium_outlined,
                              size: 16,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Plano atual: ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              widget.currentPlanName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !_isLoading,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9\-_]'),
                        ),
                        _UpperCaseFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Código do voucher',
                        hintText: 'Ex: LOUVOR-2025',
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        errorText: _fieldError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.input),
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainerLowest,
                      ),
                      onChanged: (_) {
                        if (_fieldError != null) {
                          setState(() => _fieldError = null);
                        }
                      },
                      onSubmitted: (_) => _isLoading ? null : _redeem(),
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      onPressed: _isLoading ? null : _redeem,
                      icon: Icons.check_rounded,
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : const Text('Aplicar voucher'),
                    ),
                    const SizedBox(height: 10),
                    AppSecondaryButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
