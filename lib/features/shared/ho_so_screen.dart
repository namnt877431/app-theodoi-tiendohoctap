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
import 'chon_truong_sheet.dart';
import 'sua_giao_vien_sheet.dart';

/// Trang tài khoản. Cùng một khung cho cả ba vai trò, chỉ khác phần thông tin
/// riêng: phụ huynh thấy danh sách con, học sinh thấy lớp và trường.
class HoSoScreen extends StatelessWidget {
  const HoSoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final nd = s.nguoiDung;
    if (nd == null) return const SizedBox.shrink();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(builder: (context, rang) {
          final le = BoCuc.leCanhGiua(rang.maxWidth, BoCuc.le(context), toiDa: 760);
          return ListView(
          padding: EdgeInsets.fromLTRB(le, Gap.md, le, Gap.xxl),
          children: [
            Text('Tài khoản', style: AppType.display(24)),
            const SizedBox(height: Gap.lg),
            Container(
              padding: const EdgeInsets.all(Gap.lg),
              decoration: BoxDecoration(
                color: AppColor.ink,
                borderRadius: BorderRadius.circular(R.lg),
              ),
              child: Row(
                children: [
                  AvatarChu(
                    nd.hoTen,
                    kichThuoc: 54,
                    mau: Colors.white,
                    mauNen: Colors.white.withValues(alpha: .14),
                  ),
                  const SizedBox(width: Gap.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nd.hoTen,
                            style: AppType.ui(17, w: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 3),
                        Text(
                          nd.vaiTro == VaiTro.hocSinh
                              ? 'Lớp ${nd.lop} · ${s.tenTruongCua(nd) ?? 'chưa chọn trường'}'
                              : nd.vaiTro.nhan,
                          style: AppType.ui(12.5,
                              color: Colors.white.withValues(alpha: .7), w: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.xl),
            TieuDeMuc('Thông tin', eyebrow: 'Hồ sơ'),
            const SizedBox(height: Gap.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.sm),
              decoration: BoxDecoration(
                color: AppColor.giayTrang,
                borderRadius: BorderRadius.circular(R.lg),
                border: Border.all(color: AppColor.dongKe),
              ),
              child: Column(
                children: [
                  DongThongTin(Icons.badge_outlined, 'Vai trò', nd.vaiTro.nhan),
                  if (nd.email != null) ...[
                    const Divider(),
                    DongThongTin(Icons.mail_outline_rounded, 'Email', nd.email!),
                  ],
                  if (nd.soDienThoai != null) ...[
                    const Divider(),
                    DongThongTin(
                        Icons.phone_outlined, 'Điện thoại', nd.soDienThoai!),
                  ],
                  if (nd.vaiTro == VaiTro.hocSinh) ...[
                    const Divider(),
                    DongThongTin(Icons.class_outlined, 'Lớp', nd.lop ?? '—'),
                    const Divider(),
                    // Chạm để đổi trường — tài khoản đăng ký trước khi có danh
                    // mục, hay chuyển trường, đều sửa được ở đây.
                    InkWell(
                      onTap: () => moChonTruong(context),
                      child: DongThongTin(
                        Icons.school_outlined,
                        'Trường',
                        s.tenTruongCua(nd) ?? 'Chạm để chọn',
                        mau: s.tenTruongCua(nd) == null ? AppColor.muc : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (nd.vaiTro == VaiTro.phuHuynh) ...[
              const SizedBox(height: Gap.xl),
              TieuDeMuc(
                'Con đang theo dõi',
                eyebrow: s.dsCon.isEmpty ? 'Chưa nối tài khoản nào' : '${s.dsCon.length} học sinh',
                hanhDong: TextButton.icon(
                  onPressed: () => moNhapMaMoi(context),
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text('Thêm con'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ),
              const SizedBox(height: Gap.md),
              if (s.dsCon.isEmpty)
                const LoiMoiNhapMa()
              else
                for (final con in s.dsCon)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.sm + 2),
                    child: _TheCon(con: con, dangChon: con.id == s.hocSinhHienTai?.id),
                  ),
            ],
            if (nd.vaiTro == VaiTro.hocSinh) ...[
              const SizedBox(height: Gap.xl),
              const TaoMaMoiThe(),
              const SizedBox(height: Gap.xl),
              const _GvRieng(),
              const SizedBox(height: Gap.xl),
              const _ThongKeHs(),
            ],
            const SizedBox(height: Gap.xl),
            OutlinedButton.icon(
              // AuthGate nghe trạng thái phiên nên đăng xuất xong màn hình tự
              // quay về đăng nhập — không cần điều hướng tay ở đây.
              onPressed: context.read<AppState>().dangXuat,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(s.dungThu ? 'Thoát chế độ xem thử' : 'Đăng xuất'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.butDo,
                side: BorderSide(color: AppColor.butDo.withValues(alpha: .35)),
              ),
            ),
            const SizedBox(height: Gap.lg),
            Center(
              child: Text('Sổ liên lạc · bản 0.3.0',
                  style: AppType.ui(11.5, color: AppColor.mucNhat, w: FontWeight.w400)),
            ),
          ],
        );
        }),
      ),
    );
  }
}

/// Thầy dạy thêm riêng của học sinh — chỉ nhà mình thấy, thêm bớt tùy ý mà
/// không phải nhờ quản trị.
class _GvRieng extends StatelessWidget {
  const _GvRieng();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final hs = s.hocSinhHienTai;
    if (hs == null) return const SizedBox.shrink();
    final ds = s.gvRiengCuaHs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TieuDeMuc(
          'Thầy cô dạy thêm',
          eyebrow: ds.isEmpty ? 'Chưa thêm ai' : '${ds.length} thầy cô',
          hanhDong: TextButton.icon(
            onPressed: () => moSuaGiaoVien(context, chuId: hs.id),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Thêm'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ),
        const SizedBox(height: Gap.md),
        if (ds.isEmpty)
          Container(
            padding: const EdgeInsets.all(Gap.md),
            decoration: BoxDecoration(
              color: AppColor.hocThemNhat,
              borderRadius: BorderRadius.circular(R.md),
            ),
            child: Text(
              'Thầy cô con học thêm ở ngoài chỉ nhà mình thấy. Thêm vào đây rồi chọn khi viết báo cáo học thêm.',
              style: AppType.ui(12.5, color: AppColor.hocThem, w: FontWeight.w500, height: 1.45),
            ),
          )
        else
          for (final g in ds)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.sm),
              child: Material(
                color: AppColor.giayTrang,
                borderRadius: BorderRadius.circular(R.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(R.md),
                  onTap: () => moSuaGiaoVien(context, giaoVien: g),
                  child: Ink(
                    padding: const EdgeInsets.all(Gap.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(R.md),
                      border: Border.all(color: AppColor.dongKe),
                    ),
                    child: Row(
                      children: [
                        AvatarChu(
                          g.hoTen.replaceFirst(RegExp(r'^(Thầy|Cô) '), ''),
                          kichThuoc: 38,
                          mau: AppColor.hocThem,
                          mauNen: AppColor.hocThemNhat,
                        ),
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.hoTen, style: AppType.ui(14, w: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                [s.tenMon(g.monId), g.noiDay].whereType<String>().join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.ui(11.5, color: AppColor.mucNhat, w: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: AppColor.dongKeDam),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _TheCon extends StatelessWidget {
  const _TheCon({required this.con, required this.dangChon});
  final NguoiDung con;
  final bool dangChon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.giayTrang,
      borderRadius: BorderRadius.circular(R.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(R.md),
        onTap: () => context.read<AppState>().chonCon(con),
        child: Ink(
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(
              color: dangChon ? AppColor.muc.withValues(alpha: .45) : AppColor.dongKe,
              width: dangChon ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              AvatarChu(con.hoTen, kichThuoc: 42),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(con.hoTen, style: AppType.ui(14.5, w: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Lớp ${con.lop} · ${context.read<AppState>().tenTruongCua(con) ?? '—'}',
                        style: AppType.ui(12, color: AppColor.mucNhat, w: FontWeight.w500)),
                  ],
                ),
              ),
              if (dangChon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColor.sky,
                    borderRadius: BorderRadius.circular(R.sm),
                  ),
                  child: Text('Đang xem',
                      style: AppType.ui(11, w: FontWeight.w700, color: AppColor.muc)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vài con số học sinh tự nhìn lại tuần vừa rồi.
class _ThongKeHs extends StatelessWidget {
  const _ThongKeHs();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final moc = Ngay.dauNgay(DateTime.now()).subtract(const Duration(days: 6));
    final tuan = s.baoCao.where((b) => !b.ngay.isBefore(moc)).toList();
    final xong = tuan.where((b) => b.trangThai == TrangThai.xong).length;
    final phut = tuan.fold(0, (t, b) => t + (b.soPhut ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TieuDeMuc('Bảy ngày qua', eyebrow: 'Tự nhìn lại'),
        const SizedBox(height: Gap.md),
        Row(
          children: [
            Expanded(child: OSoLieu(so: '${tuan.length}', nhan: 'Báo cáo', mau: AppColor.muc)),
            const SizedBox(width: Gap.sm),
            Expanded(child: OSoLieu(so: '$xong', nhan: 'Đã xong', mau: AppColor.xong)),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: OSoLieu(
                so: phut >= 60 ? '${(phut / 60).toStringAsFixed(1)}h' : '${phut}p',
                nhan: 'Thời gian học',
                mau: AppColor.hocThem,
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.md),
        if (s.chuoiNgayBaoCao >= 2)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Gap.md),
            decoration: BoxDecoration(
              color: AppColor.xongNhat,
              borderRadius: BorderRadius.circular(R.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    size: 18, color: AppColor.xong),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: Text(
                    '${s.chuoiNgayBaoCao} ngày liền có báo cáo. Giữ nhịp nhé.',
                    style: AppType.ui(13, w: FontWeight.w600, color: AppColor.xong),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
