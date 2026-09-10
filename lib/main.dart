import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/app_state.dart';
import 'data/repositories/mock_repository.dart';
import 'features/auth/chon_vai_tro.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const SoLienLacApp());
}

class SoLienLacApp extends StatelessWidget {
  const SoLienLacApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Đổi MockRepository sang FirebaseRepository khi ghép backend —
      // phần giao diện không phải sửa dòng nào.
      create: (_) => AppState(MockRepository()),
      child: MaterialApp(
        title: 'Sổ liên lạc',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const ChonVaiTroScreen(),
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
          child: child!,
        ),
      ),
    );
  }
}
