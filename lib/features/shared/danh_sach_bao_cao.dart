import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/layout/bo_cuc.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/ngay.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';
import 'chi_tiet_bao_cao_screen.dart';
import 'the_bao_cao.dart';

/// Danh sách báo cáo có lọc, gom theo ngày. Dùng chung cho cả phụ huynh và
/// học sinh — hai vai trò cần đúng một cách đọc lại lịch sử.
class DanhSachBaoCao extends StatefulWidget {
  const DanhSachBaoCao({super.key, this.hanhDongCuoi});

  /// Widget chèn xuống cuối danh sách (ví dụ nút thêm báo cáo).
  final Widget? hanhDongCuoi;

  @override
  State<DanhSachBaoCao> createState() => _DanhSachBaoCaoState();
}

class _DanhSachBaoCaoState extends State<DanhSachBaoCao> {
  LoaiBaiTap? _loai;
  TrangThai? _trangThai;
  String? _gvId;
  int _soNgay = 7;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final moc = Ngay.dauNgay(
      DateTime.now(),
    ).subtract(Duration(days: _soNgay - 1));

    var ds = s.baoCao.where((b) => !b.ngay.isBefore(moc));
    if (_loai != null) ds = ds.where((b) => b.loai == _loai);
    if (_trangThai != null) ds = ds.where((b) => b.trangThai == _trangThai);
    if (_gvId != null) ds = ds.where((b) => b.giaoVienId == _gvId);

    final theoNgay = <DateTime, List<BaoCao>>{};
    for (final b in ds) {
      theoNgay.putIfAbsent(Ngay.dauNgay(b.ngay), () => []).add(b);
    }
    final ngayList = theoNgay.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        _ThanhLoc(
          loai: _loai,
          trangThai: _trangThai,
          gvId: _gvId,
          soNgay: _soNgay,
          onLoai: (v) => setState(() {
            _loai = v;
            if (v != LoaiBaiTap.hocThem) _gvId = null;
          }),
          onTrangThai: (v) => setState(() => _trangThai = v),
          onGv: (v) => setState(() => _gvId = v),
          onSoNgay: (v) => setState(() => _soNgay = v),
        ),
        Expanded(
          child: ngayList.isEmpty
              ? TrangTrong(
                  icon: Icons.filter_alt_off_rounded,
                  tieuDe: 'Không có báo cáo nào khớp',
                  moTa: 'Thử nới khoảng thời gian hoặc bỏ bớt bộ lọc.',
                  hanhDong: OutlinedButton(
                    onPressed: () => setState(() {
                      _loai = null;
                      _trangThai = null;
                      _gvId = null;
                      _soNgay = 30;
                    }),
                    child: const Text('Bỏ hết bộ lọc'),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, rang) {
                    final le = BoCuc.leCanhGiua(
                      rang.maxWidth,
                      BoCuc.le(context),
                    );
                    return ListView(
                      padding: EdgeInsets.fromLTRB(le, Gap.sm, le, 96),
                      children: [
                        for (final n in ngayList) ...[
                          _DauNgay(ngay: n, so: theoNgay[n]!.length),
                          const SizedBox(height: Gap.md),
                          // Màn rộng xếp thẻ thành hai ba cột; điện thoại một cột.
                          LuoiThe(
                            children: [
                              for (final b in theoNgay[n]!)
                                TheBaoCao(
                                  b,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ChiTietBaoCaoScreen(baoCaoId: b.id),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: Gap.md + Gap.sm + 2),
                        ],
                        if (widget.hanhDongCuoi != null) widget.hanhDongCuoi!,
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DauNgay extends StatelessWidget {
  const _DauNgay({required this.ngay, required this.so});
  final DateTime ngay;
  final int so;

  @override
  Widget build(BuildContext context) {
    final homNay = Ngay.laHomNay(ngay);
    return Row(
      children: [
        Text(
          Ngay.nhan(ngay),
          style: AppType.ui(
            13.5,
            w: FontWeight.w700,
            color: homNay ? AppColor.muc : AppColor.ink,
          ),
        ),
        const SizedBox(width: Gap.sm),
        Expanded(child: Container(height: 1, color: AppColor.dongKe)),
        const SizedBox(width: Gap.sm),
        Text(
          '$so mục',
          style: AppType.ui(11.5, color: AppColor.mucNhat, w: FontWeight.w500),
        ),
      ],
    );
  }
}

/// Thanh lọc cuộn ngang. Khi chọn "Học thêm" mới hiện thêm hàng lọc theo
/// thầy cô — vì chỉ hạng mục đó mới cần phân biệt người dạy.
class _ThanhLoc extends StatelessWidget {
  const _ThanhLoc({
    required this.loai,
    required this.trangThai,
    required this.gvId,
    required this.soNgay,
    required this.onLoai,
    required this.onTrangThai,
    required this.onGv,
    required this.onSoNgay,
  });

  final LoaiBaiTap? loai;
  final TrangThai? trangThai;
  final String? gvId;
  final int soNgay;
  final ValueChanged<LoaiBaiTap?> onLoai;
  final ValueChanged<TrangThai?> onTrangThai;
  final ValueChanged<String?> onGv;
  final ValueChanged<int> onSoNgay;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final dsGv = s.gvTheoLoai(LoaiBaiTap.hocThem);

    return LayoutBuilder(
      builder: (context, rang) {
        final le = BoCuc.leCanhGiua(rang.maxWidth, BoCuc.le(context));
        return Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColor.dongKe)),
          ),
          padding: const EdgeInsets.only(bottom: Gap.md),
          child: Column(
            children: [
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: le),
                  children: [
                    for (final n in [7, 30, 90])
                      _Chip(
                        nhan: n == 90 ? 'Tất cả' : '$n ngày',
                        chon: soNgay == n,
                        onTap: () => onSoNgay(n),
                      ),
                    const _Vach(),
                    _Chip(
                      nhan: 'Mọi hạng mục',
                      chon: loai == null,
                      onTap: () => onLoai(null),
                    ),
                    for (final l in LoaiBaiTap.values)
                      _Chip(
                        nhan: l.nhanNgan,
                        chon: loai == l,
                        mau: l.mau,
                        onTap: () => onLoai(l),
                      ),
                    const _Vach(),
                    _Chip(
                      nhan: 'Mọi trạng thái',
                      chon: trangThai == null,
                      onTap: () => onTrangThai(null),
                    ),
                    for (final t in TrangThai.values)
                      _Chip(
                        nhan: t.nhan,
                        chon: trangThai == t,
                        mau: t.mau,
                        onTap: () => onTrangThai(t),
                      ),
                  ],
                ),
              ),
              if (loai == LoaiBaiTap.hocThem) ...[
                const SizedBox(height: Gap.sm),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: le),
                    children: [
                      _Chip(
                        nhan: 'Mọi thầy cô',
                        chon: gvId == null,
                        onTap: () => onGv(null),
                      ),
                      for (final g in dsGv)
                        _Chip(
                          nhan: g.hoTen,
                          chon: gvId == g.id,
                          mau: AppColor.hocThem,
                          onTap: () => onGv(g.id),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.nhan,
    required this.chon,
    required this.onTap,
    this.mau,
  });
  final String nhan;
  final bool chon;
  final VoidCallback onTap;
  final Color? mau;

  @override
  Widget build(BuildContext context) {
    final m = mau ?? AppColor.muc;
    return Padding(
      padding: const EdgeInsets.only(right: Gap.sm),
      child: Material(
        color: chon ? m : AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(R.sm),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: Gap.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(R.sm),
              border: Border.all(color: chon ? m : AppColor.dongKe),
            ),
            child: Center(
              child: Text(
                nhan,
                style: AppType.ui(
                  12.5,
                  w: FontWeight.w600,
                  color: chon ? Colors.white : AppColor.mucNhat,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Vach extends StatelessWidget {
  const _Vach();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 8),
    child: Container(width: 1, color: AppColor.dongKe),
  );
}
