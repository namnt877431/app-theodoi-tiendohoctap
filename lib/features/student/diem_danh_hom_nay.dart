import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/diem_danh.dart';
import '../../data/models/models.dart';
import '../shared/chon_bai_hoc.dart';
import '../shared/soan_bao_cao_screen.dart';

/// Bảng điểm danh: mỗi môn có tiết hôm nay mà chưa báo cáo là một dòng — môn,
/// thầy cô điền sẵn từ thời khóa biểu, bài điền sẵn là bài của lần báo cáo
/// trước (lớp thường học một bài vài tiết). Em chỉ còn trả lời hai câu app
/// không tự biết: đã sang bài mới chưa ("Bài tiếp ›"), và làm tới đâu rồi.
/// Một chạm xong một môn, cả ngày năm chạm.
///
/// Không có trạng thái chọn sẵn. Em phải tự bấm cho từng môn, để "Đã xong" là
/// câu trả lời chứ không phải cái có sẵn. Cần ghi chữ hay chụp ảnh thì cây
/// bút mở biểu mẫu đầy đủ, cũng đã điền sẵn.
class DiemDanhHomNay extends StatefulWidget {
  const DiemDanhHomNay({super.key, required this.ds});

  final List<MucDiemDanh> ds;

  @override
  State<DiemDanhHomNay> createState() => _DiemDanhHomNayState();
}

class _DiemDanhHomNayState extends State<DiemDanhHomNay> {
  /// Bài em tự đổi cho một môn, thay cho bài hôm trước; giá trị null là em
  /// đã bỏ chọn. Không có trong bảng thì dùng bài của dòng.
  final _baiDaChon = <(String, LoaiBaiTap), String?>{};
  final _dangLuu = <(String, LoaiBaiTap)>{};

  String? _baiCua(MucDiemDanh m) =>
      _baiDaChon.containsKey(m.khoa) ? _baiDaChon[m.khoa] : m.baiHoc?.id;

  Future<void> _doiBai(MucDiemDanh m) async {
    final chon = await moChonBaiHoc(context, monId: m.monId, dangChon: _baiCua(m));
    if (chon == null || !mounted) return;
    setState(() => _baiDaChon[m.khoa] = chon.isEmpty ? null : chon);
  }

  /// "Bài tiếp ›": lớp đã sang bài mới — nhảy bài đang chọn lên một bài.
  void _sangBaiTiep(MucDiemDanh m, BaiHoc tiep) =>
      setState(() => _baiDaChon[m.khoa] = tiep.id);

  void _ghiThem(MucDiemDanh m) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SoanBaoCaoScreen(muc: m, baiHocId: _baiCua(m)),
      ),
    );
  }

  Future<void> _ghi(MucDiemDanh m, TrangThai tt, {String noiDung = ''}) async {
    setState(() => _dangLuu.add(m.khoa));
    final s = context.read<AppState>();
    final tb = ScaffoldMessenger.of(context);
    final dieuHuong = Navigator.of(context);
    try {
      final (bc, ketQua) =
          await s.diemDanh(m, tt, baiHocId: _baiCua(m), noiDung: noiDung);
      tb.showSnackBar(SnackBar(
        duration: Duration(seconds: ketQua == KetQuaLuu.choMang ? 5 : 4),
        content: Text(switch (ketQua) {
          KetQuaLuu.choMang => 'Chưa có mạng — đã cất trên máy, sẽ tự gửi khi có mạng.',
          KetQuaLuu.daGui => '${s.tenMon(m.monId)} · ${tt.nhan} — đã gửi cho bố mẹ',
        }),
        action: SnackBarAction(
          label: 'Sửa',
          onPressed: () => dieuHuong.push(
            MaterialPageRoute(builder: (_) => SoanBaoCaoScreen(baoCao: bc)),
          ),
        ),
      ));
    } catch (e) {
      tb.showSnackBar(SnackBar(content: Text('Không lưu được: $e')));
    } finally {
      if (mounted) setState(() => _dangLuu.remove(m.khoa));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Container(
      decoration: BoxDecoration(
        color: AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: AppColor.dongKe),
      ),
      child: Column(
        children: [
          for (var i = 0; i < widget.ds.length; i++) ...[
            if (i > 0) const Divider(indent: Gap.lg, endIndent: Gap.lg),
            () {
              final m = widget.ds[i];
              final bai = s.baiHocTheoId(_baiCua(m));
              final tiep = s.baiSau(bai);
              return _Dong(
                muc: m,
                baiHoc: bai,
                baiTiep: tiep,
                coDanhMuc: s.baiHocTheoMon(m.monId).isNotEmpty,
                dangLuu: _dangLuu.contains(m.khoa),
                onDoiBai: () => _doiBai(m),
                onBaiTiep: tiep == null ? null : () => _sangBaiTiep(m, tiep),
                onGhiThem: () => _ghiThem(m),
                onChon: (tt) => _ghi(m, tt),
                onKhongCoBai: () => _ghi(m, TrangThai.xong, noiDung: noiDungKhongCoBai),
              );
            }(),
          ],
        ],
      ),
    );
  }
}

class _Dong extends StatelessWidget {
  const _Dong({
    required this.muc,
    required this.baiHoc,
    required this.baiTiep,
    required this.coDanhMuc,
    required this.dangLuu,
    required this.onDoiBai,
    required this.onBaiTiep,
    required this.onGhiThem,
    required this.onChon,
    required this.onKhongCoBai,
  });

  final MucDiemDanh muc;

  /// Bài đang chọn cho dòng này và bài đứng sau nó trong sách.
  final BaiHoc? baiHoc;
  final BaiHoc? baiTiep;
  final bool coDanhMuc;
  final bool dangLuu;
  final VoidCallback onDoiBai;
  final VoidCallback? onBaiTiep;
  final VoidCallback onGhiThem;
  final ValueChanged<TrangThai> onChon;
  final VoidCallback onKhongCoBai;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final gv = s.tenGv(muc.giaoVienId);
    final hocThem = muc.loai == LoaiBaiTap.hocThem;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.lg, Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dòng đầu: số tiết bên lề, tên môn kèm thầy cô, và cây bút mở
          // biểu mẫu đầy đủ khi cần ghi chữ hay chụp ảnh.
          Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  hocThem ? 'HT' : '${muc.tiet}',
                  style: AppType.numeric(14,
                      w: FontWeight.w700, color: hocThem ? AppColor.hocThem : AppColor.muc),
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: s.tenMon(muc.monId),
                    style: AppType.ui(15, w: FontWeight.w700),
                    children: [
                      if (gv != null)
                        TextSpan(
                          text: '   $gv',
                          style: AppType.ui(12.5, color: AppColor.mucNhat, w: FontWeight.w500),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: dangLuu ? null : onGhiThem,
                tooltip: 'Ghi thêm chữ, ảnh',
                icon: const Icon(Icons.edit_note_rounded, size: 22, color: AppColor.muc),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          // Dòng bài: chạm vào tên là mở bảng chọn; "Bài tiếp ›" bên phải
          // nhảy lên một bài khi lớp đã sang bài mới. Môn không có danh mục
          // thì không có dòng này.
          if (coDanhMuc)
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: dangLuu ? null : onDoiBai,
                      borderRadius: BorderRadius.circular(R.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 13, color: AppColor.muc),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                baiHoc?.ten ?? 'Chọn bài trong sách',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.ui(12.5,
                                    color: baiHoc == null ? AppColor.mucNhat : AppColor.muc,
                                    w: FontWeight.w600),
                              ),
                            ),
                            const Icon(Icons.expand_more_rounded,
                                size: 16, color: AppColor.mucNhat),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (onBaiTiep != null) ...[
                    const SizedBox(width: Gap.sm),
                    _NutBaiTiep(onTap: dangLuu ? null : onBaiTiep),
                  ],
                ],
              ),
            ),
          const SizedBox(height: Gap.sm),
          // Ô "Không có bài" rộng hơn ba ô kia một chút cho nhãn nằm trọn
          // một dòng trên máy hẹp; IntrinsicHeight giữ bốn ô cùng chiều cao.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final tt in TrangThai.values) ...[
                  Expanded(
                    flex: 3,
                    child: OChon(
                      icon: tt.icon,
                      nhan: tt.nhan,
                      mau: tt.mau,
                      mauNen: tt.mauNen,
                      iconCoMau: true,
                      onTap: dangLuu ? null : () => onChon(tt),
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                ],
                Expanded(
                  flex: 4,
                  child: OChon(
                    icon: Icons.do_not_disturb_on_outlined,
                    nhan: 'Không có bài',
                    mau: AppColor.mucNhat,
                    mauNen: AppColor.sky,
                    iconCoMau: true,
                    onTap: dangLuu ? null : onKhongCoBai,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút nhỏ "Bài tiếp ›" — câu trả lời một chạm cho "hôm nay cô sang bài mới
/// rồi hả?". Viền mảnh, không tô nền, để không tranh với bốn ô trạng thái.
class _NutBaiTiep extends StatelessWidget {
  const _NutBaiTiep({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(R.sm),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(Gap.sm + 2, 4, Gap.sm - 2, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(R.sm),
            border: Border.all(color: AppColor.dongKe),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bài tiếp',
                  style: AppType.ui(11.5, w: FontWeight.w600, color: AppColor.muc)),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColor.muc),
            ],
          ),
        ),
      ),
    );
  }
}
