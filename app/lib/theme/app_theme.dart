import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One visual language for the whole app.
///
/// The editorial palette (warm paper, near-black ink, hairline rules,
/// deep green accent) is folded into a real ColorScheme, so every widget
/// picks it up through Theme.of(context) instead of importing constants.
/// That is what makes dark mode work and keeps the gate and the home
/// screen from drifting into two different products.
class AppTheme {
  AppTheme._();

  // Light
  static const _paper       = Color(0xFFFBFAF7);
  static const _paperRaised = Color(0xFFF4F2EC);
  static const _ink         = Color(0xFF1A1A18);
  static const _inkMuted    = Color(0xFF6B6B66);
  static const _hairline    = Color(0xFFE2E0DA);
  static const _accent      = Color(0xFF2F5D50);
  static const _down        = Color(0xFFA8544A);

  // Dark. Warm charcoal, not black: the app is opened at 11pm.
  static const _paperDark       = Color(0xFF16161A);
  static const _paperRaisedDark = Color(0xFF1F1F24);
  static const _inkDark         = Color(0xFFEDEBE6);
  static const _inkMutedDark    = Color(0xFF9A9892);
  static const _hairlineDark    = Color(0xFF2E2E34);
  static const _accentDark      = Color(0xFF6FA593);

  /// Minimum height for anything tappable at the gate. Larger than
  /// Material's 48 on purpose: one-handed, in a hurry.
  static const tapTarget = 56.0;
  static const radius = 6.0;
  static const gutter = 24.0;

  /// Content never exceeds this. Without it the layout stretches to the
  /// window width on web and desktop and reads as empty.
  static const maxContentWidth = 560.0;

  static const motion = Duration(milliseconds: 180);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isLight = b == Brightness.light;

    final scheme = ColorScheme(
      brightness: b,
      primary:   isLight ? _accent : _accentDark,
      onPrimary: isLight ? _paper : _paperDark,
      primaryContainer:   isLight ? const Color(0xFFDCE7E2) : const Color(0xFF27473E),
      onPrimaryContainer: isLight ? _ink : _inkDark,
      secondary:   isLight ? _inkMuted : _inkMutedDark,
      onSecondary: isLight ? _paper : _paperDark,
      error:   isLight ? _down : const Color(0xFFD98A80),
      onError: isLight ? _paper : _paperDark,
      surface:   isLight ? _paper : _paperDark,
      onSurface: isLight ? _ink : _inkDark,
      surfaceContainerHighest: isLight ? _paperRaised : _paperRaisedDark,
      surfaceContainerHigh:    isLight ? _paperRaised : _paperRaisedDark,
      onSurfaceVariant: isLight ? _inkMuted : _inkMutedDark,
      outlineVariant:   isLight ? _hairline : _hairlineDark,
      outline:          isLight ? _hairline : _hairlineDark,
    );

    final ink = scheme.onSurface;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      textTheme: TextTheme(
        displaySmall: GoogleFonts.fraunces(
          fontSize: 34, fontWeight: FontWeight.w600,
          height: 1.12, letterSpacing: -0.6, color: ink,
        ),
        headlineSmall: GoogleFonts.fraunces(
          fontSize: 24, fontWeight: FontWeight.w600,
          height: 1.2, letterSpacing: -0.3, color: ink,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w600, height: 1.35, color: ink,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, height: 1.35, color: ink,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, height: 1.5, color: ink),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, height: 1.45, color: scheme.onSurfaceVariant,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
          letterSpacing: 1.1, color: scheme.onSurfaceVariant,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(tapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Centres and width-limits page content. Wrap every screen body in this
/// or the layout stretches on web.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: child,
        ),
      );
}