import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';
import 'sua_giao_vien_sheet.dart';

/// Ô chọn thầy cô dùng chung cho biểu mẫu báo cáo và tiết học.
///
/// Danh sách đã được lọc theo trường của học sinh (trên lớp) hoặc theo tỉnh
/// cộng thầy riêng (học thêm). Với học thêm có thêm dòng cuối "Thêm thầy cô
/// dạy thêm…" — thầy dạy thêm là chuyện riêng từng nhà, không phải nhờ quản
/// trị nhập hộ; thêm xong là chọn luôn.
class ChonGiaoVien extends StatelessWidget {
  const ChonGiaoVien({
    super.key,
    required this.loai,
    required this.giaTri,
    required this.dsGv,
    required this.onChanged,
    this.monId,
  });

  final LoaiBaiTap loai;
  final String? giaTri;
  final List<GiaoVien> dsGv;
  final ValueChanged<String?> onChanged;

  /// Môn đang chọn trên biểu mẫu, để điền sẵn khi thêm thầy mới.
  final String? monId;

  static const _them = '__them__';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final coTheThem = loai == LoaiBaiTap.hocThem && s.hocSinhHienTai != null;
    // Giá trị không còn trong danh sách (đổi hạng mục, hay thầy vừa bị xóa)
    // thì về "Chưa chọn" chứ không giữ một id lơ lửng.
    final hienTai = dsGv.any((g) => g.id == giaTri) ? giaTri : null;

    return DropdownButtonFormField<String?>(
      // Khóa theo giá trị: ô này giữ trạng thái riêng, đổi initialValue từ
      // ngoài không tự cập nhật — cần dựng lại khi vừa thêm thầy mới.
      key: ValueKey('gv-${loai.name}-$hienTai-${dsGv.length}'),
      initialValue: hienTai,
      isExpanded: true,
      style: AppType.ui(15, w: FontWeight.w500),
      hint: const Text('Chưa chọn'),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Chưa chọn')),
        for (final g in dsGv)
          DropdownMenuItem<String?>(
            value: g.id,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '${g.hoTen} · ${s.vietTatMon(g.monId)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (g.laRieng) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.home_outlined, size: 14, color: AppColor.mucNhat),
                ],
              ],
            ),
          ),
        if (coTheThem)
          DropdownMenuItem<String?>(
            value: _them,
            child: Row(
              children: [
                const Icon(Icons.add_rounded, size: 18, color: AppColor.muc),
                const SizedBox(width: 6),
                Text(
                  'Thêm thầy cô dạy thêm…',
                  style: AppType.ui(15, w: FontWeight.w600, color: AppColor.muc),
                ),
              ],
            ),
          ),
      ],
      onChanged: (v) async {
        if (v != _them) {
          onChanged(v);
          return;
        }
        final id = await moSuaGiaoVien(
          context,
          chuId: s.hocSinhHienTai!.id,
          loaiMacDinh: LoaiBaiTap.hocThem,
          monMacDinh: monId,
        );
        // Đóng mà không lưu thì giữ nguyên lựa chọn cũ.
        onChanged(id ?? hienTai);
      },
    );
  }
}
