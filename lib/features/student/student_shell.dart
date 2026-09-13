import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/layout/khung_dieu_huong.dart';
import '../../data/app_state.dart';
import '../parent/nhac_nho_screen.dart';
import '../shared/ho_so_screen.dart';
import '../shared/soan_bao_cao_screen.dart';
import '../shared/thoi_khoa_bieu_screen.dart';
import 'lich_su_bao_cao_screen.dart';
import 'trang_chu_hs_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final chuaDoc = context.select<AppState, int>((s) => s.soNhacNhoChuaDoc);

    return KhungDieuHuong(
      tab: _tab,
      onChon: (i) => setState(() => _tab = i),
      hanhDong: HanhDongChinh(
        icon: Icons.edit_rounded,
        nhan: 'Viết báo cáo',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SoanBaoCaoScreen()),
        ),
      ),
      hienHanhDongO: const {0, 2},
      diemDen: [
        const DiemDen(icon: Icons.today_outlined, iconChon: Icons.today_rounded, nhan: 'Hôm nay'),
        const DiemDen(
            icon: Icons.grid_view_outlined, iconChon: Icons.grid_view_rounded, nhan: 'Thời khóa biểu'),
        const DiemDen(icon: Icons.article_outlined, iconChon: Icons.article_rounded, nhan: 'Báo cáo'),
        DiemDen(
            icon: Icons.campaign_outlined,
            iconChon: Icons.campaign_rounded,
            nhan: 'Nhắc nhở',
            huyHieu: chuaDoc),
        const DiemDen(
            icon: Icons.person_outline_rounded, iconChon: Icons.person_rounded, nhan: 'Tài khoản'),
      ],
      man: const [
        TrangChuHsScreen(),
        ThoiKhoaBieuScreen(),
        LichSuBaoCaoScreen(),
        NhacNhoScreen(),
        HoSoScreen(),
      ],
    );
  }
}
