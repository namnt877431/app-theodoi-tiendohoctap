import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:theodoi_hoctap/core/anh/nen_anh.dart';

/// Máy nén giả: mỗi mức chất lượng cho ra một file có cỡ định trước, để kiểm
/// vòng lặp dừng đúng lúc mà không cần plugin thật.
MayNen mayNenGia(Map<int, int> coTheoChatLuong, {List<int>? daGoi}) =>
    (nguon, dich, chatLuong) async {
      daGoi?.add(chatLuong);
      final co = coTheoChatLuong[chatLuong];
      if (co == null) return null;
      final f = File(dich);
      await f.writeAsBytes(List.filled(co, 0));
      return f;
    };

Future<String> anhTam(int co) async {
  final f = File('${Directory.systemTemp.path}/goc_${DateTime.now().microsecondsSinceEpoch}.jpg');
  await f.writeAsBytes(List.filled(co, 1));
  return f.path;
}

void main() {
  const kb = 1024;

  test('ảnh đã nhỏ vẫn qua plugin một lần ở chất lượng cao — để nướng chiều xoay', () async {
    final goc = await anhTam(300 * kb);
    final daGoi = <int>[];
    final ra = await nenAnhBaiLam(goc, nen: mayNenGia({92: 320 * kb}, daGoi: daGoi));
    expect(daGoi, [92]);
    expect(ra, isNot(goc));
    expect(await File(ra).length(), 320 * kb);
  });

  test('ảnh nhỏ mà plugin hỏng thì giữ bản gốc', () async {
    final goc = await anhTam(300 * kb);
    final ra = await nenAnhBaiLam(goc, nen: mayNenGia({}));
    expect(ra, goc);
  });

  test('hạ chất lượng từng nấc, dừng ngay khi lọt dưới 500 KB', () async {
    final goc = await anhTam(3 * 1024 * kb);
    final daGoi = <int>[];
    final ra = await nenAnhBaiLam(
      goc,
      nen: mayNenGia({80: 900 * kb, 70: 620 * kb, 60: 480 * kb, 50: 300 * kb}, daGoi: daGoi),
    );
    expect(daGoi, [80, 70, 60]);
    expect(await File(ra).length(), 480 * kb);
    expect(ra, isNot(goc));
  });

  test('nén hết nấc vẫn to thì trả bản nhỏ nhất, không bỏ ảnh', () async {
    final goc = await anhTam(9 * 1024 * kb);
    final ra = await nenAnhBaiLam(
      goc,
      nen: mayNenGia({80: 900 * kb, 70: 800 * kb, 60: 700 * kb, 50: 650 * kb, 40: 600 * kb}),
    );
    expect(await File(ra).length(), 600 * kb);
  });

  test('plugin hỏng giữa chừng thì dùng bản tốt nhất đã có', () async {
    final goc = await anhTam(2 * 1024 * kb);
    final ra = await nenAnhBaiLam(goc, nen: mayNenGia({80: 700 * kb}));
    expect(await File(ra).length(), 700 * kb);
  });

  test('plugin ném lỗi thì trả bản gốc', () async {
    final goc = await anhTam(2 * 1024 * kb);
    final ra = await nenAnhBaiLam(goc, nen: (_, _, _) async => throw StateError('hỏng'));
    expect(ra, goc);
  });

  test('đổi được mức đích', () async {
    final goc = await anhTam(2 * 1024 * kb);
    final daGoi = <int>[];
    await nenAnhBaiLam(
      goc,
      mucByte: 1024 * kb,
      nen: mayNenGia({80: 950 * kb}, daGoi: daGoi),
    );
    expect(daGoi, [80]);
  });
}
