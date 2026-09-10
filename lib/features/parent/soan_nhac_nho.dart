import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';

/// Mở bảng soạn nhắc nhở. Có sẵn vài câu hay dùng để phụ huynh chạm một cái
/// là gửi được, khỏi phải gõ lúc đang bận.
Future<void> moSoanNhacNho(BuildContext context, {String? goiY, String? baoCaoId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: _SoanNhacNho(goiY: goiY, baoCaoId: baoCaoId),
    ),
  );
}

class _SoanNhacNho extends StatefulWidget {
  const _SoanNhacNho({this.goiY, this.baoCaoId});
  final String? goiY;
  final String? baoCaoId;

  @override
  State<_SoanNhacNho> createState() => _SoanNhacNhoState();
}

class _SoanNhacNhoState extends State<_SoanNhacNho> {
  late final _c = TextEditingController(text: widget.goiY ?? '');
  TimeOfDay? _han;
  bool _dangGui = false;

  static const _mau = [
    'Còn bài chưa làm, con làm nốt rồi báo cáo nhé.',
    '9 giờ tối nhớ gửi báo cáo cho bố mẹ.',
    'Chụp ảnh bài làm gửi bố mẹ xem với.',
    'Bài thầy cô dạy thêm giao, con làm trước khi đi học nhé.',
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    final noiDung = _c.text.trim();
    if (noiDung.isEmpty) return;
    setState(() => _dangGui = true);

    DateTime? han;
    if (_han != null) {
      final n = DateTime.now();
      han = DateTime(n.year, n.month, n.day, _han!.hour, _han!.minute);
      if (han.isBefore(n)) han = han.add(const Duration(days: 1));
    }

    await context.read<AppState>().guiNhacNho(noiDung, hanLuc: han, baoCaoId: widget.baoCaoId);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi nhắc nhở')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ten = context.read<AppState>().hocSinhHienTai?.tenGoi ?? 'con';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColor.giayTrang,
          borderRadius: BorderRadius.vertical(top: Radius.circular(R.lg + 4)),
        ),
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.lg),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColor.dongKeDam,
                    borderRadius: BorderRadius.circular(R.pill),
                  ),
                ),
              ),
              const SizedBox(height: Gap.lg),
              TieuDeMuc('Nhắc $ten', eyebrow: 'Gửi ngay lên app của con'),
              const SizedBox(height: Gap.lg),
              TextField(
                controller: _c,
                autofocus: true,
                maxLines: 3,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: AppType.ui(14.5, height: 1.5, w: FontWeight.w400),
                decoration: const InputDecoration(
                  hintText: 'Con làm nốt bài Tiếng Anh rồi báo cáo nhé…',
                ),
              ),
              const SizedBox(height: Gap.md),
              Eyebrow('Câu hay dùng'),
              const SizedBox(height: Gap.sm),
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  for (final m in _mau)
                    ActionChip(
                      label: Text(m.length > 34 ? '${m.substring(0, 32)}…' : m),
                      onPressed: () => setState(() => _c.text = m),
                    ),
                ],
              ),
              const SizedBox(height: Gap.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _han ?? const TimeOfDay(hour: 20, minute: 0),
                        );
                        if (t != null) setState(() => _han = t);
                      },
                      icon: const Icon(Icons.alarm_rounded, size: 18),
                      label: Text(_han == null
                          ? 'Đặt giờ nhắc'
                          : '${_han!.hour.toString().padLeft(2, '0')}:${_han!.minute.toString().padLeft(2, '0')}'),
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _dangGui ? null : _gui,
                      child: Text(_dangGui ? 'Đang gửi…' : 'Gửi nhắc nhở'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
