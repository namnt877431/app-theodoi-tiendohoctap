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
import '../shared/chi_tiet_bao_cao_screen.dart';
import '../shared/phan_thuong.dart';
import '../shared/soan_bao_cao_screen.dart';
import '../shared/the_bao_cao.dart';
import 'diem_danh_hom_nay.dart';
import 'huy_hieu_section.dart';

/// Trang chủ học sinh mở ra là thấy hai thứ: bố mẹ đang nhắc gì, và hôm nay
/// còn môn nào chưa điểm danh — mỗi môn trong thời khóa biểu là một dòng,
/// bấm một cái là xong một báo cáo.
class TrangChuHsScreen extends StatelessWidget {
  const TrangChuHsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final hs = s.hocSinhHienTai;
    final homNay = Ngay.dauNgay(DateTime.now());
    final ds = s.baoCaoNgay(homNay);
    final tk = s.tongKet(homNay);
    final chuaDoc = s.nhacNho.where((n) => !n.daDoc).toList();
    final diemDanh = s.mucDiemDanh(homNay);

    final le = BoCuc.le(context);

    final chao = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(Ngay.dayDu(DateTime.now())),
              const SizedBox(height: 3),
              Text('Chào ${hs?.tenGoi ?? ''}', style: AppType.display(26)),
            ],
          ),
        ),
        AvatarChu(hs?.hoTen ?? '', kichThuoc: 44),
      ],
    );
    final nhac = <Widget>[
      if (chuaDoc.isNotEmpty) ...[
        for (final nn in chuaDoc.take(2)) ...[
          _LoiNhac(nn: nn),
          const SizedBox(height: Gap.sm + 2),
        ],
        const SizedBox(height: Gap.sm),
      ],
      if (s.soNhap > 0) ...[
        _ChoMang(so: s.soNhap),
        const SizedBox(height: Gap.md),
      ],
    ];
    final viec = _ViecHomNay(tongKet: tk, soChuaDiemDanh: diemDanh.length);
    // Bảng điểm danh chỉ hiện khi còn môn chưa báo; xong hết thì nhường chỗ
    // cho danh sách báo cáo — câu "xong hết bài rồi" ở trên đã nói đủ.
    final diemDanhHomNay = <Widget>[
      if (diemDanh.isNotEmpty) ...[
        TieuDeMuc(
          'Điểm danh bài hôm nay',
          eyebrow: 'Còn ${diemDanh.length} môn chưa báo',
        ),
        const SizedBox(height: Gap.md),
        DiemDanhHomNay(ds: diemDanh),
      ],
    ];
    final baoCao = <Widget>[
      // Chưa có gì mà bảng điểm danh đã là lời mời rồi thì không bày thêm
      // một khung trống nữa.
      if (ds.isNotEmpty || diemDanh.isEmpty) ...[
        TieuDeMuc(
          'Báo cáo hôm nay',
          eyebrow: ds.isEmpty ? 'Chưa có mục nào' : '${ds.length} mục',
          hanhDong: ds.isEmpty
              ? null
              : TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SoanBaoCaoScreen()),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text('Thêm'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
        ),
        const SizedBox(height: Gap.md),
      ],
      if (ds.isEmpty && diemDanh.isEmpty)
        const _ChuaViet()
      else
        for (final b in ds) ...[
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
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColor.muc,
          onRefresh: s.lamMoi,
          child: ListView(
            padding: EdgeInsets.fromLTRB(le, Gap.md, le, 96),
            children: [
              NoiDung(
                // Màn rộng: cột trái tóm tắt ngày (lời nhắc, việc, con dấu),
                // cột phải rộng hơn là việc phải làm: điểm danh rồi tới dòng
                // báo cáo. Điện thoại giữ thứ tự đọc từ trên xuống, điểm danh
                // đứng ngay sau câu "việc hôm nay" vì đó chính là việc.
                child: HaiCot(
                  tiLeTrai: 2,
                  tiLePhai: 3,
                  trai: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      chao,
                      const SizedBox(height: Gap.lg),
                      ...nhac,
                      viec,
                      const SizedBox(height: Gap.xl),
                      const KhungPhanThuong(),
                      const SizedBox(height: Gap.xl),
                      const KeHuyHieu(),
                    ],
                  ),
                  phai: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: Gap.xxl + Gap.md),
                      if (diemDanhHomNay.isNotEmpty) ...[
                        ...diemDanhHomNay,
                        const SizedBox(height: Gap.xl),
                      ],
                      ...baoCao,
                    ],
                  ),
                  hep: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      chao,
                      const SizedBox(height: Gap.lg),
                      ...nhac,
                      viec,
                      const SizedBox(height: Gap.xl),
                      if (diemDanhHomNay.isNotEmpty) ...[
                        ...diemDanhHomNay,
                        const SizedBox(height: Gap.xl),
                      ],
                      const KhungPhanThuong(),
                      const SizedBox(height: Gap.xl),
                      const KeHuyHieu(),
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

/// Bài viết lúc mất mạng đang nằm trên máy. Chạm để thử gửi ngay, còn không
/// thì app tự gửi lúc quay lại hay kéo làm mới.
class _ChoMang extends StatelessWidget {
  const _ChoMang({required this.so});
  final int so;

  @override
  Widget build(BuildContext context) {
    return TrangVo(
      mauLe: AppColor.dangLam,
      keNgang: false,
      vienNoiBat: true,
      nen: AppColor.dangLamNhat.withValues(alpha: .5),
      le: const Icon(Icons.cloud_off_rounded, size: 18, color: AppColor.dangLam),
      onTap: () async {
        final s = context.read<AppState>();
        final tb = ScaffoldMessenger.of(context);
        final daGui = await s.guiNhap();
        tb.showSnackBar(SnackBar(
          content: Text(daGui > 0
              ? 'Đã gửi $daGui báo cáo cho bố mẹ'
              : 'Vẫn chưa có mạng. App sẽ tự gửi khi có mạng lại.'),
        ));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$so báo cáo đang chờ mạng',
              style: AppType.ui(13.5, w: FontWeight.w700, color: AppColor.dangLam)),
          const SizedBox(height: 3),
          Text('Bố mẹ chưa thấy. Chạm để gửi ngay, hoặc để app tự gửi khi có mạng.',
              style: AppType.ui(12, color: AppColor.mucNhat, w: FontWeight.w500, height: 1.4)),
        ],
      ),
    );
  }
}

class _LoiNhac extends StatelessWidget {
  const _LoiNhac({required this.nn});
  final NhacNho nn;

  @override
  Widget build(BuildContext context) {
    return TrangVo(
      mauLe: AppColor.butDo,
      keNgang: false,
      vienNoiBat: true,
      nen: AppColor.butDoNhat.withValues(alpha: .45),
      le: const Icon(Icons.campaign_rounded, size: 18, color: AppColor.butDo),
      onTap: () => context.read<AppState>().docNhacNho(nn.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Bố mẹ nhắc',
                    style: AppType.ui(12, w: FontWeight.w700, color: AppColor.butDo)),
              ),
              Text(Ngay.truoc(nn.taoLuc),
                  style: AppType.ui(11, color: AppColor.mucNhat, w: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 5),
          Text(nn.noiDung, style: AppType.ui(14, w: FontWeight.w400, height: 1.5)),
          const SizedBox(height: Gap.sm),
          Text('Chạm để đánh dấu đã đọc',
              style: AppType.ui(11, color: AppColor.mucNhat, w: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Câu đầu tiên trên trang chủ nói thẳng còn việc gì, thay vì bày ra số liệu
/// rồi bắt người đọc tự luận. Bài chưa làm nói trước, rồi bài dở, rồi môn
/// chưa điểm danh — "xong hết" chỉ khi không còn gì trong ba thứ đó.
class _ViecHomNay extends StatelessWidget {
  const _ViecHomNay({required this.tongKet, required this.soChuaDiemDanh});
  final TongKetNgay tongKet;
  final int soChuaDiemDanh;

  @override
  Widget build(BuildContext context) {
    final (chu, mau) = switch (tongKet) {
      _ when tongKet.chuaLam > 0 => ('Còn ${tongKet.chuaLam} bài chưa làm', AppColor.butDo),
      _ when tongKet.dangLam > 0 => ('${tongKet.dangLam} bài đang làm dở', AppColor.dangLam),
      _ when soChuaDiemDanh > 0 => ('Còn $soChuaDiemDanh môn chưa điểm danh', AppColor.muc),
      _ when tongKet.tong == 0 => ('Chưa báo cáo bài nào', AppColor.mucNhat),
      _ => ('Xong hết bài rồi', AppColor.xong),
    };

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
          Eyebrow('Việc hôm nay'),
          const SizedBox(height: Gap.sm),
          Text(chu, style: AppType.display(23, color: mau)),
          const SizedBox(height: Gap.lg),
          Row(
            children: [
              Expanded(
                child: OSoLieu(
                    so: '${tongKet.xong}', nhan: 'Đã xong', mau: AppColor.xong),
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: OSoLieu(
                    so: '${tongKet.chuaLam + tongKet.dangLam}',
                    nhan: 'Còn lại',
                    mau: AppColor.dangLam),
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: OSoLieu(
                    so: Ngay.phut(tongKet.soPhut).replaceAll(' phút', 'p'),
                    nhan: 'Đã học',
                    mau: AppColor.muc),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChuaViet extends StatelessWidget {
  const _ChuaViet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: AppColor.dongKe),
      ),
      child: TrangTrong(
        icon: Icons.edit_note_rounded,
        tieuDe: 'Viết báo cáo đầu tiên của hôm nay',
        moTa: 'Ghi lại thầy cô giao gì, con làm tới đâu. Có ảnh bài làm thì chụp thêm — bố mẹ xem được ngay.',
        hanhDong: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SoanBaoCaoScreen()),
          ),
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('Viết báo cáo'),
        ),
      ),
    );
  }
}
