import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';
import 'typography.dart';

abstract final class AppTheme {
  static ThemeData build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColor.muc,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColor.muc,
      onPrimary: Colors.white,
      secondary: AppColor.ink,
      surface: AppColor.giay,
      onSurface: AppColor.ink,
      error: AppColor.butDo,
      outlineVariant: AppColor.dongKe,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColor.skySoft,
      splashFactory: InkSparkle.splashFactory,

      textTheme: TextTheme(
        displaySmall: AppType.display(30),
        headlineMedium: AppType.display(24),
        headlineSmall: AppType.ui(19, w: FontWeight.w700),
        titleLarge: AppType.ui(17, w: FontWeight.w700),
        titleMedium: AppType.ui(15, w: FontWeight.w600),
        bodyLarge: AppType.ui(15, height: 1.5),
        bodyMedium: AppType.ui(14, height: 1.55, w: FontWeight.w400),
        bodySmall: AppType.ui(12.5, color: AppColor.mucNhat, w: FontWeight.w400),
        labelLarge: AppType.ui(14, w: FontWeight.w600),
        labelSmall: AppType.eyebrow(),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColor.skySoft,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColor.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppType.ui(18, w: FontWeight.w700),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: AppColor.giayTrang,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.lg),
          side: const BorderSide(color: AppColor.dongKe),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColor.dongKe,
        thickness: 1,
        space: 1,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColor.muc,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
          textStyle: AppType.ui(15, w: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.muc,
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: AppColor.dongKeDam),
          textStyle: AppType.ui(15, w: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColor.muc,
          textStyle: AppType.ui(14, w: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.giayTrang,
        contentPadding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md + 2),
        hintStyle: AppType.ui(15, color: AppColor.mucNhat.withValues(alpha: .75), w: FontWeight.w400),
        labelStyle: AppType.ui(14, color: AppColor.mucNhat),
        border: _field(AppColor.dongKe),
        enabledBorder: _field(AppColor.dongKe),
        focusedBorder: _field(AppColor.muc, width: 1.6),
        errorBorder: _field(AppColor.butDo),
        focusedErrorBorder: _field(AppColor.butDo, width: 1.6),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColor.sky,
        side: BorderSide.none,
        labelStyle: AppType.ui(13, w: FontWeight.w600, color: AppColor.muc),
        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.sm)),
      ),

      // Bảng chọn từ dưới lên không kéo hết bề ngang màn máy tính — thu về
      // cỡ một cột đọc, đặt giữa. Điện thoại hẹp hơn mức này nên không đổi.
      bottomSheetTheme: const BottomSheetThemeData(
        constraints: BoxConstraints(maxWidth: 640),
        backgroundColor: AppColor.giayTrang,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(R.lg + 4)),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColor.giayTrang,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColor.sky,
        elevation: 0,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppType.ui(11.5,
              w: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? AppColor.muc : AppColor.mucNhat),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 23,
            color: s.contains(WidgetState.selected) ? AppColor.muc : AppColor.mucNhat,
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColor.ink,
        contentTextStyle: AppType.ui(14, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md)),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppColor.mucNhat,
        contentPadding: EdgeInsets.symmetric(horizontal: Gap.lg),
      ),
    );
  }

  static OutlineInputBorder _field(Color c, {double width = 1}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.md),
        borderSide: BorderSide(color: c, width: width),
      );
}
