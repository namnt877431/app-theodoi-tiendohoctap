import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Nhãn nhỏ in hoa đặt trên tiêu đề mục — phân tầng bằng chữ, không bằng đổ bóng.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.chu, {super.key, this.mau});
  final String chu;
  final Color? mau;

  @override
  Widget build(BuildContext context) =>
      Text(chu.toUpperCase(), style: AppType.eyebrow(color: mau));
}

/// Tiêu đề một mục, kèm hành động phụ bên phải.
class TieuDeMuc extends StatelessWidget {
  const TieuDeMuc(this.chu, {super.key, this.eyebrow, this.hanhDong});
  final String chu;
  final String? eyebrow;
  final Widget? hanhDong;

  @override
  Widget build(BuildContext context) {
    final eb = eyebrow;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eb != null) ...[
                Eyebrow(eb),
                const SizedBox(height: 3),
              ],
              Text(chu, style: AppType.ui(17, w: FontWeight.w700)),
            ],
          ),
        ),
        ?hanhDong,
      ],
    );
  }
}

/// Huy hiệu trạng thái: chấm màu cộng chữ, nền rất nhạt.
class NhanTrangThai extends StatelessWidget {
  const NhanTrangThai(this.trangThai, {super.key, this.nhoGon = false});
  final TrangThai trangThai;
  final bool nhoGon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: nhoGon ? 7 : Gap.sm + 2, vertical: nhoGon ? 3 : 5),
      decoration: BoxDecoration(
        color: trangThai.mauNen,
        borderRadius: BorderRadius.circular(R.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trangThai.icon, size: nhoGon ? 11 : 13, color: trangThai.mau),
          const SizedBox(width: 5),
          Text(
            trangThai.nhan,
            style: AppType.ui(nhoGon ? 10.5 : 12, w: FontWeight.w600, color: trangThai.mau),
          ),
        ],
      ),
    );
  }
}

/// Huy hiệu phân biệt bài trên lớp với bài học thêm.
class NhanLoai extends StatelessWidget {
  const NhanLoai(this.loai, {super.key, this.dayDu = false});
  final LoaiBaiTap loai;
  final bool dayDu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm + 2, vertical: 5),
      decoration: BoxDecoration(
        color: loai.mauNen,
        borderRadius: BorderRadius.circular(R.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            loai == LoaiBaiTap.trenLop ? Icons.school_rounded : Icons.auto_stories_rounded,
            size: 13,
            color: loai.mau,
          ),
          const SizedBox(width: 5),
          Text(
            dayDu ? loai.nhan : loai.nhanNgan,
            style: AppType.ui(12, w: FontWeight.w600, color: loai.mau),
          ),
        ],
      ),
    );
  }
}

/// Ảnh đại diện bằng chữ cái đầu — không phải tải ảnh, luôn có mặt.
class AvatarChu extends StatelessWidget {
  const AvatarChu(this.hoTen, {super.key, this.kichThuoc = 40, this.mau, this.mauNen});
  final String hoTen;
  final double kichThuoc;
  final Color? mau;
  final Color? mauNen;

  static String chuDau(String hoTen) {
    final phan = hoTen.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (phan.isEmpty) return '?';
    if (phan.length == 1) return phan.first.substring(0, 1).toUpperCase();
    return (phan.first.substring(0, 1) + phan.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kichThuoc,
      height: kichThuoc,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: mauNen ?? AppColor.sky,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: (mau ?? AppColor.muc).withValues(alpha: .18)),
      ),
      child: Text(
        chuDau(hoTen),
        style: AppType.ui(kichThuoc * .36, w: FontWeight.w700, color: mau ?? AppColor.muc),
      ),
    );
  }
}

/// Thanh tiến độ mảnh cho tỉ lệ hoàn thành trong ngày.
class ThanhTienDo extends StatelessWidget {
  const ThanhTienDo(this.tiLe, {super.key, this.mau = AppColor.xong, this.cao = 6});
  final double tiLe;
  final Color mau;
  final double cao;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(R.pill),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: tiLe.clamp(0, 1)),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: cao,
          backgroundColor: AppColor.sky,
          valueColor: AlwaysStoppedAnimation(mau),
        ),
      ),
    );
  }
}

/// Màn hình rỗng là lời mời làm việc, không phải câu xin lỗi.
class TrangTrong extends StatelessWidget {
  const TrangTrong({
    super.key,
    required this.icon,
    required this.tieuDe,
    required this.moTa,
    this.hanhDong,
  });

  final IconData icon;
  final String tieuDe;
  final String moTa;
  final Widget? hanhDong;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.xl, vertical: Gap.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColor.sky,
                borderRadius: BorderRadius.circular(R.lg + 4),
              ),
              child: Icon(icon, size: 30, color: AppColor.muc.withValues(alpha: .7)),
            ),
            const SizedBox(height: Gap.lg),
            Text(tieuDe, style: AppType.ui(16, w: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: Gap.sm),
            Text(
              moTa,
              style: AppType.ui(13.5, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (hanhDong != null) ...[const SizedBox(height: Gap.xl), hanhDong!],
          ],
        ),
      ),
    );
  }
}

/// Ô số liệu nhỏ dùng trên trang tổng quan.
class OSoLieu extends StatelessWidget {
  const OSoLieu({super.key, required this.so, required this.nhan, required this.mau});
  final String so;
  final String nhan;
  final Color mau;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.md),
      decoration: BoxDecoration(
        color: AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: AppColor.dongKe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: mau, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(so, style: AppType.numeric(21, w: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 3),
          Text(nhan, style: AppType.ui(11.5, color: AppColor.mucNhat, w: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Nút vuông nhỏ trên thanh tiêu đề, có thể gắn huy hiệu đếm.
class NutO extends StatelessWidget {
  const NutO({super.key, required this.icon, this.onTap, this.huyHieu = 0, this.tooltip});
  final IconData icon;
  final VoidCallback? onTap;
  final int huyHieu;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final nut = Material(
      color: AppColor.giayTrang,
      borderRadius: BorderRadius.circular(R.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(R.md),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(color: AppColor.dongKe),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 20, color: AppColor.ink),
              if (huyHieu > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColor.butDo,
                      borderRadius: BorderRadius.circular(R.pill),
                      border: Border.all(color: AppColor.giayTrang, width: 1.5),
                    ),
                    child: Text(
                      huyHieu > 9 ? '9+' : '$huyHieu',
                      textAlign: TextAlign.center,
                      style: AppType.numeric(9, w: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? nut : Tooltip(message: tooltip!, child: nut);
  }
}

/// Hàng thông tin nhỏ: biểu tượng mờ, nhãn, giá trị.
class DongThongTin extends StatelessWidget {
  const DongThongTin(this.icon, this.nhan, this.giaTri, {super.key, this.mau});
  final IconData icon;
  final String nhan;
  final String giaTri;
  final Color? mau;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        // Nhãn đi cùng dòng đầu của giá trị. Tên trường dài hai dòng mà căn
        // giữa thì nhãn tụt xuống giữa hai dòng, nhìn như lệch hàng so với các
        // dòng phía trên.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 13.5 × 1.4 = 18.9 là chiều cao hộp dòng; đẩy biểu tượng 16px xuống
          // một nửa phần dôi ra để nó ngang tâm chữ chứ không ngang đỉnh chữ.
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Icon(icon, size: 16, color: mau ?? AppColor.mucNhat),
          ),
          const SizedBox(width: Gap.md),
          Text(nhan, style: AppType.ui(13.5, color: AppColor.mucNhat, w: FontWeight.w400)),
          const SizedBox(width: Gap.md),
          // Expanded chứ không phải Spacer + Flexible: hai cái đó cùng flex 1
          // nên chia đôi chỗ trống, giá trị chỉ được nửa bề ngang và xuống dòng
          // sớm dù còn thừa chỗ.
          Expanded(
            child: Text(
              giaTri,
              textAlign: TextAlign.right,
              style: AppType.ui(13.5, w: FontWeight.w600, color: mau),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nhãn nhỏ đặt trên một ô nhập trong biểu mẫu.
class NhanO extends StatelessWidget {
  const NhanO(this.chu, {super.key});
  final String chu;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Gap.sm, left: 2),
        child: Eyebrow(chu),
      );
}

/// Khung chung cho các bảng thêm/sửa mở từ dưới lên: tay nắm, tiêu đề, phần
/// thân cuộn được, và hàng nút Lưu (kèm Xóa khi đang sửa bản ghi cũ).
///
/// Tự đẩy lên khi bàn phím hiện, để ô đang gõ không bị che.
class KhungBieuMau extends StatelessWidget {
  const KhungBieuMau({
    super.key,
    required this.tieuDe,
    required this.children,
    required this.onLuu,
    this.eyebrow,
    this.nhanLuu = 'Lưu',
    this.onXoa,
    this.dangLuu = false,
  });

  final String tieuDe;
  final String? eyebrow;
  final List<Widget> children;
  final VoidCallback? onLuu;
  final VoidCallback? onXoa;
  final String nhanLuu;
  final bool dangLuu;

  @override
  Widget build(BuildContext context) {
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
                child: TieuDeMuc(tieuDe, eyebrow: eyebrow),
              ),
              const SizedBox(height: Gap.lg),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
                  children: [
                    ...children,
                    const SizedBox(height: Gap.xl),
                    Row(
                      children: [
                        if (onXoa != null) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: dangLuu ? null : onXoa,
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
                            onPressed: dangLuu ? null : onLuu,
                            child: Text(dangLuu ? 'Đang lưu…' : nhanLuu),
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

/// Hỏi lại trước khi xóa. Trả về true khi người dùng xác nhận.
Future<bool> hoiXoa(BuildContext context, String viec, {String? giaiThich}) async {
  final dongY = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(viec, style: AppType.ui(16, w: FontWeight.w700)),
      content: giaiThich == null
          ? null
          : Text(giaiThich, style: AppType.ui(13.5, w: FontWeight.w400, height: 1.45)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Thôi'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColor.butDo),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  return dongY ?? false;
}
