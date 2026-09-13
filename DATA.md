# Tầng dữ liệu

Supabase: Postgres cho dữ liệu, Auth cho đăng nhập, Storage cho ảnh bài làm.
Tất cả lược đồ nằm trong `supabase/`, chạy bằng SQL Editor — xem [README](README.md).

## Nguyên tắc

Đây là nhật ký học tập của trẻ con, nên mặc định là **cấm**. Một người chạm
được vào dữ liệu của học sinh X khi và chỉ khi họ là chính X, là phụ huynh đã
được nối với X, hoặc là quản trị. Ba trường hợp đó gói trong đúng một hàm:

```sql
xem_duoc(p_hoc_sinh uuid)
  → p_hoc_sinh = auth.uid() or la_phu_huynh_cua(p_hoc_sinh) or la_quan_tri()
```

Mọi policy đọc đều gọi nó, nên muốn đổi luật thì sửa một chỗ.

Cả ba hàm trợ giúp đều `security definer`. Nếu không, policy trên `nguoi_dung`
lại phải đọc `nguoi_dung` để biết người gọi có phải quản trị không, và đệ quy
vô hạn.

## Bảng

| Bảng | Giữ gì | Ai ghi |
|---|---|---|
| `nguoi_dung` | Hồ sơ, khóa 1–1 với `auth.users` | Chính chủ (trừ vai trò), quản trị |
| `lien_ket` | Phụ huynh nào theo dõi học sinh nào | Chỉ hàm `dung_ma_moi()` và quản trị |
| `tinh`, `truong` | Danh mục tỉnh và trường — đọc được cả khi chưa đăng nhập, vì màn đăng ký cần | Quản trị |
| `mon_hoc` | Danh mục môn | Quản trị |
| `giao_vien` | Thầy cô. Hàng `chu_id` null là danh mục chung; hàng có `chu_id` là thầy dạy thêm riêng của một học sinh | Quản trị; thầy riêng thì chính em đó và bố mẹ em đó |
| `bai_hoc` | Danh mục bài học theo sách giáo khoa: môn, khối lớp, học kì, chương, thứ tự trong sách, tên, tóm tắt và câu hỏi cho phụ huynh. Nạp từ `09_bai_hoc_lop*.sql` (sinh bởi `tools/bai_hoc/tao_sql.py`); cờ `sua_tay` bật khi quản trị sửa trong app để lần nạp lại không ghi đè | Quản trị |
| `tiet_hoc` | Thời khóa biểu | Học sinh và phụ huynh của em đó |
| `bao_cao` | Báo cáo học tập từng ngày; `bai_hoc_id` trỏ tới bài trong danh mục, null khi không chọn | Học sinh viết, phụ huynh chỉ ghi nhận xét |
| `nhac_nho` | Lời nhắc | Phụ huynh gửi, học sinh đánh dấu đã đọc |
| `ma_moi` | Mã sáu số nối phụ huynh với con | Qua hàm `tao_ma_moi()` |
| `thiet_bi` | Token FCM của từng máy, gắn với người đăng nhập | Chính chủ |
| `thong_bao` | Hàng đợi thông báo đẩy: gửi cho ai, tiêu đề, nội dung, đã gửi chưa | Chỉ trigger; người dùng đọc phần của mình |
| `cau_hinh` | Địa chỉ Edge Function và mã bí mật webhook | Chỉ SQL Editor — không vai trò API nào đọc được |

`thu` đánh số 2..8 đúng cách người Việt gọi, 8 là Chủ nhật.

### Thầy cô gắn với trường thế nào

`giao_vien` có ba cột quyết định ai thấy một hàng — app lọc, còn DB chỉ chặn
phần riêng tư:

- `loai = 'trenLop'` → `truong_id` là trường của thầy. Học sinh khai trường nào
  (`nguoi_dung.truong_id`) thì app chỉ đưa ra thầy cô trường đó. Hàng chưa gắn
  trường (dữ liệu nhập trước khi có danh mục) hiện cho mọi người.
- `loai = 'hocThem'`, `chu_id` null → thầy dạy thêm dùng chung, theo môn.
  `tinh_id` chỉ để lọc: app đưa ra thầy cùng tỉnh với trường của em, hoặc
  không ghi tỉnh.
- `chu_id` có giá trị → thầy dạy thêm riêng của học sinh đó. Policy `gv_doc`
  chỉ cho `xem_duoc(chu_id)` đọc; `gv_ghi` cho quản trị ghi tất cả, còn học
  sinh và bố mẹ chỉ ghi được hàng `hocThem` có `chu_id` là người mình xem được
  — nên không có đường nào tự biến thầy riêng thành thầy chung, hay gán thầy
  cho nhà khác.

`nguoi_dung.truong` (chữ) là cột cũ từ hồi gõ tay tên trường; giữ lại cho tài
khoản cũ và làm chỗ ghi tên để mở bảng ra vẫn đọc được. Trigger đăng ký điền
cả hai: tra `truong_id` trong danh mục (id lạ thì coi như chưa chọn, không làm
hỏng lượt đăng ký) rồi chép tên trường sang cột chữ.

### Thông báo đẩy đi đường nào

Không có gì trong app tự gửi thông báo. Ba trigger `security definer` xếp
hàng vào `thong_bao` — `tb_bao_cao_moi` (con gửi bài → mỗi phụ huynh trong
`lien_ket`), `tb_nhan_xet_moi` (nhận xét đổi và người sửa không phải chính
em → em), `tb_nhac_nho_moi` (lời nhắc → em). Hàm `nhac_toi_chua_viet_bao_cao()`
do pg_cron gọi 20:00 giờ Việt Nam, xếp hàng cho em nào có máy đăng ký mà hôm
đó chưa có báo cáo; `tong_ket_tuan()` chạy 20:00 Chủ nhật, mỗi phụ huynh có
máy nhận một dòng cho từng đứa con (thứ Hai → Chủ nhật: xong bao nhiêu bài,
mấy ngày có báo cáo, tổng giờ học). Người dùng qua API không gọi được hai hàm
này.

Mỗi hàng mới trong `thong_bao` làm trigger `tb_goi_edge_function` (file 07)
gọi Edge Function qua `pg_net`, kèm mã bí mật lấy từ `cau_hinh`. Edge Function
tra `thiet_bi` của `den_id`, gửi qua FCM, rồi ghi `da_gui_luc` và `loi`. Token
hỏng (máy gỡ app) bị xóa ngay lúc đó.

Vì sao có `thiet_bi` mà không nhét token vào `nguoi_dung`: một người nhiều
máy, và policy "chỉ chính chủ ghi" trên bảng riêng chặn được chuyện đăng ký
máy mình dưới tên người khác — đường duy nhất để nhận trộm thông báo (kèm nội
dung báo cáo) của nhà khác.

## Ba chỗ RLS không đủ, phải dùng trigger

RLS so được hàng cũ ở `using` và hàng mới ở `with check`, nhưng **không so được
hai bên với nhau** trong cùng một biểu thức. Ba luật dưới đây cần đúng phép so đó:

- `chan_tu_nang_quyen` — không ai tự đổi `vai_tro` của mình, cũng không tự mở
  lại tài khoản bị khóa. Quản trị thì được.
- `chan_phu_huynh_sua_bao_cao` — phụ huynh qua được policy `bc_sua`, nhưng
  trigger chặn lại nếu họ đụng vào bất cứ cột nào ngoài `nhan_xet_phu_huynh` và
  `phu_huynh_da_xem`. Như dòng chữ đỏ thầy cô ghi cuối trang vở: ghi được lời
  phê, không sửa được bài.
- `chan_sua_noi_dung_nhac_nho` — học sinh đánh dấu đã đọc được, nhưng không sửa
  lại nội dung bố mẹ nhắc, cũng không dời hạn.

Thêm một trigger tiện dụng chứ không phải luật: `danh_dau_bai_hoc_sua_tay` bật
cờ `sua_tay` khi ai đó (không phải SQL Editor) đổi tóm tắt hay câu hỏi của một
bài, để file `09_bai_hoc_lop*.sql` chạy lại chỉ cập nhật những bài chưa ai đụng.

Cả ba đều mở đường cho `la_phia_may_chu()` — `auth.uid() is null`. Trigger chạy
với mọi kết nối, kể cả `postgres`: không có lối thoát này thì chính người quản
trị cũng không phong nổi quản trị đầu tiên từ SQL Editor, vì lúc đó chưa có ai
là quản trị để `la_quan_tri()` đúng. Khách chưa đăng nhập cũng có `auth.uid()`
null, nhưng vai trò `anon` đã bị thu hồi sạch quyền ghi trên mọi bảng ở file 01
(chỉ còn đọc được `tinh` và `truong`) nên không tới được chỗ trigger nổ — `supabase/test/02_nguoi_dung.sql` kiểm đúng điều
này.

Trigger thứ tư, `tao_ho_so_sau_dang_ky` trên `auth.users`, dựng hồ sơ ngay khi
đăng ký và **kẹp vai trò** về `hocSinh` nếu client gửi lên thứ gì khác
`phuHuynh`/`hocSinh`. Nhờ vậy không ai tự nhận là quản trị lúc đăng ký, và hồ sơ
vẫn có kể cả khi bật xác thực email (lúc đó `signUp` chưa trả về phiên nên
client không ghi được gì).

## Mã mời

Học sinh đọc cho bố mẹ một mã sáu số, sống 15 phút, dùng một lần.

Cả hai đầu đều là hàm `security definer`, client không ghi thẳng bảng:

- `tao_ma_moi()` — vô hiệu mã cũ trước, rồi bốc số mới; trùng thì thử lại tới
  tám lần. Mỗi học sinh chỉ có đúng một mã sống, để lỡ đọc nhầm mã cũ cho bố mẹ
  thì cũng không nối vào được.
- `dung_ma_moi(p_ma)` — `select … for update` khóa hàng trong lúc kiểm tra, nên
  hai người cùng nhập một mã thì chỉ người đầu tiên nối được.

Phụ huynh **không có quyền SELECT** trên `ma_moi` và **không có quyền INSERT**
trên `lien_ket`. Đường duy nhất trở thành phụ huynh của một đứa trẻ là gọi hàm
trên với đúng mã, hoặc được quản trị gán tay.

## Ảnh bài làm

Bucket `bai-lam` để **riêng tư**, đường dẫn `{hoc_sinh_id}/{tên tệp}`. Thư mục
đầu tiên chính là id học sinh, nên policy dùng lại đúng `xem_duoc()`.

Supabase chặn `DELETE` thẳng vào `storage.objects` bằng trigger, nổ trước cả
RLS. Đường duy nhất để xóa là Storage API — app vẫn đi đường đó và vẫn bị policy
`anh_xoa` soi, nhưng bộ kiểm thử SQL thì không với tới được, nên phần xóa ảnh
không có phép thử nào.

Bucket riêng tư thì không có URL vĩnh viễn như Firebase. App gọi
`urlAnh()` → `createSignedUrl` mỗi lần hiển thị. Đổi lại, link ảnh vở của con
không rò ra ngoài được.

## Tầng repository

UI không biết gì về Supabase. Nó chỉ thấy `HocTapRepository`:

```
HocTapRepository (interface)
├── SupabaseRepository   ← khi có SUPABASE_URL + khóa
└── MockRepository       ← dữ liệu mẫu trong bộ nhớ, và toàn bộ test Dart
```

`AppState` giữ một `_repo` đổi được, nên chế độ dùng thử chỉ là tráo cài đặt chứ
không phải nhánh `if` rải khắp màn hình.

Model chuyển đổi qua extension `…Pg` với khóa snake_case. Hai hàm riêng —
`NguoiDungPg.toMapCaNhan()` và `BaoCaoPg.toMapNhanXet()` — chỉ gửi lên đúng
những cột được phép ghi, để lệnh ghi hạn chế không vô tình đụng vào cột bảo vệ
và làm trigger ném lỗi.

## Kiểm thử

`supabase/test/` — 93 phép thử phân quyền, chạy thẳng trên dự án
thật và không để lại dấu vết. Xem
[supabase/test/README.md](supabase/test/README.md).

Phía Dart: `flutter test` chạy trên `MockRepository`.
