import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/anh/nen_anh.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/ngay.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';
import 'chon_bai_hoc.dart';
import 'chon_giao_vien.dart';
import 'anh_bai_lam.dart';

/// Học sinh viết báo cáo trong ngày. Ô nội dung được kẻ dòng đúng nhịp trang vở
/// để việc gõ vào app giống viết vào vở hơn là điền biểu mẫu.
class SoanBaoCaoScreen extends StatefulWidget {
  const SoanBaoCaoScreen({super.key, this.baoCao, this.loaiMacDinh});

  final BaoCao? baoCao;
  final LoaiBaiTap? loaiMacDinh;

  @override
  State<SoanBaoCaoScreen> createState() => _SoanBaoCaoScreenState();
}

class _SoanBaoCaoScreenState extends State<SoanBaoCaoScreen> {
  late LoaiBaiTap _loai;
  late String _monId;
  String? _gvId;
  String? _baiHocId;
  late DateTime _ngay;
  late TrangThai _trangThai;
  late final TextEditingController _noiDung;
  int? _soPhut;
  late List<String> _anh;
  bool _dangLuu = false;

  bool get _suaCu => widget.baoCao != null;

  @override
  void initState() {
    super.initState();
    final b = widget.baoCao;
    _loai = b?.loai ?? widget.loaiMacDinh ?? LoaiBaiTap.trenLop;
    _monId = b?.monId ?? context.read<AppState>().monMacDinh;
    _gvId = b?.giaoVienId;
    _baiHocId = b?.baiHocId;
    _ngay = b?.ngay ?? Ngay.dauNgay(DateTime.now());
    _trangThai = b?.trangThai ?? TrangThai.xong;
    _noiDung = TextEditingController(text: b?.noiDung ?? '');
    _soPhut = b?.soPhut;
    _anh = [...?b?.anh];
  }

  @override
  void dispose() {
    _noiDung.dispose();
    super.dispose();
  }

  Future<void> _themAnh(ImageSource nguon) async {
    try {
      // Thu về cạnh dài 1600 px ngay lúc chụp — trang vở ở cỡ đó vẫn đọc rõ
      // chữ, còn ảnh 12 MP nguyên bản thì vừa nặng vừa tốn kho. Sau đó ép
      // tiếp xuống dưới 500 KB.
      final f = await ImagePicker().pickImage(
        source: nguon,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (f == null) return;
      final duongDan = await nenAnhBaiLam(f.path);
      if (mounted) setState(() => _anh = [..._anh, duongDan]);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được máy ảnh trên thiết bị này')),
      );
    }
  }

  Future<void> _luu() async {
    if (_noiDung.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viết vài dòng về bài hôm nay đã nhé')),
      );
      return;
    }
    setState(() => _dangLuu = true);
    final s = context.read<AppState>();
    final goc = widget.baoCao;

    // Dựng thẳng đối tượng thay vì copyWith: người dùng có quyền bỏ trống
    // thầy cô hoặc số phút, mà copyWith thì không xóa được giá trị cũ.
    final mau = goc ?? s.taoBaoCaoRong(loai: _loai);
    final bc = BaoCao(
      id: mau.id,
      hocSinhId: mau.hocSinhId,
      ngay: _ngay,
      loai: _loai,
      monId: _monId,
      giaoVienId: _gvId,
      baiHocId: _baiHocId,
      noiDung: _noiDung.text.trim(),
      trangThai: _trangThai,
      anh: _anh,
      soPhut: _soPhut,
      nhanXetPhuHuynh: mau.nhanXetPhuHuynh,
      phuHuynhDaXem: mau.phuHuynhDaXem,
      taoLuc: mau.taoLuc,
    );
    final KetQuaLuu ketQua;
    try {
      ketQua = await s.luuBaoCao(bc);
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangLuu = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lưu được: $e')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: ketQua == KetQuaLuu.choMang ? 5 : 4),
        content: Text(switch (ketQua) {
          KetQuaLuu.choMang => 'Chưa có mạng — đã cất trên máy, sẽ tự gửi khi có mạng.',
          KetQuaLuu.daGui => _suaCu ? 'Đã lưu báo cáo' : 'Đã gửi báo cáo cho bố mẹ',
        }),
      ),
    );
  }

  Future<void> _xoa() async {
    await context.read<AppState>().xoaBaoCao(widget.baoCao!.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final dsGv = s.gvChoHocSinh(_loai);

    // Chưa có môn nào thì không dựng biểu mẫu — một danh sách chọn rỗng chỉ
    // làm người dùng bối rối chứ không nói được vấn đề nằm ở đâu.
    if (s.monHoc.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Viết báo cáo')),
        body: const TrangTrong(
          icon: Icons.menu_book_outlined,
          tieuDe: 'Chưa có môn học nào',
          moTa: 'Danh mục môn học còn trống nên chưa viết báo cáo được. Nhờ quản trị nạp danh mục trước.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_suaCu ? 'Sửa báo cáo' : 'Viết báo cáo'),
        actions: [
          if (_suaCu)
            Padding(
              padding: const EdgeInsets.only(right: Gap.lg),
              child: NutO(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Xóa báo cáo',
                onTap: _xoa,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xxl),
        children: [
          _Nhan('Hạng mục'),
          Row(
            children: [
              for (final l in LoaiBaiTap.values) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _loai = l;
                      _gvId = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: Gap.md + 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _loai == l ? l.mauNen : AppColor.giayTrang,
                        borderRadius: BorderRadius.circular(R.md),
                        border: Border.all(
                          color: _loai == l ? l.mau.withValues(alpha: .45) : AppColor.dongKe,
                          width: _loai == l ? 1.4 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            l == LoaiBaiTap.trenLop
                                ? Icons.school_rounded
                                : Icons.auto_stories_rounded,
                            size: 16,
                            color: _loai == l ? l.mau : AppColor.mucNhat,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              l.nhan,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.ui(13,
                                  w: FontWeight.w600,
                                  color: _loai == l ? l.mau : AppColor.mucNhat),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (l != LoaiBaiTap.values.last) const SizedBox(width: Gap.sm),
              ],
            ],
          ),
          const SizedBox(height: Gap.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Nhan('Môn học'),
                    DropdownButtonFormField<String>(
                      initialValue: _monId,
                      isExpanded: true,
                      style: AppType.ui(15, w: FontWeight.w500),
                      items: [
                        for (final m in s.monHoc)
                          DropdownMenuItem(value: m.id, child: Text(m.ten)),
                      ],
                      onChanged: (v) => setState(() {
                        if (v != _monId) _baiHocId = null;
                        _monId = v!;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Nhan('Ngày học'),
                    InkWell(
                      borderRadius: BorderRadius.circular(R.md),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _ngay,
                          firstDate: DateTime.now().subtract(const Duration(days: 60)),
                          lastDate: DateTime.now().add(const Duration(days: 7)),
                        );
                        if (d != null) setState(() => _ngay = Ngay.dauNgay(d));
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(),
                        child: Text(
                          Ngay.nhan(_ngay),
                          style: AppType.ui(15, w: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          _Nhan(_loai == LoaiBaiTap.hocThem ? 'Thầy cô dạy thêm' : 'Giáo viên bộ môn'),
          ChonGiaoVien(
            loai: _loai,
            giaTri: _gvId,
            dsGv: dsGv,
            monId: _monId,
            onChanged: (v) => setState(() => _gvId = v),
          ),
          // Chỉ hiện khi khối lớp của em có danh mục cho môn này — không thì
          // ô chọn rỗng chỉ làm người ta tưởng mình thiếu gì đó.
          if (s.baiHocTheoMon(_monId).isNotEmpty) ...[
            const SizedBox(height: Gap.lg),
            _Nhan('Bài học trong sách'),
            ChonBaiHoc(
              monId: _monId,
              giaTri: _baiHocId,
              onChanged: (v) => setState(() => _baiHocId = v),
            ),
          ],
          const SizedBox(height: Gap.lg),
          _Nhan('Hôm nay con làm gì?'),
          _OViet(controller: _noiDung),
          const SizedBox(height: Gap.lg),
          _Nhan('Làm tới đâu rồi?'),
          Row(
            children: [
              for (final tt in TrangThai.values) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _trangThai = tt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: Gap.md),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _trangThai == tt ? tt.mauNen : AppColor.giayTrang,
                        borderRadius: BorderRadius.circular(R.md),
                        border: Border.all(
                          color: _trangThai == tt
                              ? tt.mau.withValues(alpha: .5)
                              : AppColor.dongKe,
                          width: _trangThai == tt ? 1.4 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(tt.icon,
                              size: 18,
                              color: _trangThai == tt ? tt.mau : AppColor.mucNhat),
                          const SizedBox(height: 5),
                          Text(
                            tt.nhan,
                            style: AppType.ui(11.5,
                                w: FontWeight.w600,
                                color: _trangThai == tt ? tt.mau : AppColor.mucNhat),
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
          const SizedBox(height: Gap.lg),
          _Nhan('Làm mất bao lâu? (không bắt buộc)'),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (final p in [15, 30, 45, 60, 90])
                ChoiceChip(
                  label: Text(Ngay.phut(p)),
                  selected: _soPhut == p,
                  showCheckmark: false,
                  selectedColor: AppColor.muc,
                  labelStyle: AppType.ui(13,
                      w: FontWeight.w600,
                      color: _soPhut == p ? Colors.white : AppColor.muc),
                  onSelected: (v) => setState(() => _soPhut = v ? p : null),
                ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          _Nhan('Ảnh bài làm (không bắt buộc)'),
          _KhoAnh(
            anh: _anh,
            onXoa: (i) => setState(() => _anh = [..._anh]..removeAt(i)),
            onChup: () => _themAnh(ImageSource.camera),
            onChon: () => _themAnh(ImageSource.gallery),
          ),
          const SizedBox(height: Gap.xl),
          FilledButton(
            onPressed: _dangLuu ? null : _luu,
            child: Text(
              _dangLuu
                  ? 'Đang lưu…'
                  : (_suaCu ? 'Lưu thay đổi' : 'Gửi báo cáo cho bố mẹ'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Nhan extends StatelessWidget {
  const _Nhan(this.chu);
  final String chu;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Gap.sm, left: 2),
        child: Eyebrow(chu),
      );
}

/// Ô nhập nội dung kẻ dòng đúng nhịp trang vở, để việc gõ báo cáo giống
/// viết vào vở hơn là điền biểu mẫu.
class _OViet extends StatefulWidget {
  const _OViet({required this.controller});
  final TextEditingController controller;

  @override
  State<_OViet> createState() => _OVietState();
}

class _OVietState extends State<_OViet> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const padTren = Gap.md;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(
          color: _focus.hasFocus ? AppColor.muc : AppColor.dongKe,
          width: _focus.hasFocus ? 1.6 : 1,
        ),
      ),
      child: CustomPaint(
        painter: _KeDong(padTren: padTren),
        child: TextField(
          controller: widget.controller,
          focusNode: _focus,
          minLines: 5,
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
          style: AppType.ui(15, height: lineHeight / 15, w: FontWeight.w400),
          decoration: InputDecoration(
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(Gap.lg, padTren, Gap.lg, padTren),
            hintText: 'Cô Lan giao bài 12, 13, 14 trang 47. Con làm xong bài 12 và 13, bài 14 chưa ra…',
            hintStyle: AppType.ui(14.5,
                color: AppColor.mucNhat.withValues(alpha: .6),
                w: FontWeight.w400,
                height: lineHeight / 14.5),
          ),
        ),
      ),
    );
  }
}

class _KeDong extends CustomPainter {
  const _KeDong({required this.padTren});
  final double padTren;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColor.dongKe
      ..strokeWidth = 1;
    for (var y = padTren + lineHeight; y < size.height - 2; y += lineHeight) {
      canvas.drawLine(Offset(Gap.md, y), Offset(size.width - Gap.md, y), p);
    }
  }

  @override
  bool shouldRepaint(_KeDong old) => old.padTren != padTren;
}

class _KhoAnh extends StatelessWidget {
  const _KhoAnh({
    required this.anh,
    required this.onXoa,
    required this.onChup,
    required this.onChon,
  });

  final List<String> anh;
  final ValueChanged<int> onXoa;
  final VoidCallback onChup;
  final VoidCallback onChon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onChup,
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('Chụp ảnh'),
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onChon,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Chọn từ máy'),
              ),
            ),
          ],
        ),
        if (anh.isNotEmpty) ...[
          const SizedBox(height: Gap.md),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: anh.length,
              separatorBuilder: (_, _) => const SizedBox(width: Gap.sm),
              itemBuilder: (_, i) => AnhBaiLam(
                duongDan: anh[i],
                canh: 104,
                onXoa: () => onXoa(i),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
