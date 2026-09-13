import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/ngay.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';
import 'sua_tiet_hoc.dart';

const _cotThu = [2, 3, 4, 5, 6, 7, 8];

/// Ô hẹp nhất còn đọc được tên môn viết tắt; màn hẹp thì giữ cỡ này và
/// cuộn ngang, màn rộng thì ô giãn ra cho bảy cột lấp đầy bề ngang.
const _rongOToiThieu = 80.0;
const _caoO = 64.0;
const _rongCotTiet = 36.0;
const _khe = 4.0;

/// Thời khóa biểu giữ đúng hình dạng tờ giấy dán cánh tủ: hàng là tiết,
/// cột là thứ. Buổi học thêm tách riêng xuống dưới vì nó không nằm trong
/// khung tiết của trường.
class ThoiKhoaBieuScreen extends StatefulWidget {
  const ThoiKhoaBieuScreen({super.key});

  @override
  State<ThoiKhoaBieuScreen> createState() => _ThoiKhoaBieuScreenState();
}

class _ThoiKhoaBieuScreenState extends State<ThoiKhoaBieuScreen> {
  Buoi _buoi = Buoi.sang;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final hs = s.hocSinhHienTai;
    final hocThem = s.tkb.where((t) => t.loai == LoaiBaiTap.hocThem).toList()
      ..sort((a, b) => a.thu.compareTo(b.thu));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thời khóa biểu'),
            if (hs != null)
              Text(
                '${hs.hoTen} · Lớp ${hs.lop}',
                style: AppType.ui(11.5, color: AppColor.mucNhat, w: FontWeight.w500),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Gap.lg),
            child: NutO(
              icon: Icons.add_rounded,
              tooltip: 'Thêm tiết học',
              onTap: () => moSuaTietHoc(context, buoi: _buoi),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Gap.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.md),
            child: _ChonBuoi(buoi: _buoi, onChon: (b) => setState(() => _buoi = b)),
          ),
          _LuoiTkb(buoi: _buoi),
          const SizedBox(height: Gap.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            child: TieuDeMuc(
              'Học thêm trong tuần',
              eyebrow: '${hocThem.length} buổi',
              hanhDong: TextButton.icon(
                onPressed: () =>
                    moSuaTietHoc(context, buoi: Buoi.toi, loai: LoaiBaiTap.hocThem),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text('Thêm buổi'),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ),
          ),
          const SizedBox(height: Gap.md),
          if (hocThem.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Gap.lg),
                decoration: BoxDecoration(
                  color: AppColor.hocThemNhat,
                  borderRadius: BorderRadius.circular(R.md),
                ),
                child: Text(
                  'Chưa khai buổi học thêm nào. Thêm vào đây để báo cáo học thêm gắn đúng thầy cô.',
                  style: AppType.ui(13, color: AppColor.hocThem, w: FontWeight.w500, height: 1.5),
                ),
              ),
            )
          else
            for (final t in hocThem)
              Padding(
                padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm + 2),
                child: _DongHocThem(t),
              ),
        ],
      ),
    );
  }
}

class _ChonBuoi extends StatelessWidget {
  const _ChonBuoi({required this.buoi, required this.onChon});
  final Buoi buoi;
  final ValueChanged<Buoi> onChon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColor.sky,
        borderRadius: BorderRadius.circular(R.md),
      ),
      child: Row(
        children: [
          for (final b in [Buoi.sang, Buoi.chieu])
            Expanded(
              child: GestureDetector(
                onTap: () => onChon(b),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: buoi == b ? AppColor.giayTrang : Colors.transparent,
                    borderRadius: BorderRadius.circular(R.sm + 1),
                    border: Border.all(
                      color: buoi == b ? AppColor.dongKe : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    'Buổi ${b.nhan.toLowerCase()}',
                    style: AppType.ui(13.5,
                        w: FontWeight.w600,
                        color: buoi == b ? AppColor.ink : AppColor.mucNhat),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Lưới tiết × thứ. Cột tiết ghim bên trái, phần còn lại cuộn ngang —
/// giữ được hình dạng bảng thật mà vẫn vừa màn hình điện thoại.
class _LuoiTkb extends StatelessWidget {
  const _LuoiTkb({required this.buoi});
  final Buoi buoi;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final homNay = Ngay.cotTuNgay(DateTime.now());

    return LayoutBuilder(builder: (context, rang) {
      final conLai = rang.maxWidth - Gap.lg * 2 - _rongCotTiet - _khe - _khe * (_cotThu.length - 1);
      final rongO = (conLai / _cotThu.length).clamp(_rongOToiThieu, 140.0).toDouble();
      return _luoi(context, s, homNay, rongO);
    });
  }

  Widget _luoi(BuildContext context, AppState s, int homNay, double rongO) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: Gap.lg),
        Column(
          children: [
            SizedBox(
              height: 34,
              width: _rongCotTiet,
              child: Center(child: Eyebrow('Tiết')),
            ),
            for (var tiet = 1; tiet <= 5; tiet++)
              Container(
                width: _rongCotTiet,
                height: _caoO,
                margin: const EdgeInsets.only(bottom: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColor.sky.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(R.sm),
                ),
                child: Text('$tiet', style: AppType.numeric(15, color: AppColor.muc)),
              ),
          ],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: Gap.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (final cot in _cotThu)
                      SizedBox(
                        width: rongO,
                        height: 34,
                        child: Center(
                          child: Text(
                            Ngay.thuNganTuCot(cot),
                            style: AppType.ui(
                              12.5,
                              w: cot == homNay ? FontWeight.w800 : FontWeight.w600,
                              color: cot == homNay ? AppColor.muc : AppColor.mucNhat,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                for (var tiet = 1; tiet <= 5; tiet++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        for (final cot in _cotThu)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _OLuoi(
                              tiet: s.tkbTai(cot, tiet, buoi),
                              thu: cot,
                              soTiet: tiet,
                              buoi: buoi,
                              homNay: cot == homNay,
                              rong: rongO,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OLuoi extends StatelessWidget {
  const _OLuoi({
    required this.tiet,
    required this.thu,
    required this.soTiet,
    required this.buoi,
    required this.homNay,
    required this.rong,
  });

  final TietHoc? tiet;
  final int thu;
  final int soTiet;
  final Buoi buoi;
  final bool homNay;
  final double rong;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final t = tiet;

    if (t == null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(R.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(R.sm),
          onTap: () => moSuaTietHoc(context, thu: thu, tiet: soTiet, buoi: buoi),
          child: Ink(
            width: rong,
            height: _caoO,
            decoration: BoxDecoration(
              color: homNay ? AppColor.sky.withValues(alpha: .35) : Colors.transparent,
              borderRadius: BorderRadius.circular(R.sm),
              border: Border.all(color: AppColor.dongKe),
            ),
            child: const Center(
              child: Icon(Icons.add_rounded, size: 15, color: AppColor.dongKeDam),
            ),
          ),
        ),
      );
    }

    return Material(
      color: AppColor.giayTrang,
      borderRadius: BorderRadius.circular(R.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(R.sm),
        onTap: () => moSuaTietHoc(context, tietHoc: t),
        child: Ink(
          width: rong,
          height: _caoO,
          padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(R.sm),
            border: Border.all(
              color: homNay ? AppColor.muc.withValues(alpha: .4) : AppColor.dongKe,
              width: homNay ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.vietTatMon(t.monId),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.ui(13.5, w: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              if (t.giaoVienId != null)
                Text(
                  s.tenGv(t.giaoVienId)!.replaceFirst(RegExp(r'^(Thầy|Cô) '), ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.ui(10.5, color: AppColor.mucNhat, w: FontWeight.w500),
                ),
              const Spacer(),
              Text(
                t.batDau ?? t.phong ?? '',
                style: AppType.numeric(10, color: AppColor.mucNhat, w: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DongHocThem extends StatelessWidget {
  const _DongHocThem(this.t);
  final TietHoc t;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();

    return Material(
      color: AppColor.giayTrang,
      borderRadius: BorderRadius.circular(R.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(R.md),
        onTap: () => moSuaTietHoc(context, tietHoc: t),
        child: Ink(
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(color: AppColor.hocThem.withValues(alpha: .22)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColor.hocThemNhat,
                  borderRadius: BorderRadius.circular(R.sm),
                ),
                child: Text(
                  Ngay.thuNganTuCot(t.thu),
                  style: AppType.ui(14, w: FontWeight.w700, color: AppColor.hocThem),
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.tenMon(t.monId), style: AppType.ui(14.5, w: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      [s.tenGv(t.giaoVienId), t.phong].where((e) => e != null).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.ui(12, color: AppColor.mucNhat, w: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Gap.sm),
              Text(
                t.khungGio,
                style: AppType.numeric(12, color: AppColor.hocThem, w: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
