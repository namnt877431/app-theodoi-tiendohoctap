import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../data/app_state.dart';
import '../../data/repositories/hoc_tap_repository.dart';
import 'bia_so.dart';
import 'dang_ky_screen.dart';
import 'dung_thu_sheet.dart';

class DangNhapScreen extends StatefulWidget {
  const DangNhapScreen({super.key});

  @override
  State<DangNhapScreen> createState() => _DangNhapScreenState();
}

class _DangNhapScreenState extends State<DangNhapScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _matKhau = TextEditingController();
  bool _hienMatKhau = false;
  bool _dangGui = false;
  String? _loi;

  @override
  void dispose() {
    _email.dispose();
    _matKhau.dispose();
    super.dispose();
  }

  Future<void> _vao() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    try {
      await context.read<AppState>().dangNhap(_email.text, _matKhau.text);
      // AuthGate tự đổi màn khi phiên thay đổi — ở đây không điều hướng.
    } on LoiHocTap catch (e) {
      if (mounted) setState(() => _loi = e.thongDiep);
    } catch (_) {
      if (mounted) setState(() => _loi = 'Không đăng nhập được. Thử lại sau.');
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  Future<void> _quenMatKhau() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _loi = 'Nhập email trước rồi bấm quên mật khẩu.');
      return;
    }
    try {
      await context.read<AppState>().guiEmailDatLaiMatKhau(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi link đặt lại mật khẩu tới $email')),
      );
    } on LoiHocTap catch (e) {
      if (mounted) setState(() => _loi = e.thongDiep);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.giay,
      body: Column(
        children: [
          const BiaSo(
            phuDe: 'Mỗi tối, bố mẹ biết hôm nay con đã học những gì — không phải hỏi.',
            gonGang: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xl, Gap.xl, Gap.xl),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Đăng nhập', style: AppType.ui(17, w: FontWeight.w700)),
                    const SizedBox(height: Gap.lg),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      style: AppType.ui(15, w: FontWeight.w500),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'ten@email.com',
                      ),
                      validator: (v) =>
                          (v ?? '').trim().contains('@') ? null : 'Nhập email hợp lệ',
                    ),
                    const SizedBox(height: Gap.md),
                    TextFormField(
                      controller: _matKhau,
                      obscureText: !_hienMatKhau,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _vao(),
                      style: AppType.ui(15, w: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hienMatKhau
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                            color: AppColor.mucNhat,
                          ),
                          tooltip: _hienMatKhau ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                          onPressed: () => setState(() => _hienMatKhau = !_hienMatKhau),
                        ),
                      ),
                      validator: (v) =>
                          (v ?? '').length >= 6 ? null : 'Mật khẩu ít nhất 6 ký tự',
                    ),
                    if (_loi != null) ...[
                      const SizedBox(height: Gap.md),
                      HopLoi(_loi!),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _dangGui ? null : _quenMatKhau,
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ),
                    const SizedBox(height: Gap.sm),
                    FilledButton(
                      onPressed: _dangGui ? null : _vao,
                      child: Text(_dangGui ? 'Đang vào…' : 'Đăng nhập'),
                    ),
                    const SizedBox(height: Gap.md),
                    OutlinedButton(
                      onPressed: _dangGui
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const DangKyScreen()),
                              ),
                      child: const Text('Tạo tài khoản mới'),
                    ),
                    const SizedBox(height: Gap.xl),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
                          child: Text('hoặc',
                              style: AppType.ui(12,
                                  color: AppColor.mucNhat, w: FontWeight.w500)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: Gap.md),
                    TextButton.icon(
                      onPressed: _dangGui ? null : () => moDungThu(context),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Xem thử với dữ liệu mẫu'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hộp báo lỗi dùng chung cho các biểu mẫu đăng nhập, đăng ký, nhập mã mời.
class HopLoi extends StatelessWidget {
  const HopLoi(this.chu, {super.key});
  final String chu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: AppColor.butDoNhat,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: AppColor.butDo.withValues(alpha: .3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 17, color: AppColor.butDo),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Text(chu,
                style: AppType.ui(13,
                    color: AppColor.butDo, w: FontWeight.w500, height: 1.45)),
          ),
        ],
      ),
    );
  }
}
