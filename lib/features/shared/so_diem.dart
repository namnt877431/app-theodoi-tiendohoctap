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
/// đều ghi được — cô trả bài là ghi ngay, khỏi đợi. Chạm khung là mở cả sổ.
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
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SoDiemScreen())),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(R.lg),
                border: Border.all(color: AppColor.dongKe),
              ),
              child: ds.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(Gap.lg),
                      child: Text(
                        'Sổ điểm như ở trường: mỗi môn một dòng, cột miệng, 15 phút, 1 tiết, '
                        'học kỳ và TBM. Cô trả bài là ghi vào. Chạm để mở sổ.',
                        style: AppType.ui(
                          13,
                          color: AppColor.mucNhat,
                          w: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < hien.length; i++) ...[
                          if (i > 0)
                            const Divider(
                              indent: Gap.lg,
                              endIndent: Gap.lg,
                              height: 1,
                            ),
                          _DongDiem(d: hien[i]),
                        ],
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Gap.lg,
                            0,
                            Gap.lg,
                            Gap.sm + 2,
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Mở sổ điểm của $ten ›',
                              style: AppType.ui(
                                12.5,
                                color: AppColor.muc,
                                w: FontWeight.w600,
                              ),
                            ),
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

/// Một dòng điểm gọn trên trang chủ: ô điểm bên trái, môn và cột, ngày.
class _DongDiem extends StatelessWidget {
  const _DongDiem({required this.d});
  final DiemThi d;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final mau = mauDiem(d);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.lg,
        vertical: Gap.sm + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: mau.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(R.md),
            ),
            child: Text(
              d.diemChu,
              style: AppType.numeric(16, w: FontWeight.w700, color: mau),
            ),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: s.tenMon(d.monId),
                style: AppType.ui(14.5, w: FontWeight.w700),
                children: [
                  TextSpan(
                    text: '  ${d.loai.nhanNgan} · HK${d.hocKi}',
                    style: AppType.ui(
                      12.5,
                      color: AppColor.mucNhat,
                      w: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: Gap.sm),
          Text(
            Ngay.ddMM(d.ngay),
            style: AppType.numeric(
              12,
              color: AppColor.mucNhat,
              w: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ cả sổ

/// Sổ điểm một học kì, đúng hình dạng tờ sổ điểm ở trường: mỗi môn một hàng
/// — đủ mọi môn trong danh mục — các cột Điểm miệng · Điểm 15 phút · Điểm 1
/// tiết · Học kỳ · TBM; nhiều điểm trong một ô ghi liền "10 | 9,5". Môn chấm
/// nhận xét hiện Đ / CĐ. Chạm một ô để ghi hay sửa điểm ở đúng môn, đúng cột.
class SoDiemScreen extends StatefulWidget {
  const SoDiemScreen({super.key});

  @override
  State<SoDiemScreen> createState() => _SoDiemScreenState();
}

class _SoDiemScreenState extends State<SoDiemScreen> {
  /// 1, 2 là học kỳ; 0 là cả năm.
  late int _cheDo = AppState.hocKiCua(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ten = s.hocSinhHienTai?.tenGoi ?? 'con';
    final caNam = _cheDo == 0;
    final ds = caNam ? s.diemThi : s.diemThi.where((d) => d.hocKi == _cheDo).toList();

    // Kết quả từng môn cho chế độ đang xem, để tính TB các môn và xếp loại.
    final ketQua = [
      for (final m in s.monHoc)
        caNam ? ketQuaCaNam(m.id, s.diemThi) : ketQuaHocKi(m.id, ds),
    ];
    final tbCacMon = tbCacMonCua(ketQua);
    final xepLoai = xepLoaiHocLuc(ketQua);
    // Còn môn nào chưa có TBM thì xếp loại chỉ là tạm — học lực thật cần đủ
    // mọi môn.
    final tamTinh = ketQua.any((k) => k.tb == null);

    return Scaffold(
      appBar: AppBar(title: Text('Sổ điểm của $ten')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => moGhiDiem(context, hocKi: caNam ? null : _cheDo),
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
                // Wrap chứ không Row: ba chip cộng chữ to có thể không vừa một
                // hàng trên máy hẹp.
                Wrap(
                  spacing: Gap.sm - 2,
                  runSpacing: Gap.sm - 2,
                  children: [
                    for (final (int cd, String nhan) in [(1, 'Học kỳ 1'), (2, 'Học kỳ 2'), (0, 'Cả năm')])
                      ChoiceChip(
                        label: Text(nhan),
                        selected: _cheDo == cd,
                        showCheckmark: false,
                        selectedColor: AppColor.muc,
                        visualDensity: VisualDensity.compact,
                        labelStyle: AppType.ui(13,
                            w: FontWeight.w600, color: _cheDo == cd ? Colors.white : AppColor.muc),
                        onSelected: (_) => setState(() => _cheDo = cd),
                      ),
                  ],
                ),
                const SizedBox(height: Gap.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        tbCacMon == null
                            ? '${ds.length} điểm đã ghi'
                            : 'TB các môn${tamTinh ? ' (tạm tính)' : ''}'
                                '${xepLoai == null ? '' : ' · Học lực $xepLoai'}',
                        style: AppType.ui(12.5, color: AppColor.mucNhat, w: FontWeight.w600, height: 1.4),
                      ),
                    ),
                    if (tbCacMon != null) ...[
                      const SizedBox(width: Gap.sm),
                      Text(
                        chuTbm(tbCacMon),
                        style: AppType.numeric(18, color: mauSo(tbCacMon), w: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Gap.md),
                if (s.monHoc.isEmpty)
                  const TrangTrong(
                    icon: Icons.menu_book_outlined,
                    tieuDe: 'Chưa có môn học nào',
                    moTa: 'Danh mục môn học còn trống nên chưa lập được sổ điểm.',
                  )
                else if (caNam)
                  _BangCaNam(ketQua: ketQua)
                else
                  _BangDiem(ds: ds, hocKi: _cheDo),
                const SizedBox(height: Gap.md),
                Text(
                  caNam
                      ? 'TB cả năm = (TBM học kỳ 1 + 2 × TBM học kỳ 2) ÷ 3. Học lực Giỏi: TB các môn '
                          'từ 8, không môn nào dưới 6,5, Toán hoặc Văn từ 8; Khá: từ 6,5, không môn '
                          'nào dưới 5; Trung bình: từ 5, không môn nào dưới 3,5.'
                      : 'TBM = (miệng + 15 phút + 2 × 1 tiết + 3 × học kỳ) ÷ tổng hệ số, chỉ tính '
                          'khi đã có cả điểm 1 tiết lẫn học kỳ. Chạm một ô để ghi hay sửa.',
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

/// Bảng cả năm: mỗi môn một hàng, ba cột TBM học kỳ 1, học kỳ 2 và cả năm.
class _BangCaNam extends StatelessWidget {
  const _BangCaNam({required this.ketQua});
  final List<KetQuaMon> ketQua;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final kieuDau = AppType.ui(11.5, w: FontWeight.w700, color: Colors.white, height: 1.25);
    Widget oDau(String chu) => Expanded(
          child: Text(chu, textAlign: TextAlign.center, style: kieuDau),
        );
    Widget o(String? chu, Color mau, {bool dam = false}) => Expanded(
          child: Center(
            child: Text(chu ?? '',
                style: AppType.numeric(13.5, w: dam ? FontWeight.w700 : FontWeight.w600, color: mau)),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: AppColor.dongKe),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColor.muc,
            padding: const EdgeInsets.symmetric(vertical: Gap.sm + 2),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Padding(
                    padding: const EdgeInsets.only(left: Gap.sm + 2),
                    child: Text('Môn học', style: kieuDau),
                  ),
                ),
                oDau('Học kỳ 1'),
                oDau('Học kỳ 2'),
                oDau('Cả năm'),
              ],
            ),
          ),
          for (var i = 0; i < ketQua.length; i++)
            Container(
              decoration: BoxDecoration(
                color: i.isOdd ? AppColor.skySoft.withValues(alpha: .6) : null,
                border: const Border(top: BorderSide(color: AppColor.dongKe)),
              ),
              padding: const EdgeInsets.symmetric(vertical: Gap.sm + 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Padding(
                      padding: const EdgeInsets.only(left: Gap.sm + 2, right: Gap.xs),
                      child: Text(s.tenMon(ketQua[i].monId),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.ui(13, w: FontWeight.w600, height: 1.25)),
                    ),
                  ),
                  o(ketQua[i].hk1?.chu, ketQua[i].hk1?.mau ?? AppColor.mucNhat),
                  o(ketQua[i].hk2?.chu, ketQua[i].hk2?.mau ?? AppColor.mucNhat),
                  o(ketQua[i].chu, ketQua[i].mau, dam: true),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- kết quả môn

/// Kết quả một môn trong một kỳ (hay cả năm): số, hoặc Đ/CĐ, hoặc chưa có.
class TbMon {
  const TbMon.so(double v)
      : so = v,
        dat = null;
  const TbMon.nhanXet(bool d)
      : so = null,
        dat = d;

  final double? so;
  final bool? dat;

  String get chu => so != null ? chuTbm(so!) : (dat! ? 'Đ' : 'CĐ');
  Color get mau => so != null ? mauSo(so!) : (dat! ? AppColor.xong : AppColor.butDo);
}

/// Kết quả một môn để tính TB các môn và xếp loại. [hk1], [hk2] chỉ có khi
/// xem cả năm. [chuaDu]: đã có điểm nhưng chưa đủ để ra TBM — xếp loại trên
/// số liệu này chỉ là tạm tính.
class KetQuaMon {
  const KetQuaMon(this.monId, {this.tb, this.hk1, this.hk2, this.chuaDu = false});
  final String monId;
  final TbMon? tb;
  final TbMon? hk1;
  final TbMon? hk2;
  final bool chuaDu;

  String? get chu => tb?.chu;
  Color get mau => tb?.mau ?? AppColor.mucNhat;
}

/// Kết quả một môn trong một học kỳ, từ điểm của kỳ đó.
KetQuaMon ketQuaHocKi(String monId, List<DiemThi> dsKi) {
  final ds = dsKi.where((d) => d.monId == monId).toList();
  final tb = _tbMon(ds);
  return KetQuaMon(monId, tb: tb, chuaDu: tb == null && ds.isNotEmpty);
}

/// Kết quả cả năm: (HK1 + 2 × HK2) ÷ 3; môn nhận xét là Đ khi cả hai kỳ Đ.
/// Thiếu một kỳ thì chưa tính.
KetQuaMon ketQuaCaNam(String monId, List<DiemThi> tatCa) {
  final ds = tatCa.where((d) => d.monId == monId).toList();
  final k1 = _tbMon(ds.where((d) => d.hocKi == 1).toList());
  final k2 = _tbMon(ds.where((d) => d.hocKi == 2).toList());
  TbMon? cn;
  if (k1 != null && k2 != null) {
    if (k1.so != null && k2.so != null) {
      cn = TbMon.so((k1.so! + 2 * k2.so!) / 3);
    } else if (k1.dat != null && k2.dat != null) {
      cn = TbMon.nhanXet(k1.dat! && k2.dat!);
    }
  }
  return KetQuaMon(monId, tb: cn, hk1: k1, hk2: k2, chuaDu: cn == null && ds.isNotEmpty);
}

TbMon? _tbMon(List<DiemThi> ds) {
  final so = diemTrungBinh(ds);
  if (so != null) return TbMon.so(so);
  final nhanXet = ds.where((d) => d.bangNhanXet).toList();
  if (nhanXet.isEmpty || ds.any((d) => !d.bangNhanXet)) return null;
  return TbMon.nhanXet(nhanXet.every((d) => d.dat ?? false));
}

/// Trung bình cộng TBM các môn chấm điểm; null khi chưa môn nào có TBM.
double? tbCacMonCua(List<KetQuaMon> ds) {
  final so = [for (final k in ds) if (k.tb?.so != null) k.tb!.so!];
  if (so.isEmpty) return null;
  return so.reduce((a, b) => a + b) / so.length;
}

/// Xếp loại học lực theo cách trường dùng với sổ điểm dạng này:
/// - Giỏi: TB các môn ≥ 8,0, Toán hoặc Văn ≥ 8,0, không môn nào dưới 6,5.
/// - Khá: ≥ 6,5, Toán hoặc Văn ≥ 6,5, không môn nào dưới 5,0.
/// - Trung bình: ≥ 5,0, Toán hoặc Văn ≥ 5,0, không môn nào dưới 3,5.
/// - Yếu: ≥ 3,5, không môn nào dưới 2,0. Còn lại: Kém.
/// Ba mức trên còn cần mọi môn chấm nhận xét đều Đ. Chưa có Toán lẫn Văn thì
/// bỏ điều kiện đó. Null khi chưa môn nào có TBM.
String? xepLoaiHocLuc(List<KetQuaMon> ds, {Set<String> monChinh = const {'m_toan', 'm_van'}}) {
  final tb = tbCacMonCua(ds);
  if (tb == null) return null;
  final so = [for (final k in ds) if (k.tb?.so != null) k.tb!.so!];
  final thap = so.reduce((a, b) => a < b ? a : b);
  final chinh = [for (final k in ds) if (monChinh.contains(k.monId) && k.tb?.so != null) k.tb!.so!];
  bool chinhDat(double muc) => chinh.isEmpty || chinh.any((v) => v >= muc);
  final nhanXetDat = ds.every((k) => k.tb?.dat != false);
  if (tb >= 8 && thap >= 6.5 && chinhDat(8) && nhanXetDat) return 'Giỏi';
  if (tb >= 6.5 && thap >= 5 && chinhDat(6.5) && nhanXetDat) return 'Khá';
  if (tb >= 5 && thap >= 3.5 && chinhDat(5) && nhanXetDat) return 'Trung bình';
  if (tb >= 3.5 && thap >= 2) return 'Yếu';
  return 'Kém';
}

/// Bảng sáu cột. Cộng lại vừa khít điện thoại 390 px trừ lề, để năm cột điểm
/// đều trong tầm mắt; màn rộng thì các cột điểm giãn ra. Hẹp hơn nữa thì cuộn.
class _BangDiem extends StatelessWidget {
  const _BangDiem({required this.ds, required this.hocKi});
  final List<DiemThi> ds;
  final int hocKi;

  static const _rongMon = 84.0;
  static const _rongToiThieu = {
    LoaiKiemTra.mieng: 62.0,
    LoaiKiemTra.muoiLamPhut: 62.0,
    LoaiKiemTra.giuaKi: 62.0,
    LoaiKiemTra.cuoiKi: 46.0,
  };
  static const _rongTb = 42.0;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();

    return LayoutBuilder(
      builder: (context, rang) {
        final toiThieu =
            _rongMon +
            _rongToiThieu.values.fold(0.0, (t, r) => t + r) +
            _rongTb;
        // Trừ 2 cho viền trái phải của khung.
        final thua =
            ((rang.maxWidth - 2 - toiThieu) / LoaiKiemTra.values.length).clamp(
              0.0,
              56.0,
            );
        final rongCot = {
          for (final l in LoaiKiemTra.values) l: _rongToiThieu[l]! + thua,
        };
        final rongBang =
            _rongMon + rongCot.values.fold(0.0, (t, r) => t + r) + _rongTb + 2;

        final bang = Container(
          width: rongBang,
          decoration: BoxDecoration(
            color: AppColor.giayTrang,
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(color: AppColor.dongKe),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _HangTieuDe(rongCot: rongCot),
              for (var i = 0; i < s.monHoc.length; i++)
                _HangMon(
                  mon: s.monHoc[i],
                  ds: ds.where((d) => d.monId == s.monHoc[i].id).toList(),
                  hocKi: hocKi,
                  rongCot: rongCot,
                  soLe: i.isOdd,
                ),
            ],
          ),
        );
        if (rongBang <= rang.maxWidth) return bang;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: bang,
        );
      },
    );
  }
}

/// Đầu bảng nền mực, chữ trắng — như tờ sổ điểm.
class _HangTieuDe extends StatelessWidget {
  const _HangTieuDe({required this.rongCot});
  final Map<LoaiKiemTra, double> rongCot;

  @override
  Widget build(BuildContext context) {
    final kieu = AppType.ui(
      11.5,
      w: FontWeight.w700,
      color: Colors.white,
      height: 1.25,
    );
    Widget o(double rong, String chu) => SizedBox(
      width: rong,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Text(chu, textAlign: TextAlign.center, style: kieu),
      ),
    );
    return Container(
      color: AppColor.muc,
      padding: const EdgeInsets.symmetric(vertical: Gap.sm + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _BangDiem._rongMon,
            child: Padding(
              padding: const EdgeInsets.only(left: Gap.sm + 2),
              child: Text('Môn học', style: kieu),
            ),
          ),
          for (final l in LoaiKiemTra.values) o(rongCot[l]!, l.nhan),
          o(_BangDiem._rongTb, 'TBM'),
        ],
      ),
    );
  }
}

class _HangMon extends StatelessWidget {
  const _HangMon({
    required this.mon,
    required this.ds,
    required this.hocKi,
    required this.rongCot,
    required this.soLe,
  });
  final MonHoc mon;
  final List<DiemThi> ds;
  final int hocKi;
  final Map<LoaiKiemTra, double> rongCot;
  final bool soLe;

  @override
  Widget build(BuildContext context) {
    final tbm = chuTbmMon(ds);
    return Container(
      decoration: BoxDecoration(
        color: soLe ? AppColor.skySoft.withValues(alpha: .6) : null,
        border: const Border(top: BorderSide(color: AppColor.dongKe)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _BangDiem._rongMon,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.sm + 2,
                Gap.sm,
                Gap.xs,
                Gap.sm,
              ),
              child: Text(
                mon.ten,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppType.ui(13, w: FontWeight.w600, height: 1.25),
              ),
            ),
          ),
          for (final l in LoaiKiemTra.values)
            _ODiem(
              rong: rongCot[l]!,
              ds: ds.where((d) => d.loai == l).toList()
                ..sort((a, b) => a.ngay.compareTo(b.ngay)),
              onTap: () =>
                  moODiem(context, monId: mon.id, loai: l, hocKi: hocKi),
            ),
          SizedBox(
            width: _BangDiem._rongTb,
            child: Center(
              child: Text(
                tbm ?? '',
                style: AppType.numeric(
                  13.5,
                  w: FontWeight.w700,
                  color: mauTbm(ds),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Một ô điểm: các điểm ghi liền, cách nhau bằng " | " như trên sổ; xuống
/// dòng khi nhiều. Ô trống để trống. Chạm để ghi hay sửa.
class _ODiem extends StatelessWidget {
  const _ODiem({required this.rong, required this.ds, required this.onTap});
  final double rong;
  final List<DiemThi> ds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: rong,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: Gap.sm),
          alignment: Alignment.center,
          child: Text.rich(
            TextSpan(
              children: [
                for (var i = 0; i < ds.length; i++) ...[
                  if (i > 0)
                    TextSpan(
                      text: ' | ',
                      style: AppType.numeric(
                        13,
                        color: AppColor.dongKeDam,
                        w: FontWeight.w500,
                      ),
                    ),
                  TextSpan(
                    text: ds[i].diemChu,
                    style: AppType.numeric(
                      13.5,
                      w: FontWeight.w600,
                      color: mauDiem(ds[i]),
                    ),
                  ),
                ],
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Màu theo mức xếp loại: xanh lá từ 8, mực từ 6,5, hổ phách từ 5, đỏ dưới
/// 5. Đ xanh lá, CĐ đỏ.
Color mauDiem(DiemThi d) {
  final so = d.diem;
  if (so == null) return (d.dat ?? false) ? AppColor.xong : AppColor.butDo;
  return mauSo(so);
}

Color mauSo(double d) => d >= 8
    ? AppColor.xong
    : d >= 6.5
    ? AppColor.muc
    : d >= 5
    ? AppColor.dangLam
    : AppColor.butDo;

Color mauTbm(List<DiemThi> ds) {
  final tb = diemTrungBinh(ds);
  if (tb != null) return mauSo(tb);
  final nhanXet = ds.where((d) => d.bangNhanXet).toList();
  if (nhanXet.isEmpty) return AppColor.mucNhat;
  return nhanXet.every((d) => d.dat ?? false) ? AppColor.xong : AppColor.butDo;
}

/// "9,7" — TBM lấy một chữ số thập phân, luôn có phần lẻ như trên sổ.
String chuTbm(double v) =>
    ((v * 10).round() / 10).toStringAsFixed(1).replaceAll('.', ',');

/// TBM của một môn dạng chữ: số, hoặc Đ / CĐ với môn chấm nhận xét, hoặc
/// null khi chưa tính được.
String? chuTbmMon(List<DiemThi> ds) {
  final tb = diemTrungBinh(ds);
  if (tb != null) return chuTbm(tb);
  final nhanXet = ds.where((d) => d.bangNhanXet).toList();
  if (nhanXet.isEmpty || ds.any((d) => !d.bangNhanXet)) return null;
  return nhanXet.every((d) => d.dat ?? false) ? 'Đ' : 'CĐ';
}

/// Điểm trung bình môn một học kì theo cách trường tính: mỗi điểm nhân hệ số
/// của cột (miệng, 15 phút 1; 1 tiết 2; học kỳ 3), chia tổng hệ số. Chưa có
/// cả 1 tiết lẫn học kỳ thì chưa tính — con số nửa vời chỉ gây hiểu nhầm.
/// Điểm Đ/CĐ không tham gia.
double? diemTrungBinh(List<DiemThi> ds) {
  final so = ds.where((d) => d.diem != null).toList();
  if (!so.any((d) => d.loai == LoaiKiemTra.giuaKi) ||
      !so.any((d) => d.loai == LoaiKiemTra.cuoiKi)) {
    return null;
  }
  var tong = 0.0;
  var heSo = 0;
  for (final d in so) {
    tong += d.diem! * d.loai.heSo;
    heSo += d.loai.heSo;
  }
  return tong / heSo;
}

// -------------------------------------------------------------------- ô

/// Chạm một ô trên sổ: ô trống thì ghi luôn; có điểm rồi thì liệt kê từng
/// điểm (ngày, ghi chú) để chạm sửa, kèm nút ghi thêm.
Future<void> moODiem(
  BuildContext context, {
  required String monId,
  required LoaiKiemTra loai,
  required int hocKi,
}) {
  final s = context.read<AppState>();
  final co = s.diemThi.any(
    (d) => d.monId == monId && d.loai == loai && d.hocKi == hocKi,
  );
  if (!co) return moGhiDiem(context, monId: monId, loai: loai, hocKi: hocKi);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: s,
      child: _ODiemSheet(monId: monId, loai: loai, hocKi: hocKi),
    ),
  );
}

class _ODiemSheet extends StatelessWidget {
  const _ODiemSheet({
    required this.monId,
    required this.loai,
    required this.hocKi,
  });
  final String monId;
  final LoaiKiemTra loai;
  final int hocKi;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ds =
        s.diemThi
            .where(
              (d) => d.monId == monId && d.loai == loai && d.hocKi == hocKi,
            )
            .toList()
          ..sort((a, b) => a.ngay.compareTo(b.ngay));

    // Material chứ không Container tô màu: ListTile vẽ mực chạm lên Material
    // gần nhất, tô màu ở giữa là che mất.
    return Material(
      color: AppColor.giayTrang,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(R.lg + 4)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.lg),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColor.dongKeDam,
                    borderRadius: BorderRadius.circular(R.pill),
                  ),
                ),
              ),
              const SizedBox(height: Gap.lg),
              TieuDeMuc(
                '${s.tenMon(monId)} · ${loai.nhanNgan}',
                eyebrow: 'Học kỳ $hocKi · ${ds.length} điểm',
                hanhDong: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    moGhiDiem(context, monId: monId, loai: loai, hocKi: hocKi);
                  },
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text('Ghi thêm'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(height: Gap.md),
              for (final d in ds)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Container(
                    width: 46,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: mauDiem(d).withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(R.md),
                    ),
                    child: Text(
                      d.diemChu,
                      style: AppType.numeric(
                        16,
                        w: FontWeight.w700,
                        color: mauDiem(d),
                      ),
                    ),
                  ),
                  title: Text(
                    Ngay.dayDu(d.ngay),
                    style: AppType.ui(14, w: FontWeight.w600),
                  ),
                  subtitle: (d.ghiChu ?? '').isEmpty
                      ? null
                      : Text(
                          d.ghiChu!,
                          style: AppType.ui(12.5, color: AppColor.mucNhat),
                        ),
                  trailing: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColor.mucNhat,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    moGhiDiem(context, d: d);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------- ghi

/// Bảng ghi hoặc sửa một điểm. Mở từ ô sổ thì [monId], [loai], [hocKi] đã
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

  late String _monId =
      widget.d?.monId ?? widget.monId ?? context.read<AppState>().monMacDinh;
  late LoaiKiemTra _loai = widget.d?.loai ?? widget.loai ?? LoaiKiemTra.mieng;
  late int _hocKi =
      widget.d?.hocKi ?? widget.hocKi ?? AppState.hocKiCua(DateTime.now());
  late DateTime _ngay = widget.d?.ngay ?? Ngay.dauNgay(DateTime.now());
  late final _diem = TextEditingController(
    text: widget.d?.diem == null ? '' : widget.d!.diemChu,
  );
  late final _ghiChu = TextEditingController(text: widget.d?.ghiChu ?? '');

  /// Môn chấm Đ/CĐ thay vì điểm số. Sửa điểm cũ thì theo điểm đó; ghi mới
  /// thì nhớ theo môn — lần trước môn này ghi Đ thì lần này cũng Đ.
  late bool _nhanXet = widget.d?.bangNhanXet ?? _monChamNhanXet(_monId);
  late bool _dat = widget.d?.dat ?? true;
  bool _dangLuu = false;

  bool _monChamNhanXet(String monId) {
    final cu = context
        .read<AppState>()
        .diemThi
        .where((d) => d.monId == monId)
        .firstOrNull;
    return cu?.bangNhanXet ?? false;
  }

  @override
  void dispose() {
    _diem.dispose();
    _ghiChu.dispose();
    super.dispose();
  }

  double? get _diemSo =>
      double.tryParse(_diem.text.trim().replaceAll(',', '.'));

  Future<void> _luu() async {
    final diem = _nhanXet ? null : _diemSo;
    if (!_nhanXet && (diem == null || diem < 0 || diem > 10)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Điểm từ 0 tới 10, ví dụ 8,5')),
      );
      return;
    }
    setState(() => _dangLuu = true);
    final s = context.read<AppState>();
    final cu = widget.d;
    final gc = _ghiChu.text.trim();
    try {
      if (cu == null) {
        await s.ghiDiem(
          monId: _monId,
          loai: _loai,
          hocKi: _hocKi,
          diem: diem,
          dat: _nhanXet ? _dat : null,
          ngay: _ngay,
          ghiChu: gc,
        );
      } else {
        await s.luuDiem(
          cu.copyWith(
            monId: _monId,
            loai: _loai,
            hocKi: _hocKi,
            diem: () => diem,
            dat: () => _nhanXet ? _dat : null,
            ngay: _ngay,
            ghiChu: () => gc.isEmpty ? null : gc,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangLuu = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không lưu được: $e')));
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
        const NhanO('Môn'),
        DropdownButtonFormField<String>(
          initialValue: s.monHoc.any((m) => m.id == _monId) ? _monId : null,
          isExpanded: true,
          style: AppType.ui(15, w: FontWeight.w500),
          items: [
            for (final m in s.monHoc)
              DropdownMenuItem(value: m.id, child: Text(m.ten)),
          ],
          onChanged: (v) => setState(() {
            _monId = v ?? _monId;
            if (!suaCu) _nhanXet = _monChamNhanXet(_monId);
          }),
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
                  nhan: l.nhanNgan,
                  mau: AppColor.muc,
                  mauNen: AppColor.sky,
                  chon: _loai == l,
                  onTap: () => setState(() => _loai = l),
                ),
              ),
              if (l != LoaiKiemTra.values.last)
                const SizedBox(width: Gap.sm - 2),
            ],
          ],
        ),
        const SizedBox(height: Gap.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: NhanO(_nhanXet ? 'Đạt hay chưa?' : 'Điểm')),
            TextButton(
              onPressed: () => setState(() => _nhanXet = !_nhanXet),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: Text(_nhanXet ? 'Chấm điểm số' : 'Môn chấm Đ / CĐ'),
            ),
          ],
        ),
        if (_nhanXet)
          Row(
            children: [
              for (final (bool gt, String nhan, IconData ic) in [
                (true, 'Đạt', Icons.check_circle_rounded),
                (false, 'Chưa đạt', Icons.cancel_rounded),
              ]) ...[
                Expanded(
                  child: OChon(
                    icon: ic,
                    nhan: nhan,
                    mau: gt ? AppColor.xong : AppColor.butDo,
                    mauNen: gt ? AppColor.xongNhat : AppColor.butDoNhat,
                    chon: _dat == gt,
                    onTap: () => setState(() => _dat = gt),
                  ),
                ),
                if (gt) const SizedBox(width: Gap.sm),
              ],
            ],
          )
        else ...[
          TextField(
            controller: _diem,
            autofocus: !suaCu,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            textAlign: TextAlign.center,
            style: AppType.numeric(22, w: FontWeight.w700),
            decoration: const InputDecoration(hintText: '8,5'),
            onChanged: (_) => setState(() {}),
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
                  labelStyle: AppType.numeric(
                    13,
                    w: FontWeight.w600,
                    color: _diemSo == d ? Colors.white : AppColor.muc,
                  ),
                  onSelected: (_) => setState(() => _diem.text = chuDiem(d)),
                ),
            ],
          ),
        ],
        const SizedBox(height: Gap.lg),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NhanO('Học kỳ'),
                  Row(
                    children: [
                      for (final ki in [1, 2]) ...[
                        ChoiceChip(
                          label: Text('HK$ki'),
                          selected: _hocKi == ki,
                          showCheckmark: false,
                          selectedColor: AppColor.muc,
                          labelStyle: AppType.ui(
                            13,
                            w: FontWeight.w600,
                            color: _hocKi == ki ? Colors.white : AppColor.muc,
                          ),
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
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 7)),
                      );
                      if (d != null) setState(() => _ngay = Ngay.dauNgay(d));
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(isDense: true),
                      child: Text(
                        Ngay.nhan(_ngay),
                        style: AppType.ui(14.5, w: FontWeight.w500),
                      ),
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
          decoration: const InputDecoration(
            hintText: 'Sai câu hình cuối…',
            counterText: '',
          ),
        ),
      ],
    );
  }
}
