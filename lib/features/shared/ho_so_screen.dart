import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/ngay.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';
import '../auth/chon_vai_tro.dart';

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xxl),
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
                              ? 'Lớp ${nd.lop} · ${nd.truong}'
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
                    DongThongTin(Icons.school_outlined, 'Trường', nd.truong ?? '—'),
                  ],
                ],
              ),
            ),
            if (nd.vaiTro == VaiTro.phuHuynh && s.dsCon.isNotEmpty) ...[
              const SizedBox(height: Gap.xl),
              TieuDeMuc('Con đang theo dõi', eyebrow: '${s.dsCon.length} học sinh'),
              const SizedBox(height: Gap.md),
              for (final con in s.dsCon)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.sm + 2),
                  child: _TheCon(con: con, dangChon: con.id == s.hocSinhHienTai?.id),
                ),
            ],
            if (nd.vaiTro == VaiTro.hocSinh) ...[
              const SizedBox(height: Gap.xl),
              _ThongKeHs(),
            ],
            const SizedBox(height: Gap.xl),
            OutlinedButton.icon(
              onPressed: () {
                context.read<AppState>().dangXuat();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const ChonVaiTroScreen()),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Đăng xuất'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.butDo,
                side: BorderSide(color: AppColor.butDo.withValues(alpha: .35)),
              ),
            ),
            const SizedBox(height: Gap.lg),
            Center(
              child: Text('Sổ liên lạc · bản 0.1.0',
                  style: AppType.ui(11.5, color: AppColor.mucNhat, w: FontWeight.w400)),
            ),
          ],
        ),
      ),
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
                    Text('Lớp ${con.lop} · ${con.truong}',
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
        if (s.chuoiNgayTron >= 2)
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
                    '${s.chuoiNgayTron} ngày liền làm hết bài. Giữ nhịp nhé.',
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
