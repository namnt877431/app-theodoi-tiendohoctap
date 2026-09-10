import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';
import '../../data/repositories/hoc_tap_repository.dart';
import 'dang_nhap_screen.dart';

/// Tạo tài khoản. Chỉ mở cho phụ huynh và học sinh — tài khoản quản trị do
/// người dựng hệ thống tạo tay trong Firebase Console, không để ai tự đăng ký.
class DangKyScreen extends StatefulWidget {
  const DangKyScreen({super.key});

  @override
  State<DangKyScreen> createState() => _DangKyScreenState();
}

class _DangKyScreenState extends State<DangKyScreen> {
  final _form = GlobalKey<FormState>();
  final _hoTen = TextEditingController();
  final _email = TextEditingController();
  final _matKhau = TextEditingController();
  final _nhacLai = TextEditingController();
  final _lop = TextEditingController();
  final _truong = TextEditingController();
  final _sdt = TextEditingController();

  VaiTro _vaiTro = VaiTro.phuHuynh;
  bool _dangGui = false;
  String? _loi;

  @override
  void dispose() {
    for (final c in [_hoTen, _email, _matKhau, _nhacLai, _lop, _truong, _sdt]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _tao() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    try {
      final laHocSinh = _vaiTro == VaiTro.hocSinh;
      await context.read<AppState>().dangKy(
            hoTen: _hoTen.text,
            email: _email.text,
            matKhau: _matKhau.text,
            vaiTro: _vaiTro,
            lop: laHocSinh ? _lop.text.trim() : null,
            truong: laHocSinh ? _truong.text.trim() : null,
            soDienThoai: laHocSinh ? null : _sdt.text.trim(),
          );
      // Tạo xong là đã đăng nhập luôn; AuthGate lo phần chuyển màn.
    } on LoiHocTap catch (e) {
      if (mounted) setState(() => _loi = e.thongDiep);
    } catch (_) {
      if (mounted) setState(() => _loi = 'Không tạo được tài khoản. Thử lại sau.');
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final laHocSinh = _vaiTro == VaiTro.hocSinh;

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xxl),
          children: [
            Eyebrow('Bạn là ai'),
            const SizedBox(height: Gap.sm),
            Row(
              children: [
                for (final vt in [VaiTro.phuHuynh, VaiTro.hocSinh]) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _vaiTro = vt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: Gap.lg),
                        decoration: BoxDecoration(
                          color: _vaiTro == vt ? AppColor.sky : AppColor.giayTrang,
                          borderRadius: BorderRadius.circular(R.md),
                          border: Border.all(
                            color: _vaiTro == vt
                                ? AppColor.muc.withValues(alpha: .45)
                                : AppColor.dongKe,
                            width: _vaiTro == vt ? 1.4 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(vt.icon,
                                size: 22,
                                color: _vaiTro == vt ? AppColor.muc : AppColor.mucNhat),
                            const SizedBox(height: 6),
                            Text(
                              vt.nhan,
                              style: AppType.ui(13.5,
                                  w: FontWeight.w700,
                                  color: _vaiTro == vt ? AppColor.muc : AppColor.mucNhat),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (vt == VaiTro.phuHuynh) const SizedBox(width: Gap.sm),
                ],
              ],
            ),
            const SizedBox(height: Gap.lg),
            _O(
              nhan: 'Họ và tên',
              c: _hoTen,
              hint: laHocSinh ? 'Nguyễn Minh Khôi' : 'Nguyễn Văn Hùng',
              capitalize: true,
              kiemTra: (v) =>
                  v.trim().length >= 2 ? null : 'Nhập họ tên đầy đủ',
            ),
            _O(
              nhan: 'Email',
              c: _email,
              hint: 'ten@email.com',
              banPhim: TextInputType.emailAddress,
              kiemTra: (v) => v.trim().contains('@') ? null : 'Nhập email hợp lệ',
            ),
            _O(
              nhan: 'Mật khẩu',
              c: _matKhau,
              hint: 'Ít nhất 6 ký tự',
              an: true,
              kiemTra: (v) => v.length >= 6 ? null : 'Mật khẩu ít nhất 6 ký tự',
            ),
            _O(
              nhan: 'Nhắc lại mật khẩu',
              c: _nhacLai,
              an: true,
              kiemTra: (v) => v == _matKhau.text ? null : 'Hai lần nhập chưa khớp',
            ),
            if (laHocSinh) ...[
              Row(
                children: [
                  Expanded(
                    child: _O(nhan: 'Lớp', c: _lop, hint: '9A2', capitalize: true),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    flex: 2,
                    child: _O(
                      nhan: 'Trường',
                      c: _truong,
                      hint: 'THCS Nguyễn Trãi',
                      capitalize: true,
                    ),
                  ),
                ],
              ),
            ] else
              _O(
                nhan: 'Số điện thoại (không bắt buộc)',
                c: _sdt,
                hint: '09xx xxx xxx',
                banPhim: TextInputType.phone,
              ),
            if (_loi != null) ...[
              HopLoi(_loi!),
              const SizedBox(height: Gap.md),
            ],
            Container(
              padding: const EdgeInsets.all(Gap.md),
              decoration: BoxDecoration(
                color: AppColor.sky.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(R.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 17, color: AppColor.muc),
                  const SizedBox(width: Gap.sm),
                  Expanded(
                    child: Text(
                      laHocSinh
                          ? 'Tạo xong, vào mục Tài khoản bấm "Tạo mã mời" rồi đọc mã sáu số cho bố mẹ nhập.'
                          : 'Tạo xong, bạn nhập mã mời sáu số mà con đọc cho để nối vào tài khoản của con.',
                      style: AppType.ui(12.5,
                          color: AppColor.muc, w: FontWeight.w500, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.lg),
            FilledButton(
              onPressed: _dangGui ? null : _tao,
              child: Text(_dangGui ? 'Đang tạo…' : 'Tạo tài khoản'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Một ô nhập kèm nhãn, gói lại để biểu mẫu đăng ký khỏi lặp mười lần
/// cùng một khối Column.
class _O extends StatelessWidget {
  const _O({
    required this.nhan,
    required this.c,
    this.hint,
    this.an = false,
    this.capitalize = false,
    this.banPhim,
    this.kiemTra,
  });

  final String nhan;
  final TextEditingController c;
  final String? hint;
  final bool an;
  final bool capitalize;
  final TextInputType? banPhim;
  final String? Function(String)? kiemTra;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.sm, left: 2),
            child: Eyebrow(nhan),
          ),
          TextFormField(
            controller: c,
            obscureText: an,
            keyboardType: banPhim,
            textCapitalization:
                capitalize ? TextCapitalization.words : TextCapitalization.none,
            style: AppType.ui(15, w: FontWeight.w500),
            decoration: InputDecoration(hintText: hint),
            validator: kiemTra == null ? null : (v) => kiemTra!(v ?? ''),
          ),
        ],
      ),
    );
  }
}
