import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/ngay.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/trang_vo.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';
import 'soan_nhac_nho.dart';

/// Dòng nhắc nhở giữa phụ huynh và học sinh. Phụ huynh thấy lời mình đã gửi
/// kèm việc con đã đọc chưa; học sinh thấy lời nhắc gửi cho mình.
class NhacNhoScreen extends StatelessWidget {
  const NhacNhoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final laPhuHuynh = s.nguoiDung?.vaiTro == VaiTro.phuHuynh;
    final ds = s.nhacNho;
    final ten = s.hocSinhHienTai?.tenGoi ?? 'con';

    return Scaffold(
      appBar: AppBar(
        title: Text(laPhuHuynh ? 'Nhắc nhở đã gửi' : 'Nhắc nhở'),
        actions: [
          if (laPhuHuynh)
            Padding(
              padding: const EdgeInsets.only(right: Gap.lg),
              child: TextButton.icon(
                onPressed: () => moSoanNhacNho(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nhắc'),
              ),
            ),
        ],
      ),
      body: ds.isEmpty
          ? TrangTrong(
              icon: Icons.campaign_outlined,
              tieuDe: laPhuHuynh ? 'Chưa có lời nhắc nào' : 'Chưa có lời nhắc nào',
              moTa: laPhuHuynh
                  ? 'Khi $ten còn bài chưa làm hoặc quên báo cáo, gửi một lời nhắc — nó hiện ngay trên app của con.'
                  : 'Khi bố mẹ nhắc gì, lời nhắc sẽ xuất hiện ở đây.',
              hanhDong: laPhuHuynh
                  ? FilledButton.icon(
                      onPressed: () => moSoanNhacNho(context),
                      icon: const Icon(Icons.campaign_rounded, size: 18),
                      label: Text('Nhắc $ten'),
                    )
                  : null,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xxl),
              itemCount: ds.length,
              separatorBuilder: (_, _) => const SizedBox(height: Gap.md),
              itemBuilder: (_, i) => _TheNhacNho(nn: ds[i], laPhuHuynh: laPhuHuynh),
            ),
    );
  }
}

class _TheNhacNho extends StatelessWidget {
  const _TheNhacNho({required this.nn, required this.laPhuHuynh});

  final NhacNho nn;
  final bool laPhuHuynh;

  @override
  Widget build(BuildContext context) {
    final quaHan = nn.hanLuc != null && nn.hanLuc!.isBefore(DateTime.now()) && !nn.daDoc;
    final mauLe = nn.daDoc
        ? AppColor.dongKeDam
        : (quaHan ? AppColor.butDo : AppColor.muc);

    return TrangVo(
      mauLe: mauLe,
      keNgang: false,
      vienNoiBat: !nn.daDoc,
      le: Icon(
        nn.daDoc ? Icons.mark_email_read_rounded : Icons.campaign_rounded,
        size: 18,
        color: mauLe,
      ),
      onTap: laPhuHuynh || nn.daDoc
          ? null
          : () => context.read<AppState>().docNhacNho(nn.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  laPhuHuynh ? 'Bạn đã gửi' : 'Bố mẹ nhắc',
                  style: AppType.ui(12, w: FontWeight.w700, color: mauLe),
                ),
              ),
              Text(
                Ngay.truoc(nn.taoLuc),
                style: AppType.ui(11.5, color: AppColor.mucNhat, w: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text(
            nn.noiDung,
            style: AppType.ui(14, w: FontWeight.w400, height: 1.55),
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              if (nn.hanLuc != null) ...[
                Icon(Icons.alarm_rounded, size: 13, color: quaHan ? AppColor.butDo : AppColor.mucNhat),
                const SizedBox(width: 4),
                Text(
                  quaHan ? 'Quá hạn ${Ngay.gio(nn.hanLuc!)}' : 'Hạn ${Ngay.gio(nn.hanLuc!)}',
                  style: AppType.ui(11.5,
                      w: FontWeight.w600,
                      color: quaHan ? AppColor.butDo : AppColor.mucNhat),
                ),
                const SizedBox(width: Gap.md),
              ],
              Icon(
                nn.daDoc ? Icons.done_all_rounded : Icons.done_rounded,
                size: 13,
                color: nn.daDoc ? AppColor.xong : AppColor.mucNhat,
              ),
              const SizedBox(width: 4),
              Text(
                nn.daDoc
                    ? (laPhuHuynh ? 'Con đã đọc' : 'Đã đọc')
                    : (laPhuHuynh ? 'Chưa đọc' : 'Chạm để đánh dấu đã đọc'),
                style: AppType.ui(11.5,
                    color: nn.daDoc ? AppColor.xong : AppColor.mucNhat, w: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
