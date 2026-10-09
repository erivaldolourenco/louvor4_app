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
  // ── Brand palette (índigo) ───────────────────────────────────────────────
  // Escala única do azul da marca, do mais claro (50) ao mais escuro (950).
  // Todo azul do app sai daqui — ColorScheme, tints, sombras e notificação.
  // Evite hex de azul soltos em widgets.

  static const indigo50 = Color(0xFFEEF2FF);
  static const indigo100 = Color(0xFFE0E7FF);
  static const indigo200 = Color(0xFFC7D2FE);
  static const indigo300 = Color(0xFFA5B4FC);
  static const indigo400 = Color(0xFF818CF8);
  static const indigo500 = Color(0xFF6366F1);
  static const indigo600 = Color(0xFF4F46E5);
  static const indigo700 = Color(0xFF4338CA);
  static const indigo800 = Color(0xFF3730A3);
  static const indigo900 = Color(0xFF312E81);
  static const indigo950 = Color(0xFF1E1B4B);

  // ── Brand ────────────────────────────────────────────────────────────────

  /// Cor principal no tema claro: botões primários, FABs, destaques.
  static const primary = indigo600;

  /// Cor principal no tema escuro — um passo mais clara que a do tema claro,
  /// pra manter o destaque sobre o fundo escuro.
  static const brandPrimary = indigo500;

  /// Variante mais escura: pressed / hover.
  static const primaryDark = indigo700;

  /// Fundo de botões preenchidos (FilledButton, FAB, AppPrimaryButton) nos
  /// dois temas. No escuro o primary (indigo500) fica abaixo de 4.5:1 com
  /// texto branco, então os botões usam um passo mais escuro.
  static const primaryButton = indigo600;

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
  static const surfaceDark = Color(0xFF1E293B);

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
  static const textPrimaryLight = Color(0xFF0F172A);

  /// Texto principal no tema escuro.
  static const textPrimaryDark = Color(0xFFF8FAFC);

  /// Texto secundário / placeholders no tema claro.
  static const textMutedLight = Color(0xFF475569);

  /// Texto secundário / placeholders no tema escuro.
  static const textMutedDark = Color(0xFF94A3B8);

  /// Texto ainda mais apagado no tema claro.
  static const textSubtleLight = Color(0xFF6B7280);

  /// Texto ainda mais apagado no tema escuro.
  static const textSubtleDark = Color(0xFF8494AB);

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

  static const warningTextLight = Color(0xFF92400E);
  static const warningTextDark = Color(0xFFFCD34D);

  // ── Tertiary (Destaques musicais: tom, bpm, badges vibrantes) ─────────────

  /// Cor terciária (âmbar/dourado musical vibrante).
  static const tertiary = Color(0xFFD97706);

  /// Variante terciária escura/hover.
  static const tertiaryDark = Color(0xFFB45309);

  /// Texto / ícone sobre fundo tertiary.
  static const onTertiary = Colors.white;

  /// Fundo sutil de container terciário no tema claro.
  static const tertiaryContainerLight = Color(0xFFFEF3C7);

  /// Fundo sutil de container terciário no tema escuro.
  static const tertiaryContainerDark = Color(0xFF451A03);

  /// Texto sobre container terciário no tema claro.
  static const onTertiaryContainerLight = Color(0xFF92400E);

  /// Texto sobre container terciário no tema escuro.
  static const onTertiaryContainerDark = Color(0xFFFDE68A);

  /// Âmbar quente escurecido usado como tertiary no tema claro (tom/BPM) —
  /// mesma família do [tertiaryWarmDark], mas com contraste ≥ 4.5:1 sobre
  /// branco e com texto branco por cima.
  static const tertiaryWarmLight = Color(0xFFB45309);

  /// Âmbar quente usado como tertiary no tema escuro (tom/BPM). Sobre ele,
  /// use texto escuro — branco não passa no contraste mínimo.
  static const tertiaryWarmDark = Color(0xFFE09F3E);
  static const onTertiaryWarmDark = Color(0xFF0F172A);

  // ── Pending (status "Pendente") ──────────────────────────────────────────
  // Laranja em vez de âmbar, pra não confundir status com o destaque musical
  // (tom/BPM), que já usa a família âmbar do tertiary.

  static const pendingContainerLight = Color(0xFFFFEDD5);
  static const onPendingContainerLight = Color(0xFF9A3412);
  static const pendingContainerDark = Color(0xFF3B1D0E);
  static const onPendingContainerDark = Color(0xFFFDBA74);

  // ── Confirmed (status "Aceito"/"Confirmado") ─────────────────────────────

  static const onSuccessContainerLight = Color(0xFF047857);
  static const onSuccessContainerDark = Color(0xFF34D399);

  // ── Arrangement (tags de arranjo/categoria — teal) ───────────────────────
  // Fundo translúcido + texto teal claro no escuro: texto branco sobre o
  // teal sólido (#0D9488) fica abaixo de 4.5:1.

  static const arrangementLight = Color(0xFF0F766E);
  static const arrangementContainerLight = Color(0xFFCCFBF1);
  static const arrangementDark = Color(0xFF5EEAD4);
  static const arrangementContainerDark = Color(0xFF113B3A);

  // ── M3 Surface Containers ───────────────────────────────────────────────

  static const surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const surfaceContainerLowLight = Color(0xFFF8FAFC);
  static const surfaceContainerLight = Color(0xFFF1F5F9);
  static const surfaceContainerHighLight = Color(0xFFE2E8F0);
  static const surfaceContainerHighestLight = Color(0xFFCBD5E1);

  static const surfaceContainerLowestDark = Color(0xFF0F172A);
  static const surfaceContainerLowDark = Color(0xFF1E293B);
  static const surfaceContainerDark = Color(0xFF273449);
  static const surfaceContainerHighDark = Color(0xFF334155);
  static const surfaceContainerHighestDark = Color(0xFF475569);

  // ── Primary tints (fundos sutis para ícones/badges azuis) ────────────────

  static const primarySubtleLight = indigo50;
  static const primarySubtleDark = indigo950;

  static const primaryBorderLight = indigo200;
  static const primaryBorderDark = indigo800;

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
  static const secondaryButtonBorderLight = indigo200;

  /// Texto/ícone do botão secundário no tema escuro.
  static const secondaryButtonFgDark = Color(0xFFE2E8F0);

  // ── Shadows ──────────────────────────────────────────────────────────────

  static const shadowLight = Color(0x140F172A);
  static const shadowDark = Color(0x33000000);

  static const primaryShadow = Color(0x664F46E5);

  /// Sombra do botão primário (pill button).
  static const primaryButtonShadow = Color(0x334F46E5);

  /// Sombra do sheet no tema claro.
  static const sheetShadowLight = Color(0x144F46E5);

  /// Sombra do container de ícone no tema escuro.
  static const iconContainerShadowDark = Color(0x22000000);

  /// Sombra do container de ícone no tema claro.
  static const iconContainerShadowLight = Color(0x12000000);

  // ── Platform brands (ícones de plataformas externas) ─────────────────────
  // Cores de identidade de marca de terceiros — mantidas literais de
  // propósito (não substituídas por tokens do ColorScheme do app), já que
  // recolorir o ícone do YouTube/Spotify/Deezer pra paleta do app quebraria
  // o reconhecimento visual da plataforma. Centralizadas aqui em vez de
  // hex soltos nas telas, seguindo o mesmo padrão de success/danger/warning.

  /// Vermelho oficial do YouTube.
  static const youtube = Color(0xFFFF0000);

  /// Verde do Spotify sobre fundo escuro.
  static const spotifyDark = Color(0xFF1DB954);

  /// Verde do Spotify sobre fundo claro (mais escuro, pra manter contraste).
  static const spotifyLight = Color(0xFF168A3F);

  /// Roxo oficial do Deezer.
  static const deezer = Color(0xFFA238FF);
}
