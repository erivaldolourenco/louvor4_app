import 'package:flutter/material.dart';

/// Todos os tokens de cor do app.
///
/// Organização:
///   brand   — cor primária e suas variantes
///   surface — fundos de tela e cards
///   text    — cores de texto
///   border  — bordas e divisores
///   danger  — erros e ações destrutivas
///   success — confirmações e sucesso
///   warning — alertas e avisos
///   tint    — fundos sutis de ícones e badges
abstract final class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────────

  /// Cor principal: botões primários, FABs, destaques.
  static const primary = Color(0xFF2563EB);

  /// Variante mais escura: pressed / hover.
  static const primaryDark = Color(0xFF1D4ED8);

  /// Variante mais brilhante: ícones de destaque, links.
  static const primaryBright = Color(0xFF0166FF);

  /// Texto / ícone sobre fundo primary.
  static const onPrimary = Colors.white;

  // ── Surface ──────────────────────────────────────────────────────────────

  /// Fundo do Scaffold no tema claro.
  static const scaffoldLight = Colors.white;

  /// Fundo do Scaffold no tema escuro.
  static const scaffoldDark = Color(0xFF0F172A);

  /// Cards e superfícies principais no tema claro.
  static const surfaceLight = Colors.white;

  /// Cards e superfícies principais no tema escuro.
  static const surfaceDark = Color(0xFF111827);

  /// Superfície ligeiramente elevada no tema claro (ex: input background).
  static const surfaceElevatedLight = Color(0xFFF8FAFC);

  /// Superfície ligeiramente elevada no tema escuro.
  static const surfaceElevatedDark = Color(0xFF1E293B);

  /// Superfície mais recuada no tema claro (chips, tab bar bg).
  static const surfaceSubtleLight = Color(0xFFF1F5F9);

  /// Superfície mais recuada no tema escuro.
  static const surfaceSubtleDark = Color(0xFF334155);

  // ── Text ─────────────────────────────────────────────────────────────────

  /// Texto principal no tema claro.
  static const textPrimaryLight = Color(0xFF4D4D4D);

  /// Texto principal no tema escuro.
  static const textPrimaryDark = Colors.white;

  /// Texto secundário / placeholders no tema claro.
  static const textMutedLight = Color(0xFF64748B);

  /// Texto secundário / placeholders no tema escuro.
  static const textMutedDark = Color(0xFF94A3B8);

  /// Texto ainda mais apagado no tema claro.
  static const textSubtleLight = Color(0xFF6B7280);

  /// Texto ainda mais apagado no tema escuro.
  static const textSubtleDark = Color(0xFF475569);

  // ── Border ───────────────────────────────────────────────────────────────

  /// Borda padrão no tema claro.
  static const borderLight = Color(0xFFE2E8F0);

  /// Borda padrão no tema escuro.
  static const borderDark = Color(0xFF1E293B);

  /// Borda mais visível no tema claro.
  static const borderStrongLight = Color(0xFFDCE3EC);

  /// Borda mais visível no tema escuro.
  static const borderStrongDark = Color(0xFF243041);

  /// Borda sutil no tema claro.
  static const borderSubtleLight = Color(0xFFCBD5E1);

  /// Borda sutil no tema escuro.
  static const borderSubtleDark = Color(0xFF334155);

  // ── Danger ───────────────────────────────────────────────────────────────

  static const danger = Color(0xFFB3261E);
  static const dangerBright = Color(0xFFEF4444);
  static const onDanger = Colors.white;

  static const dangerSubtleLight = Color(0xFFFEE2E2);
  static const dangerSubtleDark = Color(0xFF3F1114);

  static const dangerBorderLight = Color(0xFFFCA5A5);
  static const dangerBorderDark = Color(0xFF7F1D1D);

  static const dangerTextLight = Color(0xFF991B1B);
  static const dangerTextDark = Color(0xFFFCA5A5);

  // ── Success ──────────────────────────────────────────────────────────────

  static const success = Color(0xFF2E7D32);
  static const successBright = Color(0xFF10B981);
  static const onSuccess = Colors.white;

  static const successSubtleLight = Color(0xFFE8FBF3);
  static const successSubtleDark = Color(0xFF123227);

  // ── Warning ──────────────────────────────────────────────────────────────

  static const warning = Color(0xFFF59E0B);
  static const onWarning = Colors.white;

  static const warningSubtleLight = Color(0xFFFFF6E5);
  static const warningSubtleDark = Color(0xFF3F2A13);

  // ── Primary tints (fundos sutis para ícones/badges azuis) ────────────────

  static const primarySubtleLight = Color(0xFFEFF6FF);
  static const primarySubtleDark = Color(0xFF172554);

  static const primaryBorderLight = Color(0xFFBFDBFE);
  static const primaryBorderDark = Color(0xFF1E3A8A);

  // ── Form fields ──────────────────────────────────────────────────────────

  /// Fundo de inputs no tema claro (branco azulado).
  static const inputFillLight = Color(0xFFF6F8FF);

  /// Borda de inputs no tema claro.
  static const inputBorderLight = Color(0xFFE5E7EB);

  /// Placeholder / hint no tema claro.
  static const hintLight = Color(0xFF9CA3AF);

  // ── Secondary button ─────────────────────────────────────────────────────

  /// Fundo do botão secundário (outlined) no tema claro.
  static const secondaryButtonBgLight = Color(0xFFF8FBFF);

  /// Borda do botão secundário no tema claro.
  static const secondaryButtonBorderLight = Color(0xFFD6E4FF);

  /// Texto/ícone do botão secundário no tema escuro.
  static const secondaryButtonFgDark = Color(0xFFE2E8F0);

  // ── Shadows ──────────────────────────────────────────────────────────────

  static const shadowLight = Color(0x140F172A);
  static const shadowDark = Color(0x33000000);

  static const primaryShadow = Color(0x662563EB);

  /// Sombra do botão primário (pill button).
  static const primaryButtonShadow = Color(0x330166FF);

  /// Sombra do sheet no tema claro.
  static const sheetShadowLight = Color(0x140166FF);

  /// Sombra do container de ícone no tema escuro.
  static const iconContainerShadowDark = Color(0x22000000);

  /// Sombra do container de ícone no tema claro.
  static const iconContainerShadowLight = Color(0x12000000);
}
