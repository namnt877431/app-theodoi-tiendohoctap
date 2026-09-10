import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/app_state.dart';
import 'data/repositories/firebase_repository.dart';
import 'data/repositories/hoc_tap_repository.dart';
import 'data/repositories/mock_repository.dart';
import 'features/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(SoLienLacApp(repo: await _chonKho()));
}

/// Dùng Firebase nếu project đã được cấu hình; chưa cấu hình thì rơi về dữ liệu
/// mẫu để app vẫn mở được. Nhờ vậy người mới clone repo chạy được ngay, còn khi
/// đã chạy `flutterfire configure` thì tự động chuyển sang dữ liệu thật.
Future<HocTapRepository> _chonKho() async {
  try {
    await Firebase.initializeApp();
    return FirebaseRepository();
  } catch (e) {
    debugPrint(
      'Chưa cấu hình Firebase ($e) — chạy bằng dữ liệu mẫu. '
      'Xem phần "Ghép Firebase" trong README.',
    );
    return MockRepository();
  }
}

class SoLienLacApp extends StatelessWidget {
  const SoLienLacApp({super.key, required this.repo});

  final HocTapRepository repo;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(repo),
      child: MaterialApp(
        title: 'Sổ liên lạc',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const AuthGate(),
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
          child: child!,
        ),
      ),
    );
  }
}
