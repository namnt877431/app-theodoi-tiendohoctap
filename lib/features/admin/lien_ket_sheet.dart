import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';

/// Nối một phụ huynh với các học sinh mà họ được phép theo dõi.
/// Đây là thao tác quản trị nhạy cảm nhất nên mỗi lần bật/tắt đều lưu ngay
/// và hiện lại trạng thái thật, không gom vào một nút "Lưu" mơ hồ.
Future<void> moLienKet(BuildContext context, NguoiDung phuHuynh) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: _LienKet(phuHuynh: phuHuynh),
    ),
  );
}

class _LienKet extends StatefulWidget {
  const _LienKet({required this.phuHuynh});
  final NguoiDung phuHuynh;

  @override
  State<_LienKet> createState() => _LienKetState();
}

class _LienKetState extends State<_LienKet> {
  late final Set<String> _dangChon = {...widget.phuHuynh.conIds};
  List<NguoiDung> _hocSinh = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tai());
  }

  Future<void> _tai() async {
    final ds = await context.read<AppState>().repo.danhSachNguoiDung();
    if (!mounted) return;
    setState(() => _hocSinh = ds.where((n) => n.vaiTro == VaiTro.hocSinh).toList());
  }

  Future<void> _doi(NguoiDung hs, bool bat) async {
    final repo = context.read<AppState>().repo;
    if (bat) {
      await repo.lienKet(widget.phuHuynh.id, hs.id);
    } else {
      await repo.huyLienKet(widget.phuHuynh.id, hs.id);
    }
    if (!mounted) return;
    setState(() => bat ? _dangChon.add(hs.id) : _dangChon.remove(hs.id));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .8),
      decoration: const BoxDecoration(
        color: AppColor.giayTrang,
        borderRadius: BorderRadius.vertical(top: Radius.circular(R.lg + 4)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                widget.phuHuynh.hoTen,
                eyebrow: 'Chọn học sinh phụ huynh này được theo dõi',
              ),
            ),
            const SizedBox(height: Gap.lg),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
                itemCount: _hocSinh.length,
                separatorBuilder: (_, _) => const SizedBox(height: Gap.sm),
                itemBuilder: (_, i) {
                  final hs = _hocSinh[i];
                  final chon = _dangChon.contains(hs.id);
                  return Material(
                    color: chon ? AppColor.sky.withValues(alpha: .6) : AppColor.giayTrang,
                    borderRadius: BorderRadius.circular(R.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(R.md),
                      onTap: () => _doi(hs, !chon),
                      child: Ink(
                        padding: const EdgeInsets.all(Gap.md),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(R.md),
                          border: Border.all(
                            color: chon ? AppColor.muc.withValues(alpha: .4) : AppColor.dongKe,
                            width: chon ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            AvatarChu(hs.hoTen, kichThuoc: 40),
                            const SizedBox(width: Gap.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(hs.hoTen, style: AppType.ui(14, w: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('Lớp ${hs.lop}',
                                      style: AppType.ui(11.5,
                                          color: AppColor.mucNhat, w: FontWeight.w500)),
                                ],
                              ),
                            ),
                            Icon(
                              chon
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 21,
                              color: chon ? AppColor.muc : AppColor.dongKeDam,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Xong'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
