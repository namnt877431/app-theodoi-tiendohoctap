import 'dart:io';

import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;

const _album = 'Sổ liên lạc';

Future<String> taiAnhVeMay({String? duongDan, String? url}) async {
  if (!await Gal.hasAccess(toAlbum: true)) {
    final ok = await Gal.requestAccess(toAlbum: true);
    if (!ok) return 'Chưa được phép ghi vào thư viện ảnh. Vào Cài đặt cấp quyền cho Sổ liên lạc.';
  }
  try {
    if (duongDan != null && await File(duongDan).exists()) {
      await Gal.putImage(duongDan, album: _album);
    } else if (url != null) {
      final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (r.statusCode != 200) return 'Không tải được ảnh từ kho (mã ${r.statusCode}).';
      await Gal.putImageBytes(r.bodyBytes, album: _album);
    } else {
      return 'Không có ảnh để tải.';
    }
    return 'Đã lưu vào thư viện ảnh, album "$_album".';
  } on GalException catch (e) {
    return 'Không lưu được ảnh: ${e.type.message}';
  }
}
