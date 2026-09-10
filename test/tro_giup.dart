import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/data/app_state.dart';
import 'package:theodoi_hoctap/data/models/models.dart';
import 'package:theodoi_hoctap/data/repositories/mock_repository.dart';

/// Phiên đăng nhập đi qua một Stream nên trạng thái không có ngay sau await.
/// Chờ tới khi điều kiện đúng, thay vì đoán một khoảng delay cố định.
Future<void> cho(bool Function() dieuKien, {String moTa = 'điều kiện'}) async {
  for (var i = 0; i < 250; i++) {
    if (dieuKien()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('Chờ quá lâu mà $moTa vẫn chưa đúng');
}

Future<AppState> vaoVoiVaiTro(VaiTro vaiTro) async {
  final s = AppState(MockRepository());
  await s.dungThuVoiVaiTro(vaiTro);
  await cho(() => s.nguoiDung != null && !s.dangTai, moTa: 'phiên đăng nhập');
  return s;
}
