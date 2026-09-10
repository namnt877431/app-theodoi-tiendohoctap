# Tầng dữ liệu

## Nguyên tắc

Màn hình không bao giờ gọi thẳng Firebase. Mọi thứ đi qua interface
[`HocTapRepository`](lib/data/repositories/hoc_tap_repository.dart), có hai bản
cài đặt:

| Bản | Dùng khi | File |
|---|---|---|
| `MockRepository` | Xem thử giao diện, và chạy test không cần mạng | [mock_repository.dart](lib/data/repositories/mock_repository.dart) |
| `FirebaseRepository` | Chạy thật trên Auth + Firestore + Storage | [firebase_repository.dart](lib/data/repositories/firebase_repository.dart) |

[`main.dart`](lib/main.dart) tự chọn: `Firebase.initializeApp()` chạy được thì
dùng Firebase, không thì rơi về dữ liệu mẫu. Nhờ vậy người mới clone repo mở
app được ngay, còn khi đã cấu hình xong thì tự chuyển sang dữ liệu thật.

## Sơ đồ Firestore

```
nguoiDung/{uid}
    hoTen, vaiTro, email, soDienThoai, lop, truong, conIds[], hoatDong
    maMoiDaDung          ← bằng chứng nối tài khoản, xem phần Mã mời

monHoc/{id}              ten, vietTat
giaoVien/{id}            hoTen, monId, loai, noiDay, soDienThoai

hocSinh/{hsId}/tietHoc/{id}
    thu (2..8), tiet, buoi, monId, giaoVienId, loai, phong, batDau, ketThuc

hocSinh/{hsId}/baoCao/{id}
    ngay, khoaNgay, loai, monId, giaoVienId, noiDung, trangThai,
    anh[], soPhut, nhanXetPhuHuynh, phuHuynhDaXem, taoLuc

hocSinh/{hsId}/nhacNho/{id}
    tuId, denId, noiDung, taoLuc, hanLuc, daDoc, baoCaoId

maMoi/{ma}               hocSinhId, hetHan, daDung
```

Storage: `baiLam/{hocSinhId}/{tên tệp}.jpg`

**Vì sao dữ liệu học tập nằm dưới `hocSinh/{hsId}`:** để luật bảo mật chỉ cần
một phép kiểm tra ở cấp thư mục — người đọc phải là chính học sinh đó, hoặc là
phụ huynh có `hsId` trong `conIds`, hoặc là quản trị. Nếu để phẳng ở một
collection chung thì mỗi lần đọc phải kiểm tra từng bản ghi.

**`khoaNgay`** là chuỗi `"2026-09-10"` lưu song song với `ngay`. Truy vấn "báo
cáo của ngày X" nhờ vậy chỉ là một phép so sánh bằng, không phải dựng chỉ mục
cho khoảng thời gian.

## Nối phụ huynh với con — mã mời

Học sinh bấm **Tạo mã mời** ở trang Tài khoản, được một mã sáu số sống 15 phút
và chỉ dùng được một lần. Đọc mã cho bố mẹ nhập vào app của họ.

Điểm nhạy cảm: nếu chỉ để client tự ghi `conIds`, bất kỳ ai cũng thêm được id
học sinh lạ vào danh sách của mình và đọc trọn dữ liệu của đứa trẻ đó.

Cách bịt, không cần Cloud Function (tức là chạy được trên gói Spark miễn phí):
khi nối, client ghi kèm `maMoiDaDung` vào chính hồ sơ của mình. Luật bảo mật
tự đối chiếu — xem hàm `themConHopLe` trong [firestore.rules](firestore.rules):

- có đúng một id được thêm vào `conIds`
- id đó phải bằng `maMoi/{maMoiDaDung}.hocSinhId`
- mã đó phải chưa dùng và chưa hết hạn

Server không tin lời client nói "tôi là phụ huynh của em này"; nó tự kiểm tra
người gửi có thật sự cầm mã do con sinh ra hay không.

Quản trị vẫn gán tay được qua màn **Người dùng → Liên kết con**, vì luật cho
quản trị ghi thẳng.

## Ai được đọc gì

| Dữ liệu | Học sinh | Phụ huynh đã nối | Quản trị |
|---|---|---|---|
| Hồ sơ của mình | đọc, sửa | đọc, sửa | đọc, sửa tất cả |
| Hồ sơ học sinh | — | đọc | đọc |
| Thời khóa biểu | đọc, sửa | đọc, sửa | đọc, sửa |
| Báo cáo | đọc, viết, xóa | đọc, chỉ sửa `nhanXetPhuHuynh` và `phuHuynhDaXem` | tất cả |
| Nhắc nhở | đọc, chỉ sửa `daDoc` | đọc, tạo, xóa lời mình gửi | tất cả |
| Môn học, thầy cô | đọc | đọc | ghi |
| Ảnh bài làm | đọc, tải lên, xóa | đọc | đọc, xóa |

Vài chi tiết cố ý:

- **Báo cáo là lời của học sinh.** Phụ huynh không sửa được nội dung, không đổi
  được trạng thái. Họ chỉ viết nhận xét — đúng như dòng chữ đỏ thầy cô ghi cuối
  trang vở.
- **`daDoc` chỉ học sinh đặt được.** Phụ huynh không tự đánh dấu hộ, nếu không
  cái dấu "con đã đọc" chẳng còn nghĩa gì.
- **Không ai tự phong quản trị.** Luật chặn `vaiTro == 'quanTri'` lúc đăng ký;
  tài khoản quản trị tạo tay trong Firebase Console rồi sửa `vaiTro` trong
  Firestore.
- **Không ai tự mở khóa cho mình.** `hoatDong` nằm ngoài danh sách trường mà
  người dùng được sửa.

## Ảnh bài làm

Ảnh chụp xong nằm ở máy dưới dạng đường dẫn cục bộ. Lúc lưu báo cáo,
`AppState.luuBaoCao` đưa những tấm chưa có đường dẫn mạng lên Storage rồi thay
bằng URL tải về. Sửa lại một báo cáo cũ không tải lên lần nữa những tấm đã nằm
sẵn trên kho.

Xóa báo cáo thì xóa ảnh trước rồi mới xóa bản ghi — làm ngược lại mà nửa chừng
hỏng thì ảnh nằm lại trong kho không còn ai biết đường dẫn để dọn.

## Lỗi

`FirebaseRepository` bắt `FirebaseAuthException` và dịch sang câu người dùng
đọc được, gói trong `LoiHocTap`. Màn hình chỉ việc hiện `loi.thongDiep`, không
phải đoán mã lỗi tiếng Anh. Thêm một mã lỗi mới thì sửa đúng một chỗ:
hàm `_dichLoiAuth`.

## Dữ liệu cũ

`enumTu` cho giá trị enum lạ rơi về mặc định thay vì ném lỗi, và `ngayTu` đọc
được cả `Timestamp`, `DateTime`, chuỗi ISO lẫn số mili-giây. Nghĩa là đổi tên
một hạng mục về sau sẽ không làm sập app của người chưa cập nhật.

## Kiểm chứng

Luật bảo mật không được tin vì nó "trông có vẻ đúng". [test_rules/](test_rules/)
chạy chúng trên Firestore Emulator với ba nhân vật — phụ huynh đã nối, phụ huynh
lạ, và quản trị — rồi kiểm tra từng đường: đọc báo cáo, sửa nhận xét, đánh dấu
đã đọc, nối tài khoản bằng mã mời, tự nâng quyền.

```bash
cd test_rules && npm install && npm test
```
