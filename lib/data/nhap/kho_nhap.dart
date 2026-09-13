import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Chỗ giữ báo cáo viết lúc mất mạng, chờ có mạng gửi lên.
///
/// Nằm trên máy, không phải máy chủ: đứa trẻ bấm Gửi ở nơi 4G chập chờn thì
/// bài không mất, cũng không phải bấm lại. Ảnh đi kèm được chép vào thư mục
/// bền của app — ảnh chụp nằm trong cache, Android dọn cache bất cứ lúc nào.
abstract interface class KhoNhap {
  Future<List<BaoCao>> doc();
  Future<void> ghi(List<BaoCao> ds);

  /// Chép ảnh tạm vào chỗ bền, trả về đường dẫn mới.
  Future<String> giuAnh(String duongDan);

  /// Bỏ ảnh đã chép, sau khi báo cáo lên được máy chủ.
  Future<void> boAnh(String duongDan);
}

/// Bản trong bộ nhớ cho test và chế độ xem thử.
class KhoNhapBoNho implements KhoNhap {
  List<BaoCao> ds = [];

  @override
  Future<List<BaoCao>> doc() async => List.of(ds);
  @override
  Future<void> ghi(List<BaoCao> moi) async => ds = List.of(moi);
  @override
  Future<String> giuAnh(String duongDan) async => duongDan;
  @override
  Future<void> boAnh(String duongDan) async {}
}

/// Bản thật: một file JSON và một thư mục ảnh trong thư mục dữ liệu của app.
class KhoNhapFile implements KhoNhap {
  KhoNhapFile(this.thuMuc);

  final Directory thuMuc;

  File get _file => File('${thuMuc.path}${Platform.pathSeparator}nhap_bao_cao.json');
  Directory get _anh => Directory('${thuMuc.path}${Platform.pathSeparator}anh_nhap');

  @override
  Future<List<BaoCao>> doc() async {
    try {
      if (!await _file.exists()) return const [];
      final ds = jsonDecode(await _file.readAsString());
      if (ds is! List) return const [];
      return [
        for (final m in ds)
          if (m is Map) BaoCaoPg.fromMap(m.cast<String, Object?>()),
      ];
    } catch (e) {
      // File hỏng thì coi như không có nháp — còn hơn làm app không mở được.
      debugPrint('Không đọc được nháp báo cáo ($e).');
      return const [];
    }
  }

  @override
  Future<void> ghi(List<BaoCao> ds) async {
    await thuMuc.create(recursive: true);
    // toMap() không mang tao_luc (cột đó máy chủ tự điền); nháp thì phải giữ
    // để thứ tự và giờ gửi không đổi sau khi lên máy chủ.
    final json = [
      for (final b in ds) b.toMap()..['tao_luc'] = b.taoLuc.toIso8601String(),
    ];
    await _file.writeAsString(jsonEncode(json), flush: true);
  }

  @override
  Future<String> giuAnh(String duongDan) async {
    final goc = File(duongDan);
    if (duongDan.startsWith(_anh.path)) return duongDan;
    await _anh.create(recursive: true);
    final ten = duongDan.split(RegExp(r'[\\/]')).last;
    final dich = '${_anh.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}_$ten';
    await goc.copy(dich);
    return dich;
  }

  @override
  Future<void> boAnh(String duongDan) async {
    if (!duongDan.startsWith(_anh.path)) return;
    try {
      await File(duongDan).delete();
    } catch (_) {
      // Đã mất từ trước thì thôi.
    }
  }
}
