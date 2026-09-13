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
                        'Cô trả bài là ghi vào — miệng, 15 phút, giữa kì, cuối kì — thành '
                        'bảng điểm đủ các môn, có điểm trung bình. Quà điểm thi đếm từ đây.',
                        style: AppType.ui(13, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.5),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < hien.length; i++) ...[
                          if (i > 0) const Divider(indent: Gap.lg, endIndent: Gap.lg, height: 1),
                          _DongDiem(d: hien[i], gon: true, onTap: () => moGhiDiem(context, d: hien[i])),
                        ],
                        if (ds.length > 3)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm + 2),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text('Xem bảng điểm của $ten ›',
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
    final mau = mauDiem(d.diem);
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

/// Bảng điểm một học kì, đúng dạng sổ điểm ở trường: mỗi môn một hàng, các
/// cột Miệng · 15 phút · Giữa kì · Cuối kì · TB. Đủ mọi môn trong danh mục,
/// kể cả môn chưa có điểm — nhìn là biết còn thiếu cột nào. Chạm một điểm để
/// sửa, chạm ô trống để ghi vào đúng môn, đúng cột.
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
    final tbCacMon = [
      for (final m in s.monHoc) diemTrungBinh(ds.where((d) => d.monId == m.id).toList()),
    ].whereType<double>().toList();

    return Scaffold(
      appBar: AppBar(title: Text('Bảng điểm của $ten')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => moGhiDiem(context, hocKi: _hocKi),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ghi điểm'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(BoCuc.le(context), Gap.sm, BoCuc.le(context), 96),
        children: [
          NoiDung(
            toiDa: 900,
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
                    Expanded(
                      child: Text(
                        tbCacMon.isEmpty
                            ? '${ds.length} điểm'
                            : 'TB các môn ${chuDiem(_lamTron(tbCacMon.reduce((a, b) => a + b) / tbCacMon.length))}',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.numeric(12.5,
                            color: tbCacMon.isEmpty ? AppColor.mucNhat : AppColor.muc,
                            w: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.md),
                if (s.monHoc.isEmpty)
                  const TrangTrong(
                    icon: Icons.menu_book_outlined,
                    tieuDe: 'Chưa có môn học nào',
                    moTa: 'Danh mục môn học còn trống nên chưa lập được bảng điểm.',
                  )
                else
                  _BangDiem(ds: ds, hocKi: _hocKi),
                const SizedBox(height: Gap.md),
                Text(
                  'TB môn = (miệng + 15 phút + 2 × giữa kì + 3 × cuối kì) ÷ (số bài nhỏ + 5), '
                  'chỉ tính khi đã có cả giữa kì lẫn cuối kì.',
                  style: AppType.ui(12, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bảng cuộn ngang khi màn hẹp. Cột môn giữ bề rộng cố định; bốn cột điểm và
/// cột TB giãn ra khi có chỗ.
class _BangDiem extends StatelessWidget {
  const _BangDiem({required this.ds, required this.hocKi});
  final List<DiemThi> ds;
  final int hocKi;

  // Cộng lại đúng 358 — vừa khít điện thoại 390 trừ lề, để năm cột điểm đều
  // nằm trong tầm mắt, không phải cuộn mới thấy giữa kì, cuối kì.
  static const _rongMon = 84.0;
  static const _rongToiThieu = {
    LoaiKiemTra.mieng: 64.0,
    LoaiKiemTra.muoiLamPhut: 64.0,
    LoaiKiemTra.giuaKi: 52.0,
    LoaiKiemTra.cuoiKi: 52.0,
  };
  static const _rongTb = 42.0;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();

    return LayoutBuilder(builder: (context, rang) {
      final toiThieu = _rongMon + _rongToiThieu.values.fold(0.0, (t, r) => t + r) + _rongTb;
      // Thừa chỗ thì chia đều cho các cột điểm; thiếu thì giữ tối thiểu và cuộn.
      // Trừ 2 cho viền trái phải của khung.
      final thua = ((rang.maxWidth - 2 - toiThieu) / LoaiKiemTra.values.length).clamp(0.0, 48.0);
      final rongCot = {
        for (final l in LoaiKiemTra.values) l: _rongToiThieu[l]! + thua,
      };
      final rongBang = _rongMon + rongCot.values.fold(0.0, (t, r) => t + r) + _rongTb + 2;

      final bang = Container(
        width: rongBang,
        decoration: BoxDecoration(
          color: AppColor.giayTrang,
          borderRadius: BorderRadius.circular(R.lg),
          border: Border.all(color: AppColor.dongKe),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _HangTieuDe(rongCot: rongCot),
            for (final m in s.monHoc) ...[
              const Divider(height: 1),
              _HangMon(
                mon: m,
                ds: ds.where((d) => d.monId == m.id).toList(),
                hocKi: hocKi,
                rongCot: rongCot,
              ),
            ],
          ],
        ),
      );
      if (rongBang <= rang.maxWidth) return bang;
      return SingleChildScrollView(scrollDirection: Axis.horizontal, child: bang);
    });
  }
}

class _HangTieuDe extends StatelessWidget {
  const _HangTieuDe({required this.rongCot});
  final Map<LoaiKiemTra, double> rongCot;

  @override
  Widget build(BuildContext context) {
    Widget o(double rong, String chu) => SizedBox(
          width: rong,
          child: Center(child: Eyebrow(chu)),
        );
    return Container(
      color: AppColor.skySoft,
      padding: const EdgeInsets.symmetric(vertical: Gap.sm + 2),
      child: Row(
        children: [
          SizedBox(
            width: _BangDiem._rongMon,
            child: Padding(
              padding: const EdgeInsets.only(left: Gap.md),
              child: Eyebrow('Môn'),
            ),
          ),
          for (final l in LoaiKiemTra.values) o(rongCot[l]!, l.nhan),
          o(_BangDiem._rongTb, 'TB'),
        ],
      ),
    );
  }
}

class _HangMon extends StatelessWidget {
  const _HangMon({required this.mon, required this.ds, required this.hocKi, required this.rongCot});
  final MonHoc mon;
  final List<DiemThi> ds;
  final int hocKi;
  final Map<LoaiKiemTra, double> rongCot;

  @override
  Widget build(BuildContext context) {
    final tb = diemTrungBinh(ds);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _BangDiem._rongMon,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.xs, Gap.sm),
            child: Text(
              mon.ten,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppType.ui(13.5, w: FontWeight.w700, height: 1.25),
            ),
          ),
        ),
        for (final l in LoaiKiemTra.values)
          _ODiem(
            rong: rongCot[l]!,
            ds: ds.where((d) => d.loai == l).toList()..sort((a, b) => a.ngay.compareTo(b.ngay)),
            onThem: () => moGhiDiem(context, monId: mon.id, loai: l, hocKi: hocKi),
          ),
        SizedBox(
          width: _BangDiem._rongTb,
          child: Center(
            child: Text(
              tb == null ? '—' : chuDiem(_lamTron(tb)),
              style: AppType.numeric(14, w: FontWeight.w700, color: tb == null ? AppColor.dongKeDam : mauDiem(tb)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Một ô trong bảng: các điểm đã có, chạm điểm để sửa; chạm chỗ trống để ghi
/// thêm vào đúng môn và cột này.
class _ODiem extends StatelessWidget {
  const _ODiem({required this.rong, required this.ds, required this.onThem});
  final double rong;
  final List<DiemThi> ds;
  final VoidCallback onThem;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: rong,
      child: InkWell(
        onTap: onThem,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: Gap.sm),
          child: ds.isEmpty
              ? Center(
                  child: Icon(Icons.add_rounded, size: 16, color: AppColor.dongKeDam),
                )
              : Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final d in ds)
                      _ChipDiem(d: d, onTap: () => moGhiDiem(context, d: d)),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ChipDiem extends StatelessWidget {
  const _ChipDiem({required this.d, required this.onTap});
  final DiemThi d;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mau = mauDiem(d.diem);
    return Material(
      color: mau.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(R.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(R.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Text(d.diemChu, style: AppType.numeric(12.5, w: FontWeight.w700, color: mau)),
        ),
      ),
    );
  }
}

/// Màu theo mức điểm: xanh lá từ 8, mực từ 6,5, hổ phách từ 5, đỏ dưới 5 —
/// đúng bốn mức xếp loại ở trường.
Color mauDiem(double d) => d >= 8
    ? AppColor.xong
    : d >= 6.5
        ? AppColor.muc
        : d >= 5
            ? AppColor.dangLam
            : AppColor.butDo;

double _lamTron(double v) => (v * 10).round() / 10;

/// Điểm trung bình môn một học kì theo cách trường tính: mỗi điểm nhân hệ số
/// của cột (miệng, 15 phút 1; giữa kì 2; cuối kì 3), chia tổng hệ số. Chưa có
/// cả giữa kì lẫn cuối kì thì chưa tính — con số nửa vời chỉ gây hiểu nhầm.
double? diemTrungBinh(List<DiemThi> ds) {
  if (!ds.any((d) => d.loai == LoaiKiemTra.giuaKi) || !ds.any((d) => d.loai == LoaiKiemTra.cuoiKi)) {
    return null;
  }
  var tong = 0.0;
  var heSo = 0;
  for (final d in ds) {
    tong += d.diem * d.loai.heSo;
    heSo += d.loai.heSo;
  }
  return tong / heSo;
}

// -------------------------------------------------------------------- ghi

/// Bảng ghi hoặc sửa một điểm. Mở từ ô bảng thì [monId], [loai], [hocKi] đã
/// đặt sẵn, chỉ còn gõ điểm.
Future<void> moGhiDiem(
  BuildContext context, {
  DiemThi? d,
  String? monId,
  LoaiKiemTra? loai,
  int? hocKi,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: _GhiDiem(d: d, monId: monId, loai: loai, hocKi: hocKi),
    ),
  );
}

class _GhiDiem extends StatefulWidget {
  const _GhiDiem({this.d, this.monId, this.loai, this.hocKi});
  final DiemThi? d;
  final String? monId;
  final LoaiKiemTra? loai;
  final int? hocKi;

  @override
  State<_GhiDiem> createState() => _GhiDiemState();
}

class _GhiDiemState extends State<_GhiDiem> {
  static const _diemNhanh = [10.0, 9.5, 9.0, 8.5, 8.0, 7.5, 7.0, 6.5];

  late String _monId = widget.d?.monId ?? widget.monId ?? context.read<AppState>().monMacDinh;
  late LoaiKiemTra _loai = widget.d?.loai ?? widget.loai ?? LoaiKiemTra.mieng;
  late int _hocKi = widget.d?.hocKi ?? widget.hocKi ?? AppState.hocKiCua(DateTime.now());
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
      eyebrow: 'Bảng điểm của ${s.hocSinhHienTai?.tenGoi ?? 'con'}',
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
        const NhanO('Cột nào?'),
        Row(
          children: [
            for (final l in LoaiKiemTra.values) ...[
              Expanded(
                child: OChon(
                  icon: switch (l) {
                    LoaiKiemTra.mieng => Icons.record_voice_over_rounded,
                    LoaiKiemTra.muoiLamPhut => Icons.timer_outlined,
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
              if (l != LoaiKiemTra.values.last) const SizedBox(width: Gap.sm - 2),
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
