import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Colores principales (del DESIGN.md) ───────────────────────────
  static const Color primary = Color(0xFF600F72);
  static const Color primaryContainer = Color(0xFF7B2D8B);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF7B3BC3);
  static const Color secondaryContainer = Color(0xFFB374FE);
  static const Color tertiary = Color(0xFF660073);
  static const Color tertiaryContainer = Color(0xFF8C009C);

  static const Color surface = Color(0xFFFCF8FF);
  static const Color surfaceDim = Color(0xFFDAD7F3);
  static const Color surfaceContainerLow = Color(0xFFF5F2FF);
  static const Color surfaceContainer = Color(0xFFEFECFF);
  static const Color surfaceContainerHigh = Color(0xFFE8E5FF);
  static const Color surfaceContainerHighest = Color(0xFFE2E0FC);

  static const Color onSurface = Color(0xFF1A1A2E);
  static const Color onSurfaceVariant = Color(0xFF4F434F);
  static const Color outline = Color(0xFF817380);
  static const Color outlineVariant = Color(0xFFD2C1D0);

  static const Color background = Color(0xFFFCF8FF);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // ─── Gradiente principal ───────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7B2D8B), Color(0xFFC026D3)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    colors: [Color(0xFF7B2D8B), Color(0xFFC026D3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Colores semánticos por país ──────────────────────────────────
  static const Color colombiaColor = Color(0xFFFFD700); // Amarillo
  static const Color chileColor = Color(0xFFE63946);    // Rojo
  static const Color ecuadorColor = Color(0xFF2DC653);  // Verde

  // ─── Colores de estado ────────────────────────────────────────────
  static const Color pendienteColor = Color(0xFFF59E0B);
  static const Color gestionadaColor = Color(0xFF3B82F6);
  static const Color respondidaColor = Color(0xFF10B981);
  static const Color borradorColor = Color(0xFF9CA3AF);
  static const Color publicadoColor = Color(0xFF10B981);
  static const Color despublicadoColor = Color(0xFFEF4444);

  // ─── Tipografía (Plus Jakarta Sans) ──────────────────────────────
  static TextTheme get textTheme => TextTheme(
    displayLarge: GoogleFonts.plusJakartaSans(
      fontSize: 32, fontWeight: FontWeight.w800, color: onSurface,
    ),
    headlineLarge: GoogleFonts.plusJakartaSans(
      fontSize: 22, fontWeight: FontWeight.w700, color: onSurface,
    ),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: 18, fontWeight: FontWeight.w700, color: onSurface,
    ),
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: 16, fontWeight: FontWeight.w600, color: onSurface,
    ),
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: 14, fontWeight: FontWeight.w600, color: onSurface,
    ),
    bodyLarge: GoogleFonts.plusJakartaSans(
      fontSize: 16, fontWeight: FontWeight.w400, color: onSurface,
    ),
    bodyMedium: GoogleFonts.plusJakartaSans(
      fontSize: 14, fontWeight: FontWeight.w400, color: onSurface,
    ),
    bodySmall: GoogleFonts.plusJakartaSans(
      fontSize: 12, fontWeight: FontWeight.w400, color: onSurfaceVariant,
    ),
    labelLarge: GoogleFonts.plusJakartaSans(
      fontSize: 14, fontWeight: FontWeight.w700, color: onSurface,
    ),
    labelMedium: GoogleFonts.plusJakartaSans(
      fontSize: 12, fontWeight: FontWeight.w700, color: onSurface,
    ),
    labelSmall: GoogleFonts.plusJakartaSans(
      fontSize: 11, fontWeight: FontWeight.w400, color: onSurfaceVariant,
    ),
  );

  // ─── ThemeData principal ──────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFFF5A6FF),
      secondary: secondary,
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFF41007A),
      tertiary: tertiary,
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: Color(0xFFFCA3FF),
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: Color(0xFF93000A),
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF2F2E43),
      onInverseSurface: Color(0xFFF2EFFF),
      inversePrimary: Color(0xFFF6ADFF),
    ),
    textTheme: textTheme,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.08),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryContainer, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w700,
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryContainer,
      unselectedItemColor: outline,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  // ─── Helpers ──────────────────────────────────────────────────────
  static Color getPaisColor(String? codigo) {
    switch (codigo) {
      case 'CO': return colombiaColor;
      case 'CL': return chileColor;
      case 'EC': return ecuadorColor;
      default: return secondary;
    }
  }

  static Color getEstadoSolicitudColor(String estado) {
    switch (estado) {
      case 'pendiente': return pendienteColor;
      case 'gestionada': return gestionadaColor;
      case 'respondida': return respondidaColor;
      default: return outline;
    }
  }

  static Color getEstadoContenidoColor(String estado) {
    switch (estado) {
      case 'publicado': return publicadoColor;
      case 'borrador': return borradorColor;
      case 'despublicado': return despublicadoColor;
      default: return outline;
    }
  }
}

// ─── Alias AppColors para facilitar importaciones ─────────────────────────
class AppColors {
  static const Color primary = AppTheme.primary;
  static const Color primaryLight = AppTheme.primaryContainer;
  static const Color secondary = AppTheme.secondary;
  static const Color background = AppTheme.background;
  static const Color surface = AppTheme.surface;
  static const Color error = AppTheme.error;
  static const Color border = AppTheme.outlineVariant;
  static const Color textPrimary = AppTheme.onSurface;
  static const Color textSecondary = AppTheme.onSurfaceVariant;
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFF59E0B);
}

// ─── Helpers globales ─────────────────────────────────────────────────────
class AppHelpers {
  static String getPaisFlag(String? codigo) {
    switch (codigo) {
      case 'CO': return '🇨🇴';
      case 'CL': return '🇨🇱';
      case 'EC': return '🇪🇨';
      default: return '🌎';
    }
  }

  static Color getPaisColor(String? codigo) => AppTheme.getPaisColor(codigo);
  static Color getEstadoColor(String estado) => AppTheme.getEstadoContenidoColor(estado);
}
