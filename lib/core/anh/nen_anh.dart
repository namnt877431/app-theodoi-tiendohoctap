import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Ép ảnh vở xuống dưới một mức dung lượng, kiểu Zalo.
///
/// Không có phép màu nào: ảnh đã được máy ảnh thu về cạnh dài 1600 px lúc
/// chụp (xem `_themAnh` ở màn viết báo cáo), ở đây chỉ hạ dần chất lượng
/// JPEG — 80, 70, 60… — tới khi file lọt dưới [mucByte]. Trang vở viết tay ở
/// 1600 px, chất lượng 60 vẫn đọc rõ từng nét; thứ mất đi là nhiễu của cảm
/// biến, không phải chữ.
///
/// Vì sao phải làm: kho miễn phí của Supabase có 1 GB. Ảnh 12 MP nguyên bản
/// 3–4 MB thì ~300 tấm là đầy; 400 KB thì được ~2.500 tấm — và tải lên 4G
/// nhanh gấp mười.
///
/// Ảnh vốn đã nhỏ vẫn đi qua plugin một lần ở chất lượng cao: plugin xoay
/// điểm ảnh theo thẻ EXIF rồi bỏ thẻ đi, nhờ vậy tấm ảnh hiện cùng một chiều
/// ở mọi nơi. Giữ thẻ thì điện thoại hiểu, trình duyệt lại không — cùng một
/// ảnh lúc ngang lúc dọc.
///
/// Trả về đường dẫn file đã nén (trong thư mục tạm), hoặc chính đường dẫn cũ
/// khi không nén được — không bao giờ làm mất tấm ảnh.
Future<String> nenAnhBaiLam(
  String duongDan, {
  int mucByte = 500 * 1024,
  MayNen nen = _nenBangPlugin,
}) async {
  // Trên web không có file để nén; image_picker đã thu ảnh về 1600 px, chất
  // lượng 85 ngay lúc chọn — và vẽ qua canvas nên chiều xoay đã được nướng vào.
  if (kIsWeb) return duongDan;
  try {
    final daNho = await File(duongDan).length() <= mucByte;
    final cacMuc = daNho ? const [92] : const [80, 70, 60, 50, 40];

    var tot = duongDan;
    for (final chatLuong in cacMuc) {
      final dich = '${Directory.systemTemp.path}/nen_'
          '${DateTime.now().microsecondsSinceEpoch}_$chatLuong.jpg';
      final f = await nen(duongDan, dich, chatLuong);
      if (f == null) break;
      tot = f.path;
      if (await f.length() <= mucByte) break;
    }
    return tot;
  } catch (e) {
    debugPrint('Không nén được ảnh ($e) — dùng bản gốc.');
    return duongDan;
  }
}

/// Một bước nén: đọc [nguon], ghi JPEG chất lượng [chatLuong] ra [dich].
/// Tách ra để test thay bằng bản giả — plugin thật cần máy Android.
typedef MayNen = Future<File?> Function(String nguon, String dich, int chatLuong);

Future<File?> _nenBangPlugin(String nguon, String dich, int chatLuong) async {
  final ra = await FlutterImageCompress.compressAndGetFile(
    nguon,
    dich,
    quality: chatLuong,
    // Ảnh vào đã ≤ 1600 px nên hai mốc này không thu thêm — chỉ để plugin
    // khỏi phóng to ảnh nhỏ.
    minWidth: 1600,
    minHeight: 1600,
    format: CompressFormat.jpeg,
    // Xoay điểm ảnh theo thẻ EXIF trước khi bỏ thẻ — xem chú thích ở trên.
    autoCorrectionAngle: true,
    // Bỏ EXIF: tọa độ GPS và số máy không có việc gì trên ảnh vở của trẻ con.
    keepExif: false,
  );
  return ra == null ? null : File(ra.path);
}
