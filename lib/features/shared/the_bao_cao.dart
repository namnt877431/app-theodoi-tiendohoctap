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
          const SizedBox(height: Gap.sm + 2),
          Text(
            bc.noiDung,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppType.ui(13.5, w: FontWeight.w400, height: 1.55, color: AppColor.ink),
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              NhanTrangThai(bc.trangThai, nhoGon: true),
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
