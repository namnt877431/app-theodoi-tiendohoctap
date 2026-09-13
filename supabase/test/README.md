# Kiểm thử phân quyền

184 phép thử. Bộ này kiểm cái mà app không kiểm được: giả sử có người moi khóa
publishable ra khỏi file APK rồi gọi thẳng API, họ chạm được tới đâu. Câu trả
lời phải là "chỉ dữ liệu của chính mình", và đó là việc của RLS chứ không phải
của Flutter.

## Cách chạy

1. Chạy xong `01_bang.sql` → `06_thong_bao.sql`, `10_phan_thuong.sql` và `11_diem_thi.sql` trước đã (`07_thong_bao_may_chu.sql` không cần).
2. Supabase → **SQL Editor** → **New query** → dán toàn bộ `KIEM_THU.sql` → **Run**.
3. Đọc thông báo hiện ra.

Kết quả luôn hiện dưới dạng **khung lỗi màu đỏ** — đó là bình thường, đọc chữ
chứ đừng nhìn màu:

```
KIỂM THỬ PHÂN QUYỀN — tất cả 184 phép thử đều ĐẠT.
```

hoặc, khi có chỗ hỏng:

```
KIỂM THỬ PHÂN QUYỀN — 148 đạt, 2 TRƯỢT trên tổng 160.
  ✗ PH không tự đánh dấu bài con là đã xong — lẽ ra bị chặn, nhưng đã đụng tới 1 hàng
  ✗ HS không tự phong mình làm quản trị — lẽ ra bị chặn, nhưng đã đụng tới 1 hàng
```

## Vì sao cả bộ là một câu lệnh `DO`

Không phải để cho gọn. SQL Editor của Supabase tách script thành từng câu lệnh
rồi gửi qua connection pooler. Mở `begin` tường minh thì mọi thứ chưa commit
nằm lại trên một kết nối, còn câu lệnh kế tiếp rơi sang kết nối khác và không
nhìn thấy gì — kể cả bảng vừa tạo xong ở dòng trên. Một câu lệnh thì không tách
được.

Hệ quả: không dùng được `rollback`. Nên bộ test kết thúc bằng một ngoại lệ cố ý
— đó là cách duy nhất hoàn tác sạch dữ liệu thử. Chạy trên dự án thật không để
lại một dòng nào.

## Các file

`KIEM_THU.sql` là các file dưới đây nối lại, sinh bằng `python gop.py`. Sửa file
lẻ rồi chạy lại script đó, đừng sửa thẳng file nối.

| File | Nội dung |
|---|---|
| `00_dau.sql` | Mở khối `DO`, khai báo biến, dựng tỉnh/trường và 5 tài khoản mẫu — đồng thời kiểm trigger tạo hồ sơ sau đăng ký (kể cả gắn trường) |
| `01_nguoi_dung.sql` | Ai đọc/sửa được hồ sơ ai; tự nâng quyền; tự mở khóa; khách vãng lai |
| `02_lien_ket.sql` | Bảng nối phụ huynh–con: không ai tự chèn được một dòng |
| `03_bao_cao.sql` | Báo cáo là lời của học sinh; phụ huynh chỉ ghi được nhận xét |
| `04_tkb_nhac_nho.sql` | Thời khóa biểu; mạo danh người gửi; chỉ học sinh đánh dấu đã đọc |
| `05_kho_anh.sql` | Ảnh bài làm không rò ra ngoài gia đình |
| `06_danh_muc.sql` | Tỉnh, trường công khai nhưng chỉ quản trị sửa; thầy cô chung ai cũng thấy, thầy riêng chỉ nhà mình thấy và tự thêm được |
| `07_thong_bao.sql` | Thông báo đẩy: máy của ai người đó đăng ký; hàng đợi chỉ trigger ghi và xếp đúng người — con gửi bài → bố mẹ, bố mẹ nhận xét/nhắc → con |
| `07b_phan_thuong.sql` | Phần thưởng: bố mẹ treo dưới tên mình, trao, xóa; con chỉ nhìn |
| `07c_diem_thi.sql` | Sổ điểm: con và bố mẹ ghi/sửa/xóa, thang 10 hoặc Đ/CĐ (đúng một), đúng bốn cột; người lạ không thấy |
| `08_chay.sql` | Vòng lặp chạy bảng phép thử ở trên |
| `10_ma_moi.sql` | Mã mời — viết tay vì phải bắt lấy mã vừa sinh rồi mang đi dùng lại |
| `11_theo_lich.sql` | Đợt nhắc 20:00 và tổng kết tuần — viết tay vì chạy với vai máy chủ như pg_cron |
| `12_cuoi.sql` | Tổng kết và ngoại lệ hoàn tác |

## Thêm một phép thử

Chèn một dòng vào file `01`–`07c`, đúng năm cột:

```sql
    ('PH lạ không xóa được liên kết của nhà khác',   -- tên hiện trong báo cáo
     '22222222-2222-2222-2222-222222222222'::uuid,  -- đóng vai ai, null là khách
     'chan',                                        -- thay | duoc | chan
     $q$delete from lien_ket
         where phu_huynh_id = '11111111-1111-1111-1111-111111111111'$q$,
     0),                                            -- số hàng mong thấy
```

- **thay** — truy vấn phải trả về đúng số hàng ghi ở cột cuối
- **duoc** — câu lệnh phải chạy trót lọt
- **chan** — câu lệnh phải bị chặn. Ghi 0 hàng cũng tính là bị chặn: RLS lọc
  hàng ra khỏi tầm nhìn thì `UPDATE` và `DELETE` không báo lỗi, chúng chỉ lặng
  lẽ không đụng tới gì.

Thứ tự các dòng có ý nghĩa — vài phép thử dựa vào thay đổi của phép trước. Và
nhớ: trigger chỉ nổ khi giá trị mới **khác** giá trị cũ, nên phép thử "không
được đổi X" phải đổi X sang một giá trị thật sự khác, nếu không nó tự đánh lừa
mình.
