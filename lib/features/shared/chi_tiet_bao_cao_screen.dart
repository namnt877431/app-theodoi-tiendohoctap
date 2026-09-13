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
import '../parent/soan_nhac_nho.dart';
import 'anh_bai_lam.dart';
import 'soan_bao_cao_screen.dart';
import 'the_bai_hoc.dart';

class ChiTietBaoCaoScreen extends StatelessWidget {
  const ChiTietBaoCaoScreen({super.key, required this.baoCaoId});
  final String baoCaoId;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final bc = s.baoCao.where((b) => b.id == baoCaoId).firstOrNull;
    if (bc == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy báo cáo này')),
      );
    }

    final laPhuHuynh = s.nguoiDung?.vaiTro == VaiTro.phuHuynh;
    final gv = s.tenGv(bc.giaoVienId);
    final bh = s.baiHocTheoId(bc.baiHocId);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tenMon(bc.monId)),
        actions: [
          if (!laPhuHuynh)
            Padding(
              padding: const EdgeInsets.only(right: Gap.lg),
              child: NutO(
                icon: Icons.edit_outlined,
                tooltip: 'Sửa báo cáo',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SoanBaoCaoScreen(baoCao: bc)),
                ),
              ),
            ),
        ],
      ),
      body: Builder(builder: (context) {
        final le = BoCuc.le(context);
        // Lời của học sinh: nhãn và trang vở…
        final trangVo = <Widget>[
          // Wrap chứ không Row: người dùng phóng chữ lên 1.3 thì hai nhãn
          // không còn vừa một hàng trên điện thoại hẹp.
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              NhanLoai(bc.loai, dayDu: true),
              NhanTrangThai(bc.trangThai),
            ],
          ),
          const SizedBox(height: Gap.lg),
          TrangVo(
            mauLe: bc.trangThai.mau,
            vienNoiBat: true,
            padding: const EdgeInsets.fromLTRB(Gap.md, Gap.lg, Gap.lg, Gap.lg),
            le: Icon(bc.trangThai.icon, size: 20, color: bc.trangThai.mau),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.tenMon(bc.monId), style: AppType.display(21)),
                if (bh != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    bh.ten,
                    style: AppType.ui(14, color: AppColor.muc, w: FontWeight.w600),
                  ),
                ],
                if (gv != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    gv,
                    style: AppType.ui(13, color: AppColor.mucNhat, w: FontWeight.w500),
                  ),
                ],
                if (bc.noiDung.isNotEmpty) ...[
                  const SizedBox(height: Gap.md),
                  Text(
                    bc.noiDung,
                    style: AppType.ui(15, w: FontWeight.w400, height: lineHeight / 15),
                  ),
                ],
              ],
            ),
          ),
        ];
        // …ảnh bài làm…
        final anh = <Widget>[
          if (bc.anh.isNotEmpty) ...[
            const SizedBox(height: Gap.xl),
            TieuDeMuc('Ảnh bài làm', eyebrow: '${bc.anh.length} ảnh'),
            const SizedBox(height: Gap.md),
            _LuoiAnh(duongDan: bc.anh),
          ],
        ];
        // …và phần đối đáp: nhận xét của bố mẹ, nút nhắc hay đổi trạng thái.
        final doiDap = <Widget>[
          const SizedBox(height: Gap.xl),
          _NhanXet(bc: bc, laPhuHuynh: laPhuHuynh),
          if (laPhuHuynh) ...[
            const SizedBox(height: Gap.xl),
            FilledButton.icon(
              onPressed: () => moSoanNhacNho(
                context,
                baoCaoId: bc.id,
                goiY: 'Bài ${s.tenMon(bc.monId)} còn dở, con làm nốt nhé.',
              ),
              icon: const Icon(Icons.campaign_rounded, size: 19),
              label: const Text('Nhắc con về bài này'),
            ),
          ] else ...[
            const SizedBox(height: Gap.xl),
            _DoiTrangThai(bc: bc),
          ],
        ];
        // Phần tra cứu: bài học trong sách và thông tin phụ.
        final thongTin = Container(
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.sm),
          decoration: BoxDecoration(
            color: AppColor.giayTrang,
            borderRadius: BorderRadius.circular(R.lg),
            border: Border.all(color: AppColor.dongKe),
          ),
          child: Column(
            children: [
              DongThongTin(Icons.event_rounded, 'Ngày học', Ngay.dayDu(bc.ngay)),
              const Divider(),
              DongThongTin(Icons.schedule_rounded, 'Thời gian làm bài',
                  bc.soPhut == null ? 'Chưa ghi' : Ngay.phut(bc.soPhut!)),
              const Divider(),
              DongThongTin(Icons.send_rounded, 'Gửi lúc',
                  '${Ngay.gio(bc.taoLuc)} · ${Ngay.ddMM(bc.taoLuc)}'),
              if (gv != null) ...[
                const Divider(),
                DongThongTin(
                  Icons.person_outline_rounded,
                  bc.loai == LoaiBaiTap.hocThem ? 'Thầy cô dạy thêm' : 'Giáo viên bộ môn',
                  gv,
                ),
              ],
            ],
          ),
        );
        final traCuu = <Widget>[
          if (bh != null) ...[
            TheBaiHoc(bh, laPhuHuynh: laPhuHuynh),
            const SizedBox(height: Gap.lg),
          ],
          thongTin,
        ];

        return ListView(
          padding: EdgeInsets.fromLTRB(le, Gap.sm, le, Gap.xxl),
          children: [
            NoiDung(
              toiDa: 1100,
              child: HaiCot(
                // Màn rộng: trái là lời học sinh và đối đáp, phải là bài học
                // trong sách cùng thông tin phụ.
                trai: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [...trangVo, ...anh, ...doiDap],
                ),
                phai: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [const SizedBox(height: Gap.xxl + Gap.sm), ...traCuu],
                ),
                // Điện thoại: trang vở, bài học, ảnh, thông tin, rồi đối đáp.
                hep: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...trangVo,
                    if (bh != null) ...[
                      const SizedBox(height: Gap.lg),
                      TheBaiHoc(bh, laPhuHuynh: laPhuHuynh),
                    ],
                    ...anh,
                    const SizedBox(height: Gap.xl),
                    thongTin,
                    ...doiDap,
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Ảnh bài làm. Dữ liệu mẫu dùng đường dẫn giả "demo:" nên vẽ ô giữ chỗ;
/// ảnh chụp thật từ máy hiện bằng Image.file.
class _LuoiAnh extends StatelessWidget {
  const _LuoiAnh({required this.duongDan});
  final List<String> duongDan;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: duongDan.length,
        separatorBuilder: (_, _) => const SizedBox(width: Gap.sm),
        itemBuilder: (context, i) => AnhBaiLam(
          duongDan: duongDan[i],
          canh: 132,
          onTap: () => moXemAnh(context, duongDan: duongDan, batDau: i),
        ),
      ),
    );
  }
}

/// Nhận xét của phụ huynh — chỗ để bố mẹ viết một câu vào bài của con,
/// đúng như dòng chữ đỏ thầy cô ghi cuối trang vở.
class _NhanXet extends StatefulWidget {
  const _NhanXet({required this.bc, required this.laPhuHuynh});
  final BaoCao bc;
  final bool laPhuHuynh;

  @override
  State<_NhanXet> createState() => _NhanXetState();
}

class _NhanXetState extends State<_NhanXet> {
  late final _c = TextEditingController(text: widget.bc.nhanXetPhuHuynh ?? '');
  bool _dangSua = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _luu() async {
    await context
        .read<AppState>()
        .luuBaoCao(widget.bc.copyWith(nhanXetPhuHuynh: _c.text.trim()));
    if (!mounted) return;
    setState(() => _dangSua = false);
  }

  @override
  Widget build(BuildContext context) {
    final co = (widget.bc.nhanXetPhuHuynh ?? '').isNotEmpty;

    if (!widget.laPhuHuynh) {
      if (!co) return const SizedBox.shrink();
      return TrangVo(
        mauLe: AppColor.butDo,
        keNgang: false,
        le: const Icon(Icons.rate_review_rounded, size: 18, color: AppColor.butDo),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bố mẹ nhận xét',
                style: AppType.ui(12, w: FontWeight.w700, color: AppColor.butDo)),
            const SizedBox(height: 6),
            Text(widget.bc.nhanXetPhuHuynh!,
                style: AppType.ui(14, w: FontWeight.w400, height: 1.55)),
          ],
        ),
      );
    }

    if (co && !_dangSua) {
      return TrangVo(
        mauLe: AppColor.butDo,
        keNgang: false,
        onTap: () => setState(() => _dangSua = true),
        le: const Icon(Icons.rate_review_rounded, size: 18, color: AppColor.butDo),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Nhận xét của bạn',
                      style: AppType.ui(12, w: FontWeight.w700, color: AppColor.butDo)),
                ),
                Text('Chạm để sửa',
                    style: AppType.ui(11, color: AppColor.mucNhat, w: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 6),
            Text(widget.bc.nhanXetPhuHuynh!,
                style: AppType.ui(14, w: FontWeight.w400, height: 1.55)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow('Nhận xét của bạn'),
        const SizedBox(height: Gap.sm),
        TextField(
          controller: _c,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: AppType.ui(14.5, height: 1.5, w: FontWeight.w400),
          decoration: const InputDecoration(
            hintText: 'Viết một câu cho con đọc — khen hoặc dặn dò…',
          ),
        ),
        const SizedBox(height: Gap.md),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(onPressed: _luu, child: const Text('Lưu nhận xét')),
        ),
      ],
    );
  }
}

/// Học sinh đổi trạng thái ngay trong màn chi tiết, khỏi phải mở lại form.
class _DoiTrangThai extends StatelessWidget {
  const _DoiTrangThai({required this.bc});
  final BaoCao bc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow('Cập nhật trạng thái'),
        const SizedBox(height: Gap.sm),
        Row(
          children: [
            for (final tt in TrangThai.values) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      context.read<AppState>().luuBaoCao(bc.copyWith(trangThai: tt)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: Gap.md),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bc.trangThai == tt ? tt.mauNen : AppColor.giayTrang,
                      borderRadius: BorderRadius.circular(R.md),
                      border: Border.all(
                        color: bc.trangThai == tt
                            ? tt.mau.withValues(alpha: .5)
                            : AppColor.dongKe,
                        width: bc.trangThai == tt ? 1.4 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(tt.icon,
                            size: 18,
                            color: bc.trangThai == tt ? tt.mau : AppColor.mucNhat),
                        const SizedBox(height: 5),
                        Text(
                          tt.nhan,
                          style: AppType.ui(11.5,
                              w: FontWeight.w600,
                              color: bc.trangThai == tt ? tt.mau : AppColor.mucNhat),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (tt != TrangThai.values.last) const SizedBox(width: Gap.sm),
            ],
          ],
        ),
      ],
    );
  }
}
