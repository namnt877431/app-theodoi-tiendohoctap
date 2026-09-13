import 'models/models.dart';

/// Lời ghi vào báo cáo khi em bấm "Không có bài" — hôm đó môn không giao gì,
/// nên coi như xong; bố mẹ đọc chữ này là hiểu, không phải đoán.
const noiDungKhongCoBai = 'Không có bài tập';

/// Một dòng trên bảng điểm danh: một môn có tiết hôm nay mà em chưa báo cáo.
/// Mọi thứ trừ trạng thái đều lấy sẵn từ thời khóa biểu, nên em chỉ còn phải
/// trả lời "làm tới đâu rồi".
class MucDiemDanh {
  const MucDiemDanh({
    required this.monId,
    required this.loai,
    required this.tiet,
    this.giaoVienId,
    this.baiHoc,
    this.baiTiep,
  });

  final String monId;
  final LoaiBaiTap loai;

  /// Tiết đầu tiên của môn trong ngày — ghi bên lề như tờ thời khóa biểu.
  final int tiet;
  final String? giaoVienId;

  /// Bài lớp đang học — bài của lần báo cáo trên lớp gần nhất — điền sẵn
  /// cho dòng này; null khi môn không có danh mục hay chưa ghi bài nào.
  final BaiHoc? baiHoc;

  /// Bài đứng sau [baiHoc] trong sách, cho nút "Bài tiếp"; null khi hết sách.
  final BaiHoc? baiTiep;

  /// Hai dòng cùng môn nhưng một trên lớp, một học thêm là hai việc khác nhau.
  (String, LoaiBaiTap) get khoa => (monId, loai);
}

/// Gom tiết trong ngày thành các dòng điểm danh, bỏ những môn đã có báo cáo.
///
/// Các tiết cùng môn, cùng hạng mục gộp làm một — Văn học hai tiết liền vẫn
/// chỉ có một bài về nhà. Thứ tự giữ theo [tietHomNay] (đã xếp theo buổi rồi
/// tiết, nên học thêm buổi tối nằm cuối). Thầy cô lấy ở tiết đầu tiên có
/// ghi tên. Bài chỉ điền sẵn cho tiết trên lớp: thầy dạy thêm ra đề, chuyên
/// đề theo ý mình, không đi theo thứ tự sách.
List<MucDiemDanh> tinhMucDiemDanh(
  List<TietHoc> tietHomNay,
  List<BaoCao> baoCaoHomNay, {
  BaiHoc? Function(String monId)? baiDangHoc,
  BaiHoc? Function(BaiHoc bh)? baiSau,
}) {
  final daBao = {for (final b in baoCaoHomNay) (b.monId, b.loai)};
  final theoKhoa = <(String, LoaiBaiTap), MucDiemDanh>{};
  for (final t in tietHomNay) {
    final khoa = (t.monId, t.loai);
    if (daBao.contains(khoa)) continue;
    final cu = theoKhoa[khoa];
    if (cu == null) {
      final bai = t.loai == LoaiBaiTap.trenLop ? baiDangHoc?.call(t.monId) : null;
      theoKhoa[khoa] = MucDiemDanh(
        monId: t.monId,
        loai: t.loai,
        tiet: t.tiet,
        giaoVienId: t.giaoVienId,
        baiHoc: bai,
        baiTiep: bai == null ? null : baiSau?.call(bai),
      );
    } else if (cu.giaoVienId == null && t.giaoVienId != null) {
      theoKhoa[khoa] = MucDiemDanh(
        monId: cu.monId,
        loai: cu.loai,
        tiet: cu.tiet,
        giaoVienId: t.giaoVienId,
        baiHoc: cu.baiHoc,
        baiTiep: cu.baiTiep,
      );
    }
  }
  return theoKhoa.values.toList();
}
