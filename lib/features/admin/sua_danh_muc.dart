import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';
import '../../data/repositories/hoc_tap_repository.dart';
import '../auth/dang_nhap_screen.dart' show HopLoi;

/// Ba bảng thêm/sửa nhỏ cho danh mục của quản trị: tỉnh, trường, môn học.
/// Thầy cô có bảng riêng ở `shared/sua_giao_vien_sheet.dart` vì học sinh cũng
/// dùng được nó.

Future<void> moSuaTinh(BuildContext context, {Tinh? tinh}) => _mo(
      context,
      _SuaTinh(tinh: tinh),
    );

Future<void> moSuaTruong(BuildContext context, {Truong? truong, String? tinhMacDinh}) =>
    _mo(context, _SuaTruong(truong: truong, tinhMacDinh: tinhMacDinh));

Future<void> moSuaMon(BuildContext context, {MonHoc? mon}) => _mo(
      context,
      _SuaMon(mon: mon),
    );

Future<void> _mo(BuildContext context, Widget than) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppState>(),
        child: than,
      ),
    );

/// Phần chung của ba bảng: giữ cờ đang lưu, lỗi, và cách đóng sau khi xong.
mixin _LuuXoa<T extends StatefulWidget> on State<T> {
  bool dangLuu = false;
  String? loi;

  Future<void> chay(Future<void> Function() viec) async {
    setState(() {
      dangLuu = true;
      loi = null;
    });
    try {
      await viec();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on LoiHocTap catch (e) {
      if (mounted) setState(() => loi = e.thongDiep);
    } catch (e) {
      if (mounted) setState(() => loi = 'Không lưu được ($e).');
    } finally {
      if (mounted) setState(() => dangLuu = false);
    }
  }
}

// ------------------------------------------------------------------------ tỉnh

class _SuaTinh extends StatefulWidget {
  const _SuaTinh({this.tinh});
  final Tinh? tinh;

  @override
  State<_SuaTinh> createState() => _SuaTinhState();
}

class _SuaTinhState extends State<_SuaTinh> with _LuuXoa {
  final _form = GlobalKey<FormState>();
  late final _ten = TextEditingController(text: widget.tinh?.ten ?? '');

  @override
  void dispose() {
    _ten.dispose();
    super.dispose();
  }

  Future<void> _xoa() async {
    final t = widget.tinh!;
    final s = context.read<AppState>();
    final soTruong = s.truongTheoTinh(t.id).length;
    final dongY = await hoiXoa(
      context,
      'Xóa tỉnh ${t.ten}?',
      giaiThich: soTruong == 0
          ? null
          : '$soTruong trường đang thuộc tỉnh này. Xóa xong chúng vẫn còn, chỉ không còn tỉnh.',
    );
    if (!dongY || !mounted) return;
    await chay(() => s.xoaTinh(t.id));
  }

  @override
  Widget build(BuildContext context) {
    final sua = widget.tinh != null;
    return Form(
      key: _form,
      child: KhungBieuMau(
        tieuDe: sua ? 'Sửa tỉnh' : 'Thêm tỉnh',
        eyebrow: 'Tỉnh / thành phố',
        nhanLuu: sua ? 'Lưu thay đổi' : 'Thêm',
        dangLuu: dangLuu,
        onXoa: sua ? _xoa : null,
        onLuu: () {
          if (!_form.currentState!.validate()) return;
          chay(() => context.read<AppState>().luuTinh(
                Tinh(id: widget.tinh?.id ?? '', ten: _ten.text.trim()),
              ));
        },
        children: [
          const NhanO('Tên tỉnh'),
          TextFormField(
            controller: _ten,
            autofocus: !sua,
            textCapitalization: TextCapitalization.words,
            style: AppType.ui(15, w: FontWeight.w500),
            decoration: const InputDecoration(hintText: 'Hà Nội'),
            validator: (v) => (v ?? '').trim().length >= 2 ? null : 'Nhập tên tỉnh',
          ),
          if (loi != null) ...[const SizedBox(height: Gap.md), HopLoi(loi!)],
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------- trường

class _SuaTruong extends StatefulWidget {
  const _SuaTruong({this.truong, this.tinhMacDinh});
  final Truong? truong;
  final String? tinhMacDinh;

  @override
  State<_SuaTruong> createState() => _SuaTruongState();
}

class _SuaTruongState extends State<_SuaTruong> with _LuuXoa {
  final _form = GlobalKey<FormState>();
  late final _ten = TextEditingController(text: widget.truong?.ten ?? '');
  late String? _tinhId = widget.truong?.tinhId ?? widget.tinhMacDinh;

  @override
  void dispose() {
    _ten.dispose();
    super.dispose();
  }

  Future<void> _xoa() async {
    final t = widget.truong!;
    final s = context.read<AppState>();
    final soGv = s.giaoVien.where((g) => g.truongId == t.id).length;
    final dongY = await hoiXoa(
      context,
      'Xóa trường ${t.ten}?',
      giaiThich: 'Học sinh đã chọn trường này sẽ thành chưa có trường'
          '${soGv == 0 ? '' : ', và $soGv thầy cô của trường sẽ hiện cho mọi trường'}.',
    );
    if (!dongY || !mounted) return;
    await chay(() => s.xoaTruong(t.id));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final sua = widget.truong != null;
    return Form(
      key: _form,
      child: KhungBieuMau(
        tieuDe: sua ? 'Sửa trường' : 'Thêm trường',
        eyebrow: 'Trường học',
        nhanLuu: sua ? 'Lưu thay đổi' : 'Thêm',
        dangLuu: dangLuu,
        onXoa: sua ? _xoa : null,
        onLuu: () {
          if (!_form.currentState!.validate()) return;
          chay(() => s.luuTruong(Truong(
                id: widget.truong?.id ?? '',
                ten: _ten.text.trim(),
                tinhId: _tinhId,
              )));
        },
        children: [
          const NhanO('Tên trường'),
          TextFormField(
            controller: _ten,
            autofocus: !sua,
            textCapitalization: TextCapitalization.words,
            style: AppType.ui(15, w: FontWeight.w500),
            decoration: const InputDecoration(hintText: 'THCS Nguyễn Trãi'),
            validator: (v) => (v ?? '').trim().length >= 2 ? null : 'Nhập tên trường',
          ),
          const SizedBox(height: Gap.lg),
          const NhanO('Tỉnh'),
          DropdownButtonFormField<String?>(
            initialValue: s.tinh.any((t) => t.id == _tinhId) ? _tinhId : null,
            isExpanded: true,
            style: AppType.ui(15, w: FontWeight.w500),
            hint: const Text('Chưa xếp tỉnh'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Chưa xếp tỉnh')),
              for (final t in s.tinh) DropdownMenuItem<String?>(value: t.id, child: Text(t.ten)),
            ],
            onChanged: (v) => setState(() => _tinhId = v),
          ),
          if (s.tinh.isEmpty) ...[
            const SizedBox(height: Gap.sm),
            Text(
              'Chưa có tỉnh nào. Thêm trường trước cũng được, xếp tỉnh sau.',
              style: AppType.ui(12, color: AppColor.mucNhat, w: FontWeight.w400),
            ),
          ],
          if (loi != null) ...[const SizedBox(height: Gap.md), HopLoi(loi!)],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------ môn

class _SuaMon extends StatefulWidget {
  const _SuaMon({this.mon});
  final MonHoc? mon;

  @override
  State<_SuaMon> createState() => _SuaMonState();
}

class _SuaMonState extends State<_SuaMon> with _LuuXoa {
  final _form = GlobalKey<FormState>();
  late final _ten = TextEditingController(text: widget.mon?.ten ?? '');
  late final _vietTat = TextEditingController(text: widget.mon?.vietTat ?? '');

  @override
  void dispose() {
    _ten.dispose();
    _vietTat.dispose();
    super.dispose();
  }

  Future<void> _xoa() async {
    final m = widget.mon!;
    final dongY = await hoiXoa(
      context,
      'Xóa môn ${m.ten}?',
      giaiThich: 'Báo cáo, tiết học và thầy cô đã gắn môn này vẫn còn, chỉ hiện là "Môn khác".',
    );
    if (!dongY || !mounted) return;
    await chay(() => context.read<AppState>().xoaMonHoc(m.id));
  }

  @override
  Widget build(BuildContext context) {
    final sua = widget.mon != null;
    return Form(
      key: _form,
      child: KhungBieuMau(
        tieuDe: sua ? 'Sửa môn học' : 'Thêm môn học',
        eyebrow: 'Môn học',
        nhanLuu: sua ? 'Lưu thay đổi' : 'Thêm',
        dangLuu: dangLuu,
        onXoa: sua ? _xoa : null,
        onLuu: () {
          if (!_form.currentState!.validate()) return;
          final ten = _ten.text.trim();
          final vt = _vietTat.text.trim();
          chay(() => context.read<AppState>().luuMonHoc(MonHoc(
                id: widget.mon?.id ?? '',
                ten: ten,
                vietTat: vt.isEmpty ? ten : vt,
              )));
        },
        children: [
          const NhanO('Tên môn'),
          TextFormField(
            controller: _ten,
            autofocus: !sua,
            textCapitalization: TextCapitalization.sentences,
            style: AppType.ui(15, w: FontWeight.w500),
            decoration: const InputDecoration(hintText: 'Ngữ văn'),
            validator: (v) => (v ?? '').trim().isNotEmpty ? null : 'Nhập tên môn',
          ),
          const SizedBox(height: Gap.lg),
          const NhanO('Viết tắt (hiện trên thời khóa biểu)'),
          TextFormField(
            controller: _vietTat,
            maxLength: 6,
            style: AppType.ui(15, w: FontWeight.w500),
            decoration: const InputDecoration(hintText: 'Văn', counterText: ''),
          ),
          if (loi != null) ...[const SizedBox(height: Gap.md), HopLoi(loi!)],
        ],
      ),
    );
  }
}
