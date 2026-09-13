import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/layout/khung_dieu_huong.dart';
import '../../data/app_state.dart';
import '../shared/ho_so_screen.dart';
import '../shared/thoi_khoa_bieu_screen.dart';
import 'bao_cao_ph_screen.dart';
import 'trang_chu_ph_screen.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final chuaDoc = context.select<AppState, int>((s) => s.soNhacNhoChuaDoc);

    return KhungDieuHuong(
      tab: _tab,
      onChon: (i) => setState(() => _tab = i),
      diemDen: [
        const DiemDen(icon: Icons.today_outlined, iconChon: Icons.today_rounded, nhan: 'Hôm nay'),
        const DiemDen(
            icon: Icons.grid_view_outlined, iconChon: Icons.grid_view_rounded, nhan: 'Thời khóa biểu'),
        DiemDen(
            icon: Icons.article_outlined,
            iconChon: Icons.article_rounded,
            nhan: 'Báo cáo',
            huyHieu: chuaDoc),
        const DiemDen(
            icon: Icons.person_outline_rounded, iconChon: Icons.person_rounded, nhan: 'Tài khoản'),
      ],
      man: const [
        TrangChuPhScreen(),
        ThoiKhoaBieuScreen(),
        BaoCaoPhScreen(),
        HoSoScreen(),
      ],
    );
  }
}
