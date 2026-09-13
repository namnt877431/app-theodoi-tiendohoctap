import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';
import '../../data/repositories/hoc_tap_repository.dart';
import '../auth/dang_nhap_screen.dart' show HopLoi;

/// Bảng thêm/sửa một thầy cô. Hai cách dùng:
///
/// - Quản trị mở với `chuId` null: chọn được trên lớp / học thêm, gắn trường
///   (trên lớp) hoặc tỉnh (học thêm), thành thầy cô dùng chung.
/// - Học sinh hay phụ huynh mở với `chuId` là id học sinh: chỉ thêm được thầy
///   dạy thêm riêng của nhà mình, không hỏi trường hay tỉnh.
///
/// Trả về id thầy cô vừa lưu, để biểu mẫu đang mở chọn ngay người đó; null
/// khi đóng mà không lưu.
Future<String?> moSuaGiaoVien(
  BuildContext context, {
  GiaoVien? giaoVien,
  String? chuId,
  LoaiBaiTap? loaiMacDinh,
  String? monMacDinh,
}) {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: _SuaGiaoVien(
        giaoVien: giaoVien,
        chuId: chuId ?? giaoVien?.chuId,
        loaiMacDinh: loaiMacDinh,
        monMacDinh: monMacDinh,
      ),
    ),
  );
}

class _SuaGiaoVien extends StatefulWidget {
  const _SuaGiaoVien({
    this.giaoVien,
    this.chuId,
    this.loaiMacDinh,
    this.monMacDinh,
  });

  final GiaoVien? giaoVien;
  final String? chuId;
  final LoaiBaiTap? loaiMacDinh;
  final String? monMacDinh;

  @override
  State<_SuaGiaoVien> createState() => _SuaGiaoVienState();
}

class _SuaGiaoVienState extends State<_SuaGiaoVien> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _hoTen;
  late final TextEditingController _noiDay;
  late final TextEditingController _sdt;
  late LoaiBaiTap _loai;
  late String _monId;
  String? _truongId;
  String? _tinhId;
  bool _dangLuu = false;
  String? _loi;

  bool get _suaCu => widget.giaoVien != null;

  /// Thầy riêng của một học sinh — bớt hẳn phần trường và tỉnh.
  bool get _laRieng => widget.chuId != null;

  @override
  void initState() {
    super.initState();
    final g = widget.giaoVien;
    final s = context.read<AppState>();
    _hoTen = TextEditingController(text: g?.hoTen ?? '');
    _noiDay = TextEditingController(text: g?.noiDay ?? '');
    _sdt = TextEditingController(text: g?.soDienThoai ?? '');
    _loai = _laRieng
        ? LoaiBaiTap.hocThem
        : g?.loai ?? widget.loaiMacDinh ?? LoaiBaiTap.trenLop;
    _monId = g?.monId ?? widget.monMacDinh ?? s.monMacDinh;
    _truongId = g?.truongId;
    _tinhId = g?.tinhId;
  }

  @override
  void dispose() {
    _hoTen.dispose();
    _noiDay.dispose();
    _sdt.dispose();
    super.dispose();
  }

  Future<void> _luu() async {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    final trenLop = _loai == LoaiBaiTap.trenLop;

    if (!_laRieng && trenLop && _truongId == null) {
      setState(() => _loi = 'Thầy cô trên lớp phải thuộc một trường. Chưa có trường thì thêm ở tab Trường trước.');
      return;
    }

    setState(() {
      _dangLuu = true;
      _loi = null;
    });
    try {
      final id = await s.luuGiaoVien(GiaoVien(
        id: widget.giaoVien?.id ?? '',
        hoTen: _hoTen.text.trim(),
        monId: _monId,
        loai: _loai,
        noiDay: _noiDay.text.trim().isEmpty ? null : _noiDay.text.trim(),
        soDienThoai: _sdt.text.trim().isEmpty ? null : _sdt.text.trim(),
        truongId: trenLop && !_laRieng ? _truongId : null,
        tinhId: !trenLop && !_laRieng ? _tinhId : null,
        chuId: widget.chuId,
      ));
      if (!mounted) return;
      Navigator.of(context).pop(id);
    } on LoiHocTap catch (e) {
      if (mounted) setState(() => _loi = e.thongDiep);
    } catch (e) {
      if (mounted) setState(() => _loi = 'Không lưu được ($e).');
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  Future<void> _xoa() async {
    final g = widget.giaoVien;
    if (g == null) return;
    final dongY = await hoiXoa(
      context,
      'Xóa ${g.hoTen}?',
      giaiThich: 'Báo cáo và tiết học đã gắn với thầy cô này vẫn còn, chỉ mất tên người dạy.',
    );
    if (!dongY || !mounted) return;
    setState(() => _dangLuu = true);
    try {
      await context.read<AppState>().xoaGiaoVien(g.id);
      if (!mounted) return;
      Navigator.of(context).pop(null);
    } on LoiHocTap catch (e) {
      if (mounted) setState(() => _loi = e.thongDiep);
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final trenLop = _loai == LoaiBaiTap.trenLop;

    return Form(
      key: _form,
      child: KhungBieuMau(
        tieuDe: _suaCu ? 'Sửa thầy cô' : (_laRieng ? 'Thêm thầy cô dạy thêm' : 'Thêm thầy cô'),
        eyebrow: _laRieng ? 'Chỉ nhà mình thấy' : 'Danh mục dùng chung',
        nhanLuu: _suaCu ? 'Lưu thay đổi' : 'Thêm',
        dangLuu: _dangLuu,
        onLuu: _luu,
        onXoa: _suaCu ? _xoa : null,
        children: [
          if (!_laRieng) ...[
            const NhanO('Hạng mục'),
            Row(
              children: [
                for (final l in LoaiBaiTap.values) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _loai = l),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: Gap.md),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _loai == l ? l.mauNen : AppColor.giayTrang,
                          borderRadius: BorderRadius.circular(R.md),
                          border: Border.all(
                            color: _loai == l ? l.mau.withValues(alpha: .45) : AppColor.dongKe,
                            width: _loai == l ? 1.4 : 1,
                          ),
                        ),
                        child: Text(
                          l == LoaiBaiTap.trenLop ? 'Trên lớp' : 'Dạy thêm',
                          style: AppType.ui(13.5,
                              w: FontWeight.w600,
                              color: _loai == l ? l.mau : AppColor.mucNhat),
                        ),
                      ),
                    ),
                  ),
                  if (l != LoaiBaiTap.values.last) const SizedBox(width: Gap.sm),
                ],
              ],
            ),
            const SizedBox(height: Gap.lg),
          ],
          const NhanO('Họ và tên'),
          TextFormField(
            controller: _hoTen,
            textCapitalization: TextCapitalization.words,
            style: AppType.ui(15, w: FontWeight.w500),
            decoration: const InputDecoration(hintText: 'Cô Nguyễn Thị Lan'),
            validator: (v) => (v ?? '').trim().length >= 2 ? null : 'Nhập tên thầy cô',
          ),
          const SizedBox(height: Gap.lg),
          const NhanO('Môn dạy'),
          DropdownButtonFormField<String>(
            initialValue: s.monHoc.any((m) => m.id == _monId) ? _monId : null,
            isExpanded: true,
            style: AppType.ui(15, w: FontWeight.w500),
            hint: const Text('Chọn môn'),
            items: [
              for (final m in s.monHoc) DropdownMenuItem(value: m.id, child: Text(m.ten)),
            ],
            onChanged: (v) => setState(() => _monId = v ?? _monId),
            validator: (v) => v == null ? 'Chọn môn dạy' : null,
          ),
          if (!_laRieng) ...[
            const SizedBox(height: Gap.lg),
            if (trenLop) ...[
              const NhanO('Trường'),
              DropdownButtonFormField<String?>(
                initialValue: s.truong.any((t) => t.id == _truongId) ? _truongId : null,
                isExpanded: true,
                style: AppType.ui(15, w: FontWeight.w500),
                hint: const Text('Chọn trường'),
                items: [
                  for (final t in s.truong)
                    DropdownMenuItem<String?>(
                      value: t.id,
                      child: Text(
                        [t.ten, s.tenTinh(t.tinhId)].whereType<String>().join(' · '),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _truongId = v),
              ),
            ] else ...[
              const NhanO('Tỉnh (để lọc, không bắt buộc)'),
              DropdownButtonFormField<String?>(
                initialValue: s.tinh.any((t) => t.id == _tinhId) ? _tinhId : null,
                isExpanded: true,
                style: AppType.ui(15, w: FontWeight.w500),
                hint: const Text('Mọi tỉnh'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Mọi tỉnh')),
                  for (final t in s.tinh)
                    DropdownMenuItem<String?>(value: t.id, child: Text(t.ten)),
                ],
                onChanged: (v) => setState(() => _tinhId = v),
              ),
            ],
          ],
          const SizedBox(height: Gap.lg),
          NhanO(trenLop ? 'Lớp phụ trách (không bắt buộc)' : 'Nơi dạy (không bắt buộc)'),
          TextFormField(
            controller: _noiDay,
            textCapitalization: TextCapitalization.sentences,
            style: AppType.ui(15, w: FontWeight.w500),
            decoration: InputDecoration(
              hintText: trenLop ? 'Lớp 9A2' : 'Trung tâm Trí Đức, hoặc nhà cô',
            ),
          ),
          const SizedBox(height: Gap.lg),
          const NhanO('Số điện thoại (không bắt buộc)'),
          TextFormField(
            controller: _sdt,
            keyboardType: TextInputType.phone,
            style: AppType.ui(15, w: FontWeight.w500),
            decoration: const InputDecoration(hintText: '09xx xxx xxx'),
          ),
          if (_loi != null) ...[
            const SizedBox(height: Gap.md),
            HopLoi(_loi!),
          ],
        ],
      ),
    );
  }
}
