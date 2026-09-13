import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';

/// Ô chọn bài học theo sách giáo khoa trên biểu mẫu báo cáo.
///
/// Chạm vào ô là mở bảng tìm bài; chưa chọn thì bên dưới có sẵn hai nút gợi
/// ý — bài hôm trước (lớp thường học một bài vài tiết) và bài kế tiếp — để
/// bấm một phát là xong, hiếm khi phải lục.
class ChonBaiHoc extends StatelessWidget {
  const ChonBaiHoc({
    super.key,
    required this.monId,
    required this.giaTri,
    required this.onChanged,
  });

  final String monId;
  final String? giaTri;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final bh = s.baiHocTheoId(giaTri);
    final homTruoc = bh == null ? s.baiDangHoc(monId) : null;
    final keTiep = s.baiSau(homTruoc);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(R.md),
          onTap: () async {
            final chon = await moChonBaiHoc(context, monId: monId, dangChon: giaTri);
            if (chon != null) onChanged(chon.isEmpty ? null : chon);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              suffixIcon: bh == null
                  ? const Icon(Icons.search_rounded, size: 20)
                  : IconButton(
                      tooltip: 'Bỏ chọn bài',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => onChanged(null),
                    ),
            ),
            child: bh == null
                ? Text(
                    'Chưa chọn — chạm để tìm bài',
                    style: AppType.ui(15, w: FontWeight.w500, color: AppColor.mucNhat),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bh.chuong != null)
                        Text(
                          bh.chuong!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.ui(11.5, color: AppColor.mucNhat, w: FontWeight.w500),
                        ),
                      Text(bh.ten, style: AppType.ui(15, w: FontWeight.w600)),
                    ],
                  ),
          ),
        ),
        if (homTruoc != null) ...[
          const SizedBox(height: Gap.sm),
          _NutGoiY(nhan: 'Hôm trước: ', bh: homTruoc, onTap: () => onChanged(homTruoc.id)),
        ],
        if (keTiep != null) ...[
          const SizedBox(height: Gap.sm),
          _NutGoiY(nhan: 'Bài tiếp: ', bh: keTiep, onTap: () => onChanged(keTiep.id)),
        ],
      ],
    );
  }
}

class _NutGoiY extends StatelessWidget {
  const _NutGoiY({required this.nhan, required this.bh, required this.onTap});
  final String nhan;
  final BaiHoc bh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(R.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm + 2),
        decoration: BoxDecoration(
          color: AppColor.skySoft,
          borderRadius: BorderRadius.circular(R.md),
          border: Border.all(color: AppColor.dongKe),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColor.muc),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: AppType.ui(13, w: FontWeight.w500, color: AppColor.ink),
                  children: [
                    TextSpan(
                      text: nhan,
                      style: const TextStyle(color: AppColor.mucNhat),
                    ),
                    TextSpan(text: bh.ten, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Gap.sm),
            Text('Chọn', style: AppType.ui(13, w: FontWeight.w700, color: AppColor.muc)),
          ],
        ),
      ),
    );
  }
}

/// Mở bảng tìm và chọn bài. Trả về id bài đã chọn, chuỗi rỗng khi người dùng
/// bấm "Không chọn bài nào", null khi đóng bảng mà không chọn gì.
Future<String?> moChonBaiHoc(
  BuildContext context, {
  required String monId,
  String? dangChon,
}) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppState>(),
        child: _BangChonBaiHoc(monId: monId, dangChon: dangChon),
      ),
    );

class _BangChonBaiHoc extends StatefulWidget {
  const _BangChonBaiHoc({required this.monId, this.dangChon});
  final String monId;
  final String? dangChon;

  @override
  State<_BangChonBaiHoc> createState() => _BangChonBaiHocState();
}

class _BangChonBaiHocState extends State<_BangChonBaiHoc> {
  final _tim = TextEditingController();

  @override
  void dispose() {
    _tim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tatCa = s.baiHocTheoMon(widget.monId);
    final homTruoc = s.baiDangHoc(widget.monId);
    final keTiep = s.baiSau(homTruoc);
    final ds = locBaiHoc(tatCa, _tim.text);

    // Nhóm theo chương, giữ thứ tự trong sách. Đang tìm thì bỏ tiêu đề
    // chương cho gọn — kết quả đã rải rác rồi.
    final dangTim = _tim.text.trim().isNotEmpty;
    final muc = <Widget>[];
    String? chuongTruoc;
    for (final b in ds) {
      if (!dangTim && b.chuong != chuongTruoc) {
        chuongTruoc = b.chuong;
        muc.add(_TieuDeChuong(b.chuong ?? 'Khác', hocKi: b.hocKi));
      }
      muc.add(_DongBai(
        bh: b,
        dangChon: b.id == widget.dangChon,
        nhan: b.id == homTruoc?.id
            ? 'Hôm trước'
            : b.id == keTiep?.id
                ? 'Kế tiếp'
                : null,
        onTap: () => Navigator.of(context).pop(b.id),
      ));
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: MediaQuery.sizeOf(context).height * .88,
        decoration: const BoxDecoration(
          color: AppColor.giayTrang,
          borderRadius: BorderRadius.vertical(top: Radius.circular(R.lg + 4)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
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
                child: TieuDeMuc(
                  'Chọn bài học',
                  eyebrow: '${s.tenMon(widget.monId)} · lớp ${s.khoiHienTai ?? '?'}',
                  hanhDong: widget.dangChon == null
                      ? null
                      : TextButton(
                          onPressed: () => Navigator.of(context).pop(''),
                          child: const Text('Bỏ chọn'),
                        ),
                ),
              ),
              const SizedBox(height: Gap.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                child: TextField(
                  controller: _tim,
                  autofocus: false,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên bài, chương… (vd: "bài 6", "phân số")',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: dangTim
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => setState(_tim.clear),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: Gap.sm),
              Expanded(
                child: tatCa.isEmpty
                    ? const TrangTrong(
                        icon: Icons.menu_book_outlined,
                        tieuDe: 'Chưa có danh mục cho môn này',
                        moTa: 'Khối lớp của em chưa được nạp bài học. Cứ viết báo cáo bình thường, không cần chọn bài.',
                      )
                    : ds.isEmpty
                        ? TrangTrong(
                            icon: Icons.search_off_rounded,
                            tieuDe: 'Không thấy bài nào',
                            moTa: 'Thử gõ ngắn hơn, ví dụ số bài hoặc một từ trong tên.',
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.xl),
                            children: muc,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lọc bài theo chuỗi gõ vào, không phân biệt hoa thường: mọi từ đều phải
/// có mặt trong tên bài hoặc tên chương. Riêng số thì phải là cả con số và
/// nằm trong tên bài — gõ "bài 6" ra Bài 6 chứ không lôi cả "Bài 23" của
/// chương 6 hay Bài 16 ra.
List<BaiHoc> locBaiHoc(List<BaiHoc> ds, String chuoi) {
  final tu = chuoi.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  if (tu.isEmpty) return ds;
  return ds.where((b) {
    final ten = b.ten.toLowerCase();
    final chuong = (b.chuong ?? '').toLowerCase();
    return tu.every((t) {
      if (int.tryParse(t) != null) {
        return RegExp('(^|[^0-9])$t([^0-9]|\$)').hasMatch(ten);
      }
      return ten.contains(t) || chuong.contains(t);
    });
  }).toList();
}

class _TieuDeChuong extends StatelessWidget {
  const _TieuDeChuong(this.chu, {this.hocKi});
  final String chu;
  final int? hocKi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, Gap.lg, 2, Gap.xs),
      child: Row(
        children: [
          Expanded(child: Eyebrow(chu)),
          if (hocKi != null) ...[
            const SizedBox(width: Gap.sm),
            Text('HK$hocKi', style: AppType.ui(10.5, w: FontWeight.w600, color: AppColor.mucNhat)),
          ],
        ],
      ),
    );
  }
}

class _DongBai extends StatelessWidget {
  const _DongBai({
    required this.bh,
    required this.dangChon,
    required this.nhan,
    required this.onTap,
  });

  final BaiHoc bh;
  final bool dangChon;

  /// Huy hiệu nhỏ bên phải: "Hôm trước" hay "Kế tiếp"; null là không có.
  final String? nhan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(R.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm + 2),
        decoration: BoxDecoration(
          color: dangChon ? AppColor.sky : null,
          borderRadius: BorderRadius.circular(R.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                bh.ten,
                style: AppType.ui(14.5, w: dangChon ? FontWeight.w700 : FontWeight.w500),
              ),
            ),
            if (nhan != null) ...[
              const SizedBox(width: Gap.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColor.skySoft,
                  borderRadius: BorderRadius.circular(R.sm),
                  border: Border.all(color: AppColor.dongKe),
                ),
                child: Text(nhan!,
                    style: AppType.ui(10.5, w: FontWeight.w600, color: AppColor.muc)),
              ),
            ],
            if (dangChon) ...[
              const SizedBox(width: Gap.sm),
              const Icon(Icons.check_rounded, size: 18, color: AppColor.muc),
            ],
          ],
        ),
      ),
    );
  }
}
