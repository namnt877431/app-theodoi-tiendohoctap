# Hệ thiết kế — Sổ liên lạc

## Ý tưởng chủ đạo

App này không phải dashboard. Nó là **quyển sổ liên lạc** mà phụ huynh Việt Nam
đã ký hằng tuần suốt mấy chục năm, cộng với **tờ thời khóa biểu dán cánh tủ**.
Toàn bộ ngôn ngữ thị giác lấy từ hai vật đó: giấy kẻ ngang, lề đỏ, mực Cửu Long,
bút đỏ chấm bài.

Người dùng chính là phụ huynh mở app lúc 9–10 giờ tối với đúng một câu hỏi trong
đầu: *hôm nay con học thế nào?* Mọi quyết định thiết kế đều phục vụ việc trả lời
câu đó trong một cái liếc mắt.

## Signature — đường lề mang nghĩa

Mỗi mục báo cáo là một **trang vở** (`TrangVo` trong `lib/core/widgets/trang_vo.dart`):
dòng kẻ ngang mờ, và một đường lề dọc bên trái.

Đường lề đó **không phải trang trí — màu của nó chính là trạng thái**:

| Màu lề | Nghĩa | Hex |
|---|---|---|
| Xanh lá | Đã xong | `#1E9E6A` |
| Hổ phách | Đang làm dở | `#E0912B` |
| Đỏ | Chưa làm | `#D64545` |

Nhờ vậy phụ huynh nhận ra bài nào còn dở **trước cả khi kịp đọc chữ**. Trang trí
và thông tin là một thứ, không phải hai.

Cùng nguyên tắc đó lặp lại ở màn nhắc nhở (lề đỏ = chưa đọc) và màn quản trị
(lề đỏ = tài khoản bị khóa, lề hổ phách = chưa liên kết).

## Bảng màu

Xanh–trắng cho giáo dục, nhưng không dùng xanh Material mặc định `#2196F3`.

```
ink       #0E2E52   mực đậm — chữ tiêu đề, bìa sổ, nền thanh nổi bật
muc       #1D5FA8   mực Cửu Long — màu chủ đạo, hành động chính
mucNhat   #5B7CA3   chữ phụ, biểu tượng không nhấn
sky       #E8F1FA   nền chip, vùng chọn
skySoft   #F3F8FD   nền toàn màn hình
giay      #FBFCFE   giấy — nền thẻ (hơi lạnh, không trắng tinh)
dongKe    #DDE7F2   dòng kẻ trên trang vở
butDo     #D64545   bút đỏ chấm bài — chỉ dùng cho việc chưa làm / cảnh báo
xong      #1E9E6A   đã xong
dangLam   #E0912B   đang làm
hocThem   #7A5AF8   bài học thêm — tách khỏi bài trên lớp
```

Đỏ xuất hiện rất tiết chế và luôn có nghĩa. Nó là nét bút của thầy cô, không
phải màu nhấn.

## Chữ

| Vai trò | Font | Vì sao |
|---|---|---|
| Toàn bộ giao diện | **Be Vietnam Pro** | Font vẽ riêng cho tiếng Việt: dấu đặt đúng chỗ, không đè lên chữ hoa như phần lớn font Latin. Nội dung app 100% tiếng Việt nên đây là lựa chọn bắt buộc, không phải sở thích. |
| Tiêu đề lớn | **Bricolage Grotesque** | Lấy cá tính cho vài chỗ thật sự cần, dùng rất hạn chế. Có `fontFamilyFallback` về Be Vietnam Pro để dấu không bao giờ vỡ. |
| Con số | Be Vietnam Pro + `tabularFigures` | Giờ giấc và số liệu canh cột đều nhau trong lưới thời khóa biểu. |

Thang cỡ chữ và nhãn eyebrow in hoa (`AppType.eyebrow`) gánh việc phân tầng —
không dùng đổ bóng.

## Nhịp và hình khối

- Giãn cách theo nhịp 4pt (`Gap.xs` … `Gap.xxl`).
- Chiều cao dòng kẻ `lineHeight = 28`. Ô nhập báo cáo và trang vở đều bám nhịp này.
- Bán kính bo góc giữ nhỏ (6 / 10 / 14): **vở không bo góc tròn**. Không có gì
  bo dạng viên thuốc trừ thanh tiến độ.
- Viền hairline thay cho đổ bóng ở gần như mọi nơi.

## Cấu trúc mang thông tin

- **Lưới thời khóa biểu** giữ đúng hình dạng tờ TKB thật: hàng là tiết, cột là
  Thứ Hai → Chủ nhật, cột tiết ghim bên trái, phần còn lại cuộn ngang. Không đổi
  thành danh sách agenda, vì hình dạng bảng chính là thứ phụ huynh đã quen đọc.
- **Buổi học thêm tách riêng** khỏi lưới, vì nó không nằm trong khung tiết của
  trường và phụ huynh theo dõi nó theo *người dạy* chứ không theo tiết.
- **Thanh phân đoạn** trên trang chủ: mỗi bài tập là một vạch riêng, tô màu theo
  trạng thái — thay cho một con số phần trăm bắt người đọc tự nhẩm.
- **Bảng điểm danh** trên trang chủ học sinh (`DiemDanhHomNay`): mỗi môn trong
  thời khóa biểu hôm nay là một dòng, số tiết ghim bên lề như tờ TKB, và bốn ô
  trạng thái để chạm. Không ô nào được chọn sẵn — "Đã xong" phải là câu trả
  lời của con, không phải cái có sẵn để bấm Gửi cho xong. Mọi thứ khác (môn,
  thầy cô, bài) app điền từ dữ liệu đã có; con chỉ trả lời hai câu app không
  tự biết: hôm nay cô sang bài mới chưa ("Bài tiếp ›"), và làm tới đâu rồi.
  Bài điền sẵn là *bài hôm trước* chứ không phải bài kế tiếp: một bài trong
  sách học vài tiết, đoán "kế tiếp" là dữ liệu chạy trước lớp.
- **Phần thưởng** (`KhungPhanThuong`) là quà thật do bố mẹ treo, app chỉ đếm
  ngày — không có điểm ảo, không có cửa hàng trong app. Con nhìn thấy đúng
  một câu: "còn 3 ngày nữa". Chuỗi có **vé nghỉ** (`LuatChuoi`): ngày không có
  tiết không tính, mỗi tuần được bỏ một ngày học — một chuỗi hai mươi ngày
  đứt vì đi chơi cuối tuần là thứ giết động lực nhanh nhất. Không thưởng riêng
  "Đã xong" ở đâu khác ngoài chuỗi, để con không có lý do bấm cho qua.

## Chữ nghĩa trong giao diện

- Tiêu đề trang chủ là **một câu trả lời**, không phải một con số:
  "Còn 1 bài chưa làm", "Xong hết bài hôm nay rồi".
- Nút nói đúng việc nó làm: "Gửi báo cáo cho bố mẹ", không phải "Gửi".
- Màn hình rỗng là lời mời làm việc: "Viết báo cáo đầu tiên của hôm nay".
- Xưng hô đúng ngữ cảnh gia đình Việt: app gọi phụ huynh là "bạn", gọi học sinh
  qua tên gọi ("Nhắc Khôi"), và trong lời nhắc thì dùng "bố mẹ".

## Sàn chất lượng

- Cỡ chữ hệ thống được kẹp trong khoảng 0.9–1.3 để bố cục không vỡ khi người
  dùng lớn tuổi phóng to chữ.
- Vùng chạm tối thiểu 42–50px ở mọi nút.
- Chuyển động tiết chế: thanh phân đoạn chạy vào khi mở trang, chuyển màn bằng
  fade. Không có gì nhấp nháy hay trôi nổi.
