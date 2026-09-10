import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/ngay.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';

/// Bảng thêm/sửa một tiết. Mở từ ô trống trong lưới thì thứ và tiết đã điền sẵn,
/// nên phần lớn trường hợp chỉ còn chọn môn rồi lưu.
Future<void> moSuaTietHoc(
  BuildContext context, {
  TietHoc? tietHoc,
  int? thu,
  int? tiet,
  Buoi? buoi,
  LoaiBaiTap? loai,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: _SuaTietHoc(
        tietHoc: tietHoc,
        thuMacDinh: thu,
        tietMacDinh: tiet,
        buoiMacDinh: buoi,
        loaiMacDinh: loai,
      ),
    ),
  );
}

class _SuaTietHoc extends StatefulWidget {
  const _SuaTietHoc({
    this.tietHoc,
    this.thuMacDinh,
    this.tietMacDinh,
    this.buoiMacDinh,
    this.loaiMacDinh,
  });

  final TietHoc? tietHoc;
  final int? thuMacDinh;
  final int? tietMacDinh;
  final Buoi? buoiMacDinh;
  final LoaiBaiTap? loaiMacDinh;

  @override
  State<_SuaTietHoc> createState() => _SuaTietHocState();
}

class _SuaTietHocState extends State<_SuaTietHoc> {
  late LoaiBaiTap _loai;
  late int _thu;
  late int _tiet;
  late Buoi _buoi;
  late String _monId;
  String? _gvId;
  late TextEditingController _phong;
  late TextEditingController _batDau;
  late TextEditingController _ketThuc;

  bool get _suaCu => widget.tietHoc != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tietHoc;
    _loai = t?.loai ?? widget.loaiMacDinh ?? LoaiBaiTap.trenLop;
    _thu = t?.thu ?? widget.thuMacDinh ?? Ngay.cotTuNgay(DateTime.now());
    _tiet = t?.tiet ?? widget.tietMacDinh ?? 1;
    _buoi = t?.buoi ?? widget.buoiMacDinh ?? Buoi.sang;
    _monId = t?.monId ?? context.read<AppState>().monHoc.first.id;
    _gvId = t?.giaoVienId;
    _phong = TextEditingController(text: t?.phong ?? '');
    _batDau = TextEditingController(text: t?.batDau ?? '');
    _ketThuc = TextEditingController(text: t?.ketThuc ?? '');
  }

  @override
  void dispose() {
    _phong.dispose();
    _batDau.dispose();
    _ketThuc.dispose();
    super.dispose();
  }

  Future<void> _luu() async {
    final s = context.read<AppState>();
    final goc = widget.tietHoc;
    final moi = TietHoc(
      id: goc?.id ?? 'tam',
      hocSinhId: goc?.hocSinhId ?? s.hocSinhHienTai?.id ?? '',
      thu: _thu,
      tiet: _tiet,
      buoi: _buoi,
      monId: _monId,
      loai: _loai,
      giaoVienId: _gvId,
      phong: _phong.text.trim().isEmpty ? null : _phong.text.trim(),
      batDau: _batDau.text.trim().isEmpty ? null : _batDau.text.trim(),
      ketThuc: _ketThuc.text.trim().isEmpty ? null : _ketThuc.text.trim(),
    );
    await s.luuTiet(moi, moi: !_suaCu);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_suaCu ? 'Đã lưu tiết học' : 'Đã thêm tiết học')),
    );
  }

  Future<void> _xoa() async {
    final s = context.read<AppState>();
    await s.xoaTiet(widget.tietHoc!.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa tiết học')),
    );
  }
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final dsGv = s.gvTheoLoai(_loai);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .88),
        decoration: const BoxDecoration(
          color: AppColor.giayTrang,
          borderRadius: BorderRadius.vertical(top: Radius.circular(R.lg + 4)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Gap.md),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.dongKeDam,
                  borderRadius: BorderRadius.circular(R.pill),
                ),
              ),
              const SizedBox(height: Gap.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                child: TieuDeMuc(
                  _suaCu ? 'Sửa tiết học' : 'Thêm tiết học',
                  eyebrow: '${Ngay.thuTuCot(_thu)} · Tiết $_tiet · Buổi ${_buoi.nhan.toLowerCase()}',
                ),
              ),
              const SizedBox(height: Gap.lg),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
                  children: [
                    _Nhan('Hạng mục'),
                    Row(
                      children: [
                        for (final l in LoaiBaiTap.values) ...[
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _loai = l;
                                _gvId = null;
                                if (l == LoaiBaiTap.hocThem) _buoi = Buoi.toi;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: Gap.md),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _loai == l ? l.mauNen : AppColor.giayTrang,
                                  borderRadius: BorderRadius.circular(R.md),
                                  border: Border.all(
                                    color: _loai == l
                                        ? l.mau.withValues(alpha: .45)
                                        : AppColor.dongKe,
                                    width: _loai == l ? 1.4 : 1,
                                  ),
                                ),
                                child: Text(
                                  l.nhan,
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
                    _Nhan('Môn học'),
                    DropdownButtonFormField<String>(
                      initialValue: _monId,
                      isExpanded: true,
                      style: AppType.ui(15, w: FontWeight.w500),
                      items: [
                        for (final m in s.monHoc)
                          DropdownMenuItem(value: m.id, child: Text(m.ten)),
                      ],
                      onChanged: (v) => setState(() => _monId = v!),
                    ),
                    const SizedBox(height: Gap.lg),
                    _Nhan(_loai == LoaiBaiTap.hocThem ? 'Thầy cô dạy thêm' : 'Giáo viên bộ môn'),
                    DropdownButtonFormField<String?>(
                      initialValue: _gvId,
                      isExpanded: true,
                      style: AppType.ui(15, w: FontWeight.w500),
                      hint: const Text('Chưa chọn'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Chưa chọn')),
                        for (final g in dsGv)
                          DropdownMenuItem<String?>(
                            value: g.id,
                            child: Text('${g.hoTen} · ${s.vietTatMon(g.monId)}'),
                          ),
                      ],
                      onChanged: (v) => setState(() => _gvId = v),
                    ),
                    const SizedBox(height: Gap.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Nhan('Thứ'),
                              DropdownButtonFormField<int>(
                                initialValue: _thu,
                                isExpanded: true,
                                style: AppType.ui(15, w: FontWeight.w500),
                                items: [
                                  for (var c = 2; c <= 8; c++)
                                    DropdownMenuItem(value: c, child: Text(Ngay.thuTuCot(c))),
                                ],
                                onChanged: (v) => setState(() => _thu = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Nhan('Buổi'),
                              DropdownButtonFormField<Buoi>(
                                initialValue: _buoi,
                                isExpanded: true,
                                style: AppType.ui(15, w: FontWeight.w500),
                                items: [
                                  for (final b in Buoi.values)
                                    DropdownMenuItem(value: b, child: Text(b.nhan)),
                                ],
                                onChanged: (v) => setState(() => _buoi = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Nhan('Tiết'),
                              DropdownButtonFormField<int>(
                                initialValue: _tiet,
                                isExpanded: true,
                                style: AppType.ui(15, w: FontWeight.w500),
                                items: [
                                  for (var t = 1; t <= 10; t++)
                                    DropdownMenuItem(value: t, child: Text('Tiết $t')),
                                ],
                                onChanged: (v) => setState(() => _tiet = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Nhan('Phòng / nơi học'),
                              TextField(
                                controller: _phong,
                                decoration: const InputDecoration(hintText: 'P.204'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.lg),
                    Row(
                      children: [
                        Expanded(child: _OGio(nhan: 'Bắt đầu', c: _batDau)),
                        const SizedBox(width: Gap.md),
                        Expanded(child: _OGio(nhan: 'Kết thúc', c: _ketThuc)),
                      ],
                    ),
                    const SizedBox(height: Gap.xl),
                    Row(
                      children: [
                        if (_suaCu) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _xoa,
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              label: const Text('Xóa'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColor.butDo,
                                side: BorderSide(color: AppColor.butDo.withValues(alpha: .35)),
                              ),
                            ),
                          ),
                          const SizedBox(width: Gap.md),
                        ],
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _luu,
                            child: Text(_suaCu ? 'Lưu thay đổi' : 'Thêm vào thời khóa biểu'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Nhan extends StatelessWidget {
  const _Nhan(this.chu);
  final String chu;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Gap.sm, left: 2),
        child: Eyebrow(chu),
      );
}

class _OGio extends StatelessWidget {
  const _OGio({required this.nhan, required this.c});
  final String nhan;
  final TextEditingController c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Nhan(nhan),
        TextField(
          controller: c,
          readOnly: true,
          decoration: const InputDecoration(
            hintText: '--:--',
            suffixIcon: Icon(Icons.schedule_rounded, size: 18, color: AppColor.mucNhat),
          ),
          onTap: () async {
            final t = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 7, minute: 15),
            );
            if (t != null) {
              c.text =
                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
            }
          },
        ),
      ],
    );
  }
}
