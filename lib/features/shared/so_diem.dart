import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/layout/bo_cuc.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/ngay.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';

/// Khung sổ điểm trên trang chủ: ba điểm mới nhất và nút ghi. Con hay bố mẹ
/// đều ghi được — cô trả bài là ghi ngay, khỏi đợi.
class KhungSoDiem extends StatelessWidget {
  const KhungSoDiem({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ds = s.diemThi;
    final ten = s.hocSinhHienTai?.tenGoi ?? 'con';
    final hien = ds.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TieuDeMuc(
          'Sổ điểm',
          eyebrow: ds.isEmpty ? 'Chưa có điểm nào' : '${ds.length} điểm đã ghi',
          hanhDong: TextButton.icon(
            onPressed: () => moGhiDiem(context),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Ghi điểm'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ),
        const SizedBox(height: Gap.md),
        Material(
          color: AppColor.giayTrang,
          borderRadius: BorderRadius.circular(R.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(R.lg),
            onTap: ds.isEmpty
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SoDiemScreen()),
                    ),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(R.lg),
                border: Border.all(color: AppColor.dongKe),
              ),
              child: ds.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(Gap.lg),
                      child: Text(
                        'Cô trả bài kiểm tra là ghi vào đây — điểm thường xuyên, giữa kì, '
                        'cuối kì. Bố mẹ theo dõi được, và quà điểm thi đếm từ đây.',
                        style: AppType.ui(13, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.5),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < hien.length; i++) ...[
                          if (i > 0) const Divider(indent: Gap.lg, endIndent: Gap.lg, height: 1),
                          _DongDiem(d: hien[i], gon: true),
                        ],
                        if (ds.length > 3)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm + 2),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text('Xem cả sổ điểm của $ten ›',
                                  style: AppType.ui(12.5, color: AppColor.muc, w: FontWeight.w600)),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Một dòng điểm: ô điểm to bên trái, môn và loại bài, ngày.
class _DongDiem extends StatelessWidget {
  const _DongDiem({required this.d, this.gon = false, this.onTap});
  final DiemThi d;
  final bool gon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final mau = d.diem >= 8
        ? AppColor.xong
        : d.diem >= 6.5
            ? AppColor.muc
            : d.diem >= 5
                ? AppColor.dangLam
                : AppColor.butDo;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Gap.lg, vertical: gon ? Gap.sm + 2 : Gap.md),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: mau.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(R.md),
              ),
              child: Text(d.diemChu, style: AppType.numeric(17, w: FontWeight.w700, color: mau)),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: s.tenMon(d.monId),
                      style: AppType.ui(14.5, w: FontWeight.w700),
                      children: [
                        TextSpan(
                          text: '  ${d.loai.nhan} · HK${d.hocKi}',
                          style: AppType.ui(12.5, color: AppColor.mucNhat, w: FontWeight.w500),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!gon && (d.ghiChu ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(d.ghiChu!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.ui(12.5, color: AppColor.ink, w: FontWeight.w400, height: 1.4)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Gap.sm),
            Text(Ngay.ddMM(d.ngay),
                style: AppType.numeric(12, color: AppColor.mucNhat, w: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ cả sổ

/// Cả sổ điểm, theo học kì, gom theo môn. Chạm một dòng để sửa hay xóa.
class SoDiemScreen extends StatefulWidget {
  const SoDiemScreen({super.key});

  @override
  State<SoDiemScreen> createState() => _SoDiemScreenState();
}

class _SoDiemScreenState extends State<SoDiemScreen> {
  late int _hocKi = AppState.hocKiCua(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ten = s.hocSinhHienTai?.tenGoi ?? 'con';
    final ds = s.diemThi.where((d) => d.hocKi == _hocKi).toList();

    // Gom theo môn, giữ thứ tự danh mục môn.
    final theoMon = <String, List<DiemThi>>{};
    for (final d in ds) {
      theoMon.putIfAbsent(d.monId, () => []).add(d);
    }
    final thuTuMon = [
      for (final m in s.monHoc)
        if (theoMon.containsKey(m.id)) m.id,
      for (final id in theoMon.keys)
        if (!s.monHoc.any((m) => m.id == id)) id,
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Sổ điểm của $ten')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => moGhiDiem(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ghi điểm'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(BoCuc.le(context), Gap.sm, BoCuc.le(context), 96),
        children: [
          NoiDung(
            toiDa: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (final ki in [1, 2]) ...[
                      ChoiceChip(
                        label: Text('Học kì $ki'),
                        selected: _hocKi == ki,
                        showCheckmark: false,
                        selectedColor: AppColor.muc,
                        labelStyle: AppType.ui(13,
                            w: FontWeight.w600, color: _hocKi == ki ? Colors.white : AppColor.muc),
                        onSelected: (_) => setState(() => _hocKi = ki),
                      ),
                      const SizedBox(width: Gap.sm),
                    ],
                    const Spacer(),
                    Text('${ds.length} điểm',
                        style: AppType.ui(12.5, color: AppColor.mucNhat, w: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: Gap.lg),
                if (ds.isEmpty)
                  TrangTrong(
                    icon: Icons.grade_outlined,
                    tieuDe: 'Học kì $_hocKi chưa có điểm nào',
                    moTa: 'Cô trả bài là ghi vào — điểm thường xuyên, giữa kì, cuối kì.',
                  )
                else
                  for (final monId in thuTuMon) ...[
                    _NhomMon(monId: monId, ds: theoMon[monId]!),
                    const SizedBox(height: Gap.md),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NhomMon extends StatelessWidget {
  const _NhomMon({required this.monId, required this.ds});
  final String monId;
  final List<DiemThi> ds;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final tb = diemTrungBinh(ds);

    return Container(
      decoration: BoxDecoration(
        color: AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: AppColor.dongKe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xs),
            child: Row(
              children: [
                Expanded(child: Text(s.tenMon(monId), style: AppType.ui(15.5, w: FontWeight.w700))),
                Text(
                  tb == null ? '${ds.length} điểm' : 'TB ${_chu(tb)}',
                  style: AppType.numeric(13, color: tb == null ? AppColor.mucNhat : AppColor.muc, w: FontWeight.w700),
                ),
              ],
            ),
          ),
          for (final d in ds) _DongDiem(d: d, onTap: () => moGhiDiem(context, d: d)),
          const SizedBox(height: Gap.xs),
        ],
      ),
    );
  }

  static String _chu(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
}

/// Điểm trung bình môn một học kì theo cách trường tính: thường xuyên hệ số
/// 1, giữa kì hệ số 2, cuối kì hệ số 3, chia cho (số bài thường xuyên + 5).
/// Chưa có cả giữa kì lẫn cuối kì thì chưa tính — con số nửa vời chỉ gây
/// hiểu nhầm.
double? diemTrungBinh(List<DiemThi> ds) {
  final tx = ds.where((d) => d.loai == LoaiKiemTra.thuongXuyen).toList();
  final gk = ds.where((d) => d.loai == LoaiKiemTra.giuaKi).firstOrNull;
  final ck = ds.where((d) => d.loai == LoaiKiemTra.cuoiKi).firstOrNull;
  if (gk == null || ck == null) return null;
  final tong = tx.fold(0.0, (t, d) => t + d.diem) + 2 * gk.diem + 3 * ck.diem;
  return tong / (tx.length + 5);
}

// -------------------------------------------------------------------- ghi

/// Bảng ghi hoặc sửa một điểm.
Future<void> moGhiDiem(BuildContext context, {DiemThi? d}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: _GhiDiem(d: d),
    ),
  );
}

class _GhiDiem extends StatefulWidget {
  const _GhiDiem({this.d});
  final DiemThi? d;

  @override
  State<_GhiDiem> createState() => _GhiDiemState();
}

class _GhiDiemState extends State<_GhiDiem> {
  static const _diemNhanh = [10.0, 9.5, 9.0, 8.5, 8.0, 7.5, 7.0, 6.5];

  late String _monId = widget.d?.monId ?? context.read<AppState>().monMacDinh;
  late LoaiKiemTra _loai = widget.d?.loai ?? LoaiKiemTra.thuongXuyen;
  late int _hocKi = widget.d?.hocKi ?? AppState.hocKiCua(DateTime.now());
  late DateTime _ngay = widget.d?.ngay ?? Ngay.dauNgay(DateTime.now());
  late final _diem = TextEditingController(text: widget.d?.diemChu ?? '');
  late final _ghiChu = TextEditingController(text: widget.d?.ghiChu ?? '');
  bool _dangLuu = false;

  @override
  void dispose() {
    _diem.dispose();
    _ghiChu.dispose();
    super.dispose();
  }

  double? get _diemSo => double.tryParse(_diem.text.trim().replaceAll(',', '.'));

  Future<void> _luu() async {
    final diem = _diemSo;
    if (diem == null || diem < 0 || diem > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Điểm từ 0 tới 10, ví dụ 8,5')),
      );
      return;
    }
    setState(() => _dangLuu = true);
    final s = context.read<AppState>();
    final cu = widget.d;
    try {
      if (cu == null) {
        await s.ghiDiem(
          monId: _monId,
          loai: _loai,
          hocKi: _hocKi,
          diem: diem,
          ngay: _ngay,
          ghiChu: _ghiChu.text,
        );
      } else {
        final gc = _ghiChu.text.trim();
        await s.luuDiem(cu.copyWith(
          monId: _monId,
          loai: _loai,
          hocKi: _hocKi,
          diem: diem,
          ngay: _ngay,
          ghiChu: () => gc.isEmpty ? null : gc,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangLuu = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không lưu được: $e')));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _xoa() async {
    final dongY = await hoiXoa(context, 'Xóa điểm này?');
    if (!dongY || !mounted) return;
    await context.read<AppState>().xoaDiem(widget.d!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final suaCu = widget.d != null;

    return KhungBieuMau(
      tieuDe: suaCu ? 'Sửa điểm' : 'Ghi điểm',
      eyebrow: 'Sổ điểm của ${s.hocSinhHienTai?.tenGoi ?? 'con'}',
      nhanLuu: suaCu ? 'Lưu' : 'Ghi',
      dangLuu: _dangLuu,
      onLuu: _luu,
      onXoa: suaCu ? _xoa : null,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NhanO('Môn'),
                  DropdownButtonFormField<String>(
                    initialValue: s.monHoc.any((m) => m.id == _monId) ? _monId : null,
                    isExpanded: true,
                    style: AppType.ui(15, w: FontWeight.w500),
                    items: [
                      for (final m in s.monHoc) DropdownMenuItem(value: m.id, child: Text(m.ten)),
                    ],
                    onChanged: (v) => setState(() => _monId = v ?? _monId),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NhanO('Điểm'),
                  TextField(
                    controller: _diem,
                    autofocus: !suaCu,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    textAlign: TextAlign.center,
                    style: AppType.numeric(20, w: FontWeight.w700),
                    decoration: const InputDecoration(hintText: '8,5'),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.sm),
        Wrap(
          spacing: Gap.sm - 2,
          runSpacing: Gap.sm - 2,
          children: [
            for (final d in _diemNhanh)
              ChoiceChip(
                label: Text(chuDiem(d)),
                selected: _diemSo == d,
                showCheckmark: false,
                selectedColor: AppColor.muc,
                visualDensity: VisualDensity.compact,
                labelStyle: AppType.numeric(13,
                    w: FontWeight.w600, color: _diemSo == d ? Colors.white : AppColor.muc),
                onSelected: (_) => setState(() => _diem.text = chuDiem(d)),
              ),
          ],
        ),
        const SizedBox(height: Gap.lg),
        const NhanO('Bài gì?'),
        Row(
          children: [
            for (final l in LoaiKiemTra.values) ...[
              Expanded(
                child: OChon(
                  icon: switch (l) {
                    LoaiKiemTra.thuongXuyen => Icons.edit_note_rounded,
                    LoaiKiemTra.giuaKi => Icons.flag_rounded,
                    LoaiKiemTra.cuoiKi => Icons.emoji_events_rounded,
                  },
                  nhan: l.nhan,
                  mau: AppColor.muc,
                  mauNen: AppColor.sky,
                  chon: _loai == l,
                  onTap: () => setState(() => _loai = l),
                ),
              ),
              if (l != LoaiKiemTra.values.last) const SizedBox(width: Gap.sm),
            ],
          ],
        ),
        const SizedBox(height: Gap.lg),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NhanO('Học kì'),
                  Row(
                    children: [
                      for (final ki in [1, 2]) ...[
                        ChoiceChip(
                          label: Text('HK$ki'),
                          selected: _hocKi == ki,
                          showCheckmark: false,
                          selectedColor: AppColor.muc,
                          labelStyle: AppType.ui(13,
                              w: FontWeight.w600, color: _hocKi == ki ? Colors.white : AppColor.muc),
                          onSelected: (_) => setState(() => _hocKi = ki),
                        ),
                        const SizedBox(width: Gap.sm),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NhanO('Ngày'),
                  InkWell(
                    borderRadius: BorderRadius.circular(R.md),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _ngay,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 7)),
                      );
                      if (d != null) setState(() => _ngay = Ngay.dauNgay(d));
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(isDense: true),
                      child: Text(Ngay.nhan(_ngay), style: AppType.ui(14.5, w: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.lg),
        const NhanO('Ghi chú (không bắt buộc)'),
        TextField(
          controller: _ghiChu,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          style: AppType.ui(14.5, w: FontWeight.w400),
          decoration: const InputDecoration(hintText: 'Sai câu hình cuối…', counterText: ''),
        ),
      ],
    );
  }
}
