import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/ngay.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/trang_vo.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';

/// Một mục báo cáo hiện như một trang vở. Đường lề bên trái mang màu trạng thái,
/// nên chỉ liếc qua là biết bài nào còn dang dở.
class TheBaoCao extends StatelessWidget {
  const TheBaoCao(this.bc, {super.key, this.onTap, this.hienNgay = false});

  final BaoCao bc;
  final VoidCallback? onTap;
  final bool hienNgay;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final gv = s.tenGv(bc.giaoVienId);
    final bh = s.baiHocTheoId(bc.baiHocId);

    return TrangVo(
      mauLe: bc.trangThai.mau,
      vienNoiBat: bc.trangThai == TrangThai.chuaLam,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md + 2, Gap.md, Gap.md + 2),
      le: Icon(bc.trangThai.icon, size: 19, color: bc.trangThai.mau),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  s.tenMon(bc.monId),
                  style: AppType.ui(15.5, w: FontWeight.w700),
                ),
              ),
              const SizedBox(width: Gap.sm),
              Text(
                hienNgay ? Ngay.nhan(bc.ngay) : Ngay.gio(bc.taoLuc),
                style: AppType.ui(11.5, color: AppColor.mucNhat, w: FontWeight.w500),
              ),
            ],
          ),
          if (bh != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.menu_book_rounded, size: 13, color: AppColor.muc),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    bh.ten,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.ui(12.5, color: AppColor.muc, w: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 5),
          Row(
            children: [
              NhanLoai(bc.loai),
              if (gv != null) ...[
                const SizedBox(width: Gap.sm),
                Flexible(
                  child: Text(
                    gv,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.ui(12.5, color: AppColor.mucNhat, w: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
          // Ghi từ bảng điểm danh thì thường không có chữ — môn, bài và
          // đường lề đã nói hết; không chừa một khoảng trống ở đó.
          if (bc.noiDung.isNotEmpty) ...[
            const SizedBox(height: Gap.sm + 2),
            Text(
              bc.noiDung,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppType.ui(13.5, w: FontWeight.w400, height: 1.55, color: AppColor.ink),
            ),
          ],
          const SizedBox(height: Gap.md),
          Row(
            children: [
              NhanTrangThai(bc.trangThai, nhoGon: true),
              if (s.laNhap(bc.id)) ...[
                const SizedBox(width: Gap.sm),
                const _NhanChoMang(),
              ],
              const Spacer(),
              if (bc.soPhut != null) ...[
                const Icon(Icons.schedule_rounded, size: 13, color: AppColor.mucNhat),
                const SizedBox(width: 4),
                Text(
                  Ngay.phut(bc.soPhut!),
                  style: AppType.ui(11.5, color: AppColor.mucNhat, w: FontWeight.w500),
                ),
              ],
              if (bc.anh.isNotEmpty) ...[
                const SizedBox(width: Gap.md),
                const Icon(Icons.photo_camera_rounded, size: 13, color: AppColor.mucNhat),
                const SizedBox(width: 4),
                Text(
                  '${bc.anh.length}',
                  style: AppType.numeric(11.5, color: AppColor.mucNhat, w: FontWeight.w600),
                ),
              ],
              if (bc.nhanXetPhuHuynh != null) ...[
                const SizedBox(width: Gap.md),
                const Icon(Icons.chat_bubble_rounded, size: 12, color: AppColor.muc),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Bài viết lúc mất mạng, còn nằm trên máy. Nhãn hổ phách như "đang làm":
/// việc chưa xong, nhưng không phải lỗi của ai.
class _NhanChoMang extends StatelessWidget {
  const _NhanChoMang();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColor.dangLamNhat,
        borderRadius: BorderRadius.circular(R.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 11, color: AppColor.dangLam),
          const SizedBox(width: 4),
          Text('Chờ mạng',
              style: AppType.ui(10.5, w: FontWeight.w600, color: AppColor.dangLam)),
        ],
      ),
    );
  }
}
