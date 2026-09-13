import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';

/// Tấm "bài hôm nay học gì" trong chi tiết báo cáo: tên bài, vài dòng tóm
/// tắt cho bố mẹ nắm được, và mấy câu để hỏi con — đáp án giấu sau một
/// cái chạm, để câu hỏi là của bố mẹ chứ không phải đọc đáp án cho con chép.
class TheBaiHoc extends StatefulWidget {
  const TheBaiHoc(this.bh, {super.key, this.laPhuHuynh = false});

  final BaiHoc bh;
  final bool laPhuHuynh;

  @override
  State<TheBaiHoc> createState() => _TheBaiHocState();
}

class _TheBaiHocState extends State<TheBaiHoc> {
  final _daMo = <int>{};

  @override
  Widget build(BuildContext context) {
    final bh = widget.bh;
    final coHoi = bh.kiemTra.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md + 2, Gap.lg, Gap.lg),
      decoration: BoxDecoration(
        color: AppColor.skySoft,
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: AppColor.dongKe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.menu_book_rounded, size: 18, color: AppColor.muc),
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bh.chuong != null) ...[
                      Text(
                        bh.chuong!,
                        style: AppType.ui(11.5, color: AppColor.mucNhat, w: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(bh.ten, style: AppType.ui(15.5, w: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          if (bh.coTomTat)
            Text(
              bh.tomTat!,
              style: AppType.ui(14, w: FontWeight.w400, height: 1.55, color: AppColor.ink),
            )
          else
            Text(
              'Bài này chưa có tóm tắt.',
              style: AppType.ui(13.5, color: AppColor.mucNhat, w: FontWeight.w500),
            ),
          if (coHoi) ...[
            const SizedBox(height: Gap.lg),
            Eyebrow(widget.laPhuHuynh ? 'Hỏi con thử' : 'Tự kiểm tra'),
            const SizedBox(height: Gap.sm),
            for (var i = 0; i < bh.kiemTra.length; i++) ...[
              _CauHoi(
                thu: i + 1,
                chuoi: bh.kiemTra[i],
                daMo: _daMo.contains(i),
                onMo: () => setState(() => _daMo.add(i)),
              ),
              if (i < bh.kiemTra.length - 1) const SizedBox(height: Gap.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _CauHoi extends StatelessWidget {
  const _CauHoi({
    required this.thu,
    required this.chuoi,
    required this.daMo,
    required this.onMo,
  });

  final int thu;
  final String chuoi;
  final bool daMo;
  final VoidCallback onMo;

  @override
  Widget build(BuildContext context) {
    final (:hoi, :dap) = tachCauHoi(chuoi);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColor.sky, shape: BoxShape.circle),
          child: Text('$thu', style: AppType.numeric(11, color: AppColor.muc)),
        ),
        const SizedBox(width: Gap.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hoi, style: AppType.ui(14, w: FontWeight.w500, height: 1.45)),
              if (dap != null)
                daMo
                    ? Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          'Gợi ý: $dap',
                          style: AppType.ui(13, color: AppColor.xong, w: FontWeight.w600, height: 1.4),
                        ),
                      )
                    : InkWell(
                        onTap: onMo,
                        borderRadius: BorderRadius.circular(R.sm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            'Xem gợi ý đáp án',
                            style: AppType.ui(12.5, color: AppColor.muc, w: FontWeight.w600),
                          ),
                        ),
                      ),
            ],
          ),
        ),
      ],
    );
  }
}
