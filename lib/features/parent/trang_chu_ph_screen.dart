import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/layout/bo_cuc.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/ngay.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';
import '../auth/ma_moi.dart';
import '../shared/chi_tiet_bao_cao_screen.dart';
import '../shared/phan_thuong.dart';
import '../shared/so_diem.dart';
import '../shared/the_bao_cao.dart';
import 'nhac_nho_screen.dart';
import 'soan_nhac_nho.dart';

/// Trang chủ phụ huynh trả lời đúng một câu hỏi: hôm nay con học thế nào?
class TrangChuPhScreen extends StatelessWidget {
  const TrangChuPhScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final hs = s.hocSinhHienTai;
    final homNay = Ngay.dauNgay(DateTime.now());
    final tk = s.tongKet(homNay);
    final dsHomNay = s.baoCaoNgay(homNay);

    final le = BoCuc.le(context);

    final dau = <Widget>[
      const _HeaderPh(),
      const SizedBox(height: Gap.lg),
      if (hs == null) ...[
        const SizedBox(height: Gap.xl),
        const LoiMoiNhapMa(),
      ],
      if (s.dsCon.length > 1) ...[
        _ChonCon(dsCon: s.dsCon, dangChon: hs),
        const SizedBox(height: Gap.lg),
      ],
    ];
    final baoCao = <Widget>[
      if (hs != null) ...[
        TieuDeMuc(
          'Báo cáo hôm nay',
          eyebrow: Ngay.dayDu(homNay),
          hanhDong: dsHomNay.isEmpty
              ? null
              : Text(
                  '${dsHomNay.length} mục',
                  style: AppType.ui(12.5, color: AppColor.mucNhat, w: FontWeight.w500),
                ),
        ),
        const SizedBox(height: Gap.md),
        if (dsHomNay.isEmpty)
          _ChuaCoBaoCao(tenCon: hs.tenGoi)
        else
          for (final loai in LoaiBaiTap.values)
            _NhomTheoLoai(
              loai: loai,
              ds: dsHomNay.where((b) => b.loai == loai).toList(),
            ),
      ],
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColor.muc,
          onRefresh: s.taiLai,
          child: ListView(
            padding: EdgeInsets.fromLTRB(le, Gap.md, le, Gap.xxl + Gap.xl),
            children: [
              NoiDung(
                child: hs == null
                    ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: dau)
                    // Màn rộng: trái là tình hình trong ngày (tóm tắt, tiết
                    // học), phải rộng hơn là báo cáo. Điện thoại đọc từ trên
                    // xuống.
                    : HaiCot(
                        tiLeTrai: 2,
                        tiLePhai: 3,
                        trai: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...dau,
                            _TomTatNgay(tongKet: tk, chuoi: s.chuoiNgayBaoCao),
                            const SizedBox(height: Gap.xl),
                            const KhungPhanThuong(),
                            const SizedBox(height: Gap.xl),
                            const KhungSoDiem(),
                            const SizedBox(height: Gap.xl),
                            const _TietHomNay(),
                          ],
                        ),
                        phai: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: Gap.xxl + Gap.lg),
                            ...baoCao,
                          ],
                        ),
                        hep: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...dau,
                            _TomTatNgay(tongKet: tk, chuoi: s.chuoiNgayBaoCao),
                            const SizedBox(height: Gap.xl),
                            const KhungPhanThuong(),
                            const SizedBox(height: Gap.xl),
                            const KhungSoDiem(),
                            const SizedBox(height: Gap.xl),
                            const _TietHomNay(),
                            const SizedBox(height: Gap.xl),
                            ...baoCao,
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderPh extends StatelessWidget {
  const _HeaderPh();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ph = s.nguoiDung;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(Ngay.dayDu(DateTime.now())),
              const SizedBox(height: 3),
              Text('Chào ${ph?.tenGoi ?? ''}', style: AppType.display(26)),
            ],
          ),
        ),
        NutO(
          icon: Icons.notifications_none_rounded,
          huyHieu: s.soNhacNhoChuaDoc,
          tooltip: 'Nhắc nhở đã gửi',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const NhacNhoScreen())),
        ),
      ],
    );
  }
}

class _ChonCon extends StatelessWidget {
  const _ChonCon({required this.dsCon, required this.dangChon});

  final List<NguoiDung> dsCon;
  final NguoiDung? dangChon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dsCon.length,
        separatorBuilder: (_, _) => const SizedBox(width: Gap.sm),
        itemBuilder: (_, i) {
          final con = dsCon[i];
          final chon = con.id == dangChon?.id;
          return Material(
            color: chon ? AppColor.ink : AppColor.giayTrang,
            borderRadius: BorderRadius.circular(R.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(R.md),
              onTap: () => context.read<AppState>().chonCon(con),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.md,
                  vertical: Gap.sm,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(R.md),
                  border: Border.all(
                    color: chon ? AppColor.ink : AppColor.dongKe,
                  ),
                ),
                child: Row(
                  children: [
                    AvatarChu(
                      con.hoTen,
                      kichThuoc: 34,
                      mau: chon ? Colors.white : AppColor.muc,
                      mauNen: chon
                          ? Colors.white.withValues(alpha: .14)
                          : AppColor.sky,
                    ),
                    const SizedBox(width: Gap.sm + 2),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          con.hoTen.split(' ').skip(1).join(' '),
                          style: AppType.ui(
                            13.5,
                            w: FontWeight.w600,
                            color: chon ? Colors.white : AppColor.ink,
                          ),
                        ),
                        Text(
                          'Lớp ${con.lop}',
                          style: AppType.ui(
                            11,
                            w: FontWeight.w500,
                            color: chon
                                ? Colors.white.withValues(alpha: .7)
                                : AppColor.mucNhat,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: Gap.xs),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Tổng kết trong ngày. Thay cho một con số phần trăm, mỗi bài tập là một vạch
/// riêng trên thanh ngang — giống nét gạch chấm bài — nên nhìn là biết còn
/// đúng mấy bài dang dở, không phải nhẩm lại từ tỉ lệ.
class _TomTatNgay extends StatelessWidget {
  const _TomTatNgay({required this.tongKet, required this.chuoi});

  final TongKetNgay tongKet;
  final int chuoi;

  String get _tieuDe {
    if (tongKet.tong == 0) return 'Hôm nay chưa có báo cáo';
    if (tongKet.chuaLam > 0) return 'Còn ${tongKet.chuaLam} bài chưa làm';
    if (tongKet.dangLam > 0) return '${tongKet.dangLam} bài đang làm dở';
    return 'Xong hết bài hôm nay rồi';
  }

  Color get _mauTieuDe {
    if (tongKet.tong == 0) return AppColor.mucNhat;
    if (tongKet.chuaLam > 0) return AppColor.butDo;
    if (tongKet.dangLam > 0) return AppColor.dangLam;
    return AppColor.xong;
  }

  @override
  Widget build(BuildContext context) {
    final vach = <TrangThai>[
      ...List.filled(tongKet.xong, TrangThai.xong),
      ...List.filled(tongKet.dangLam, TrangThai.dangLam),
      ...List.filled(tongKet.chuaLam, TrangThai.chuaLam),
    ];

    return Container(
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: AppColor.dongKe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Eyebrow('Tổng kết hôm nay')),
              if (chuoi >= 2)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gap.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.xongNhat,
                    borderRadius: BorderRadius.circular(R.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 13,
                        color: AppColor.xong,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$chuoi ngày báo cáo đều',
                        style: AppType.ui(
                          11.5,
                          w: FontWeight.w600,
                          color: AppColor.xong,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text(_tieuDe, style: AppType.display(23, color: _mauTieuDe)),
          const SizedBox(height: Gap.lg),
          if (vach.isEmpty)
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColor.sky,
                borderRadius: BorderRadius.circular(R.pill),
              ),
            )
          else
            Row(
              children: [
                for (var i = 0; i < vach.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 320 + i * 90),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, child) => Opacity(
                        opacity: v,
                        child: Transform.scale(scaleX: v, child: child),
                      ),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: vach[i].mau,
                          borderRadius: BorderRadius.circular(R.pill),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: Gap.md + 2),
          Row(
            children: [
              _ChiSo(TrangThai.xong, tongKet.xong),
              const SizedBox(width: Gap.lg),
              _ChiSo(TrangThai.dangLam, tongKet.dangLam),
              const SizedBox(width: Gap.lg),
              _ChiSo(TrangThai.chuaLam, tongKet.chuaLam),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Gap.md),
            child: Divider(),
          ),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: AppColor.mucNhat,
              ),
              const SizedBox(width: 6),
              Text(
                'Học ${Ngay.phut(tongKet.soPhut)}',
                style: AppType.ui(
                  13,
                  color: AppColor.mucNhat,
                  w: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => moSoanNhacNho(context),
                icon: const Icon(Icons.campaign_rounded, size: 17),
                label: const Text('Nhắc con'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.md),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChiSo extends StatelessWidget {
  const _ChiSo(this.tt, this.so);
  final TrangThai tt;
  final int so;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: tt.mau, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$so', style: AppType.numeric(15, w: FontWeight.w700)),
        const SizedBox(width: 4),
        Text(
          tt.nhan.toLowerCase(),
          style: AppType.ui(12, color: AppColor.mucNhat, w: FontWeight.w500),
        ),
      ],
    );
  }
}

/// Dải tiết học của hôm nay, cuộn ngang. Buổi học thêm mang màu riêng để
/// phụ huynh nhận ra ngay tối nay con có phải đi học không.
class _TietHomNay extends StatelessWidget {
  const _TietHomNay();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cot = Ngay.cotTuNgay(DateTime.now());
    final ds = s.tkbTheoThu(cot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TieuDeMuc('Tiết học hôm nay', eyebrow: 'Thời khóa biểu'),
        const SizedBox(height: Gap.md),
        if (ds.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: Gap.lg,
              horizontal: Gap.lg,
            ),
            decoration: BoxDecoration(
              color: AppColor.sky.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(R.md),
              border: Border.all(color: AppColor.dongKe),
            ),
            child: Text(
              'Hôm nay không có tiết nào trong thời khóa biểu.',
              style: AppType.ui(
                13,
                color: AppColor.mucNhat,
                w: FontWeight.w400,
              ),
            ),
          )
        else
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ds.length,
              separatorBuilder: (_, _) => const SizedBox(width: Gap.sm),
              itemBuilder: (_, i) => _OTiet(ds[i]),
            ),
          ),
      ],
    );
  }
}

class _OTiet extends StatelessWidget {
  const _OTiet(this.t);
  final TietHoc t;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final hocThem = t.loai == LoaiBaiTap.hocThem;

    return Container(
      width: 126,
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: hocThem ? LoaiBaiTap.hocThem.mauNen : AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(
          color: hocThem
              ? AppColor.hocThem.withValues(alpha: .22)
              : AppColor.dongKe,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hocThem ? AppColor.hocThem : AppColor.sky,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hocThem ? 'Học thêm' : 'Tiết ${t.tiet}',
                  style: AppType.ui(
                    9.5,
                    w: FontWeight.w700,
                    color: hocThem ? Colors.white : AppColor.muc,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            s.tenMon(t.monId),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.ui(14.5, w: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            t.khungGio.isEmpty ? (t.phong ?? '') : t.khungGio,
            style: AppType.numeric(
              11.5,
              color: AppColor.mucNhat,
              w: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nhóm báo cáo theo hạng mục. Bài học thêm còn gom tiếp theo từng thầy cô,
/// vì phụ huynh thường theo dõi theo người dạy chứ không theo môn.
class _NhomTheoLoai extends StatelessWidget {
  const _NhomTheoLoai({required this.loai, required this.ds});

  final LoaiBaiTap loai;
  final List<BaoCao> ds;

  @override
  Widget build(BuildContext context) {
    if (ds.isEmpty) return const SizedBox.shrink();
    final s = context.read<AppState>();

    final theoGv = <String?, List<BaoCao>>{};
    for (final b in ds) {
      theoGv
          .putIfAbsent(
            loai == LoaiBaiTap.hocThem ? b.giaoVienId : null,
            () => [],
          )
          .add(b);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NhanLoai(loai, dayDu: true),
              const SizedBox(width: Gap.sm),
              Expanded(child: Container(height: 1, color: AppColor.dongKe)),
              const SizedBox(width: Gap.sm),
              Text(
                '${ds.length}',
                style: AppType.numeric(
                  12.5,
                  color: AppColor.mucNhat,
                  w: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          for (final muc in theoGv.entries) ...[
            if (muc.key != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: Gap.sm),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      size: 13,
                      color: AppColor.hocThem,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      s.tenGv(muc.key) ?? '',
                      style: AppType.ui(
                        12.5,
                        w: FontWeight.w600,
                        color: AppColor.hocThem,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            for (final b in muc.value) ...[
              TheBaoCao(
                b,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChiTietBaoCaoScreen(baoCaoId: b.id),
                  ),
                ),
              ),
              const SizedBox(height: Gap.sm + 2),
            ],
          ],
        ],
      ),
    );
  }
}

class _ChuaCoBaoCao extends StatelessWidget {
  const _ChuaCoBaoCao({required this.tenCon});
  final String tenCon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Gap.xl),
      decoration: BoxDecoration(
        color: AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: AppColor.dongKe),
      ),
      child: TrangTrong(
        icon: Icons.edit_note_rounded,
        tieuDe: '$tenCon chưa gửi báo cáo nào hôm nay',
        moTa:
            'Báo cáo thường được gửi vào buổi tối, sau khi con làm xong bài. Gửi một lời nhắc nếu đã muộn.',
        hanhDong: FilledButton.icon(
          onPressed: () => moSoanNhacNho(context),
          icon: const Icon(Icons.campaign_rounded, size: 18),
          label: const Text('Nhắc con báo cáo'),
        ),
      ),
    );
  }
}
