import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cau_hinh.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'core/theme/typography.dart';
import 'core/thong_bao/fcm_kenh.dart';
import 'core/thong_bao/kenh_thong_bao.dart';
import 'core/widgets/con_dau.dart';
import 'core/widgets/khung_rong.dart';
import 'core/huy_hieu/huy_hieu.dart';
import 'data/app_state.dart';
import 'data/nhap/kho_nhap.dart';
import 'data/repositories/hoc_tap_repository.dart';
import 'data/repositories/mock_repository.dart';
import 'data/repositories/supabase_repository.dart';
import 'features/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  final repo = await _chonKho();
  // Thông báo đẩy và bài chờ mạng chỉ có nghĩa khi có máy chủ thật.
  // Bản web chưa có thông báo đẩy (cần thêm service worker và cấu hình
  // Firebase web) và không có thư mục riêng để cất bài chờ mạng — bài viết
  // lúc mất mạng chỉ giữ trong phiên đang mở.
  final trenMay = repo is SupabaseRepository && !kIsWeb;
  final kenh = trenMay ? await FcmKenh.khoiDong() : null;
  final khoNhap = trenMay ? await _moKhoNhap() : null;

  runApp(SoLienLacApp(repo: repo, kenhThongBao: kenh, khoNhap: khoNhap));
}

/// Thư mục dữ liệu riêng của app — không bị dọn như cache, gỡ app mới mất.
Future<KhoNhap?> _moKhoNhap() async {
  try {
    return KhoNhapFile(await getApplicationSupportDirectory());
  } catch (e) {
    debugPrint('Không mở được kho nháp ($e) — bài viết lúc mất mạng sẽ không được giữ.');
    return null;
  }
}

/// Dùng Supabase nếu đã khai địa chỉ dự án lúc build; chưa khai thì rơi về dữ
/// liệu mẫu để app vẫn mở được. Nhờ vậy người mới clone repo chạy được ngay.
Future<HocTapRepository> _chonKho() async {
  if (!CauHinh.coSupabase) {
    debugPrint(
      'Chưa khai SUPABASE_URL và SUPABASE_PUBLISHABLE_KEY — chạy bằng dữ liệu mẫu. '
      'Xem phần "Dựng Supabase từ đầu" trong README.',
    );
    return MockRepository();
  }

  try {
    await Supabase.initialize(
      url: CauHinh.supabaseUrl,
      publishableKey: CauHinh.supabaseKey,
    );
    return SupabaseRepository();
  } catch (e) {
    debugPrint('Không nối được Supabase ($e) — chạy bằng dữ liệu mẫu.');
    return MockRepository();
  }
}

class SoLienLacApp extends StatefulWidget {
  const SoLienLacApp({super.key, required this.repo, this.kenhThongBao, this.khoNhap});

  final HocTapRepository repo;
  final KenhThongBao? kenhThongBao;
  final KhoNhap? khoNhap;

  @override
  State<SoLienLacApp> createState() => _SoLienLacAppState();
}

class _SoLienLacAppState extends State<SoLienLacApp> with WidgetsBindingObserver {
  late final AppState _state = AppState(
    widget.repo,
    kenhThongBao: widget.kenhThongBao,
    khoNhap: widget.khoNhap,
  );
  final _thongBao = GlobalKey<ScaffoldMessengerState>();
  final _dieuHuong = GlobalKey<NavigatorState>();
  StreamSubscription<TinDen>? _theoDoiTin;
  StreamSubscription<HuyHieu>? _theoDoiHuyHieu;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Vừa đạt con dấu: đóng lên bất kỳ màn nào đang mở, sau khi màn viết
    // báo cáo kịp đóng lại.
    _theoDoiHuyHieu = _state.huyHieuMoi.listen((hh) async {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final ctx = _dieuHuong.currentContext;
      if (ctx != null && ctx.mounted) await moKhenHuyHieu(ctx, hh);
    });
    // Tin đến lúc app đang mở: hệ điều hành không hiện gì, app tự báo một
    // dòng ở dưới. Dữ liệu đã được AppState nạp lại trước khi phát.
    _theoDoiTin = _state.tinDen.listen((tin) {
      _thongBao.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          duration: const Duration(seconds: 5),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tin.tieuDe, style: AppType.ui(14, w: FontWeight.w700, color: Colors.white)),
              if (tin.noiDung.isNotEmpty)
                Text(tin.noiDung,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.ui(12.5, color: Colors.white.withValues(alpha: .85))),
            ],
          ),
          backgroundColor: AppColor.ink,
        ));
    });
  }

  /// Quay lại app — thường là vừa chạm vào một thông báo — thì nạp lại, để
  /// cái vừa được báo đã nằm sẵn trên màn hình chứ không phải kéo xuống.
  @override
  void didChangeAppLifecycleState(AppLifecycleState trangThai) {
    if (trangThai == AppLifecycleState.resumed && _state.daDangNhap && !_state.dungThu) {
      unawaited(_state.taiLaiTatCa());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _theoDoiTin?.cancel();
    _theoDoiHuyHieu?.cancel();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _state,
      child: MaterialApp(
        title: 'Sổ liên lạc',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        scaffoldMessengerKey: _thongBao,
        navigatorKey: _dieuHuong,
        home: const AuthGate(),
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
          child: KhungRong(child: child!),
        ),
      ),
    );
  }
}
