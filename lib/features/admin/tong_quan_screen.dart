import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/layout/bo_cuc.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/ngay.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/trang_vo.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';

/// Tổng quan hệ thống. Số liệu bám vào việc quản trị viên thật sự phải xử lý:
/// tài khoản nào chưa liên kết phụ huynh, tài khoản nào đang bị khóa.
class TongQuanScreen extends StatefulWidget {
  const TongQuanScreen({super.key});

  @override
  State<TongQuanScreen> createState() => _TongQuanScreenState();
}

class _TongQuanScreenState extends State<TongQuanScreen> {
  List<NguoiDung> _ds = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tai());
  }

  Future<void> _tai() async {
    final ds = await context.read<AppState>().repo.danhSachNguoiDung();
    if (mounted) setState(() => _ds = ds);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final hocSinh = _ds.where((n) => n.vaiTro == VaiTro.hocSinh).toList();
    final phuHuynh = _ds.where((n) => n.vaiTro == VaiTro.phuHuynh).toList();
    final daLienKet = phuHuynh.expand((p) => p.conIds).toSet();
    final chuaLienKet = hocSinh.where((h) => !daLienKet.contains(h.id)).toList();
    final biKhoa = _ds.where((n) => !n.hoatDong).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColor.muc,
          onRefresh: _tai,
          child: LayoutBuilder(builder: (context, rang) {
            final le = BoCuc.leCanhGiua(rang.maxWidth, BoCuc.le(context), toiDa: 1000);
            return ListView(
            padding: EdgeInsets.fromLTRB(le, Gap.md, le, Gap.xxl),
            children: [
              Eyebrow(Ngay.dayDu(DateTime.now())),
              const SizedBox(height: 3),
              Text('Tổng quan hệ thống', style: AppType.display(26)),
              const SizedBox(height: Gap.xl),
              // Sáu ô số liệu: một hàng khi rộng, hai hàng ba ô khi hẹp.
              LayoutBuilder(builder: (context, rang) {
                final o = [
                  OSoLieu(so: '${hocSinh.length}', nhan: 'Học sinh', mau: AppColor.muc),
                  OSoLieu(so: '${phuHuynh.length}', nhan: 'Phụ huynh', mau: AppColor.hocThem),
                  OSoLieu(so: '${s.giaoVien.length}', nhan: 'Thầy cô', mau: AppColor.xong),
                  OSoLieu(so: '${s.truong.length}', nhan: 'Trường', mau: AppColor.mucNhat),
                  OSoLieu(so: '${chuaLienKet.length}', nhan: 'Chưa liên kết', mau: AppColor.dangLam),
                  OSoLieu(so: '${biKhoa.length}', nhan: 'Đã khóa', mau: AppColor.butDo),
                ];
                final moiHang = rang.maxWidth >= 720 ? 6 : 3;
                return Column(
                  children: [
                    for (var i = 0; i < o.length; i += moiHang) ...[
                      if (i > 0) const SizedBox(height: Gap.sm),
                      Row(
                        children: [
                          for (var j = i; j < i + moiHang && j < o.length; j++) ...[
                            if (j > i) const SizedBox(width: Gap.sm),
                            Expanded(child: o[j]),
                          ],
                        ],
                      ),
                    ],
                  ],
                );
              }),
              const SizedBox(height: Gap.xl),
              TieuDeMuc(
                'Cần xử lý',
                eyebrow: chuaLienKet.isEmpty && biKhoa.isEmpty
                    ? 'Không còn việc tồn'
                    : '${chuaLienKet.length + biKhoa.length} mục',
              ),
              const SizedBox(height: Gap.md),
              if (chuaLienKet.isEmpty && biKhoa.isEmpty)
                Container(
                  padding: const EdgeInsets.all(Gap.lg),
                  decoration: BoxDecoration(
                    color: AppColor.xongNhat,
                    borderRadius: BorderRadius.circular(R.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 18, color: AppColor.xong),
                      const SizedBox(width: Gap.sm),
                      Expanded(
                        child: Text('Mọi tài khoản đều đã liên kết và đang hoạt động.',
                            style: AppType.ui(13, w: FontWeight.w600, color: AppColor.xong)),
                      ),
                    ],
                  ),
                ),
              for (final h in chuaLienKet) ...[
                _DongViec(
                  mau: AppColor.dangLam,
                  icon: Icons.link_off_rounded,
                  tieuDe: h.hoTen,
                  moTa: 'Học sinh lớp ${h.lop} chưa có phụ huynh nào theo dõi',
                ),
                const SizedBox(height: Gap.sm + 2),
              ],
              for (final n in biKhoa) ...[
                _DongViec(
                  mau: AppColor.butDo,
                  icon: Icons.lock_outline_rounded,
                  tieuDe: n.hoTen,
                  moTa: 'Tài khoản ${n.vaiTro.nhan.toLowerCase()} đang bị khóa',
                ),
                const SizedBox(height: Gap.sm + 2),
              ],
            ],
          );
          }),
        ),
      ),
    );
  }
}

class _DongViec extends StatelessWidget {
  const _DongViec({
    required this.mau,
    required this.icon,
    required this.tieuDe,
    required this.moTa,
  });

  final Color mau;
  final IconData icon;
  final String tieuDe;
  final String moTa;

  @override
  Widget build(BuildContext context) {
    return TrangVo(
      mauLe: mau,
      keNgang: false,
      le: Icon(icon, size: 18, color: mau),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tieuDe, style: AppType.ui(14.5, w: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(moTa,
              style: AppType.ui(12.5,
                  color: AppColor.mucNhat, w: FontWeight.w400, height: 1.45)),
        ],
      ),
    );
  }
}
