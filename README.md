# Sổ liên lạc

App Android theo dõi việc học của con, ba vai trò: phụ huynh, học sinh, quản trị.
Học sinh ghi báo cáo học tập mỗi ngày — tách riêng **bài tập trên lớp** và **bài
tập học thêm** theo từng thầy cô — kèm ảnh vở nếu muốn. Phụ huynh đọc, ghi nhận
xét và nhắc con. Cả hai cùng xếp được thời khóa biểu.

Dữ liệu nằm trên **Supabase** (gói miễn phí là đủ). Đóng gói thành APK cài nội
bộ trong nhà, không qua Play Store.

Vài thứ nhỏ nhưng đáng kể: viết báo cáo lúc **mất mạng** vẫn được — bài cất
trên máy, tự gửi khi có sóng; ảnh vở tự nén dưới 500 KB; và **con dấu khen**
tính từ chính báo cáo của con (ba ngày liền xong bài, trọn một tuần, mười giờ
học…), đóng lên màn hình đúng lúc con đạt. Từ bản 0.3, học sinh **chọn bài
trong sách giáo khoa** thay vì gõ tên (app gợi ý sẵn bài kế tiếp), và phụ
huynh đọc được **tóm tắt bài** kèm vài câu hỏi để kiểm tra con — hiện có đủ
lớp 8, bộ "Kết nối tri thức".

Báo cáo không còn là việc điền biểu mẫu mỗi môn. Trang chủ học sinh có
**bảng điểm danh**: mỗi môn trong thời khóa biểu hôm nay là một dòng, môn,
thầy cô đã điền sẵn, bài điền sẵn là bài của lần báo cáo trước (một bài
thường học vài tiết) với nút *Bài tiếp ›* khi lớp sang bài mới — con chỉ bấm
*Chưa làm / Đang làm / Đã xong / Không có bài*, mỗi môn một chạm. Cần ghi chữ
hay chụp ảnh thì mở biểu mẫu đầy đủ, cũng đã điền sẵn; phần chữ không bắt
buộc, có câu mẫu theo từng môn và app tự nhớ những câu con hay ghi.

Để con *muốn* báo cáo: bố mẹ **treo phần thưởng** theo chuỗi ngày trọn bài —
"7 ngày liền → đi ăn kem" — app đếm, con thấy trên trang chủ còn mấy ngày,
bố mẹ trao rồi treo lại. Chuỗi không đứt oan: ngày không có tiết trong thời
khóa biểu không tính, và mỗi tuần con có một **vé nghỉ** tự dùng.

---

## Phần 1 — Dựng cơ sở dữ liệu

Làm một lần, mất chừng mười phút. Không cần cài gì lên máy.

### Bước 1. Tạo dự án

Vào [supabase.com](https://supabase.com) → **Start your project** → đăng nhập
bằng GitHub hoặc email → **New project**.

| Ô | Điền |
|---|---|
| Name | `so-lien-lac` |
| Database Password | Bấm **Generate a password** rồi **lưu lại chỗ nào đó**. Mật khẩu này không xem lại được, và cần tới nếu sau này muốn nối trực tiếp vào database. |
| Region | **Southeast Asia (Singapore)** — gần Việt Nam nhất, app chạy nhẹ hơn hẳn. |
| Plan | **Free** |

Bấm **Create new project** rồi đợi khoảng hai phút cho Supabase dựng xong.

### Bước 2. Chạy các file SQL

Cột trái → **SQL Editor** (biểu tượng terminal) → **New query**.

Mở lần lượt các file dưới đây trong thư mục `supabase/`, mỗi lần dán **toàn bộ**
nội dung một file vào khung soạn thảo rồi bấm **Run** (hoặc `Ctrl+Enter`). Chạy
đúng thứ tự này:

| Thứ tự | File | Dựng gì |
|---|---|---|
| 1 | `01_bang.sql` | Mười bảng: người dùng, liên kết, tỉnh, trường, môn, thầy cô, tiết học, báo cáo, nhắc nhở, mã mời |
| 2 | `02_bao_mat.sql` | Phân quyền — ai đọc được dữ liệu của ai |
| 3 | `03_ma_moi.sql` | Hai hàm sinh và dùng mã mời sáu số |
| 4 | `04_storage.sql` | Kho ảnh bài làm, để riêng tư |
| 5 | `05_danh_muc.sql` | Danh mục mẫu: 1 tỉnh, 1 trường, 12 môn, 8 thầy cô — không bắt buộc, nhập tay trong app cũng được |
| 6 | `06_thong_bao.sql` | Hàng đợi thông báo và luật "ai nhận gì" — chạy luôn dù chưa bật thông báo đẩy. Đã dựng từ trước bản có bảng điểm danh thì chạy lại file này một lần, để thông báo của báo cáo không có chữ vẫn nói được trạng thái và tên bài |
| — | `07_thong_bao_may_chu.sql` | Chỉ chạy khi bật thông báo đẩy, xem Phần 4 |
| 7 | `08_tinh_thanh.sql` | 34 tỉnh, thành phố theo sắp xếp từ 1/7/2025 — để học sinh chọn lúc đăng ký |
| 8 | `09_bai_hoc_lop8.sql` | Danh mục bài học lớp 8 (421 mục, 9 sách) kèm tóm tắt và câu hỏi cho phụ huynh — cần `05_danh_muc.sql` chạy trước vì tham chiếu mã môn `m_toan`, `m_van`… |
| 9 | `10_phan_thuong.sql` | Phần thưởng bố mẹ treo theo chuỗi ngày trọn vẹn ("7 ngày liền → đi ăn kem") |

Mỗi lần chạy xong phải thấy **Success. No rows returned**. Nếu thấy chữ đỏ thì
dừng lại, đừng chạy file tiếp theo — xem bảng lỗi ở cuối trang này.

Cả mười file đều chạy lại được nhiều lần mà không hỏng gì, nên lỡ chạy trùng
cũng không sao.

### Bước 3. Tắt xác nhận email

**Đừng bỏ qua bước này.** Mặc định Supabase bắt bấm vào link trong email trước
khi đăng nhập được — và SMTP tích hợp của gói miễn phí chỉ gửi **2 thư mỗi
giờ**. Đăng ký tới người thứ ba là kẹt, báo `Email rate limit exceeded`, đợi cả
tiếng mới thử lại được.

Tắt đi thì đăng ký không gửi email nữa, hết luôn giới hạn đó.

**Authentication** → **Sign In / Providers** → **Email** → tắt **Confirm email**
→ **Save**.

### Bước 4. Kiểm tra phân quyền

Bước này không bắt buộc nhưng nên làm, vì đây là thứ duy nhất ngăn người lạ đọc
được bài vở của con.

**SQL Editor** → **New query** → dán toàn bộ `supabase/test/KIEM_THU.sql` →
**Run**.

Kết quả hiện ra trong một **khung đỏ** — đó là bình thường, đọc chữ chứ đừng
nhìn màu:

```
KIỂM THỬ PHÂN QUYỀN — tất cả 170 phép thử đều ĐẠT.
```

Còn nếu có chỗ hỏng thì nó liệt kê ra từng cái. Khung đỏ vì bộ test cố ý ném
ngoại lệ ở dòng cuối; đó là cách nó hoàn tác sạch dữ liệu thử, nên chạy trên dự
án thật cũng không để lại một dòng nào.

Chi tiết xem [supabase/test/README.md](supabase/test/README.md).

### Bước 5. Lấy địa chỉ và khóa

Hai giá trị này nằm ở hai trang khác nhau — Supabase mới tách ra.

**Project URL** — **Settings** (bánh răng, dưới cùng cột trái) → **Data API**.
Dạng `https://abcdefgh.supabase.co`. Không cần vào đâu cũng đoán được: phần
`abcdefgh` chính là đoạn mã trong thanh địa chỉ lúc đang mở dự án.

**Publishable key** — **Settings** → **API Keys** → mục **Publishable key**,
dòng `default`, bấm nút copy. Chuỗi bắt đầu bằng `sb_publishable_…` (dự án cũ
thì nằm ở tab **Legacy anon, service_role API keys** và bắt đầu bằng `eyJ…` —
cùng một thứ, Supabase đang đổi tên).

Đừng lấy nhầm **Secret keys** ở ngay bên dưới (`sb_secret_…`, tên cũ là
`service_role`). Khóa đó bỏ qua toàn bộ phân quyền — lọt vào APK là ai gỡ file
ra cũng đọc được dữ liệu của mọi nhà.

Tạo file `.env.json` ở thư mục gốc dự án:

```json
{
  "SUPABASE_URL": "https://abcdefgh.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "eyJhbGciOi..."
}
```

File này đã nằm trong `.gitignore`.

---

## Phần 2 — Chạy thử

```bash
flutter pub get
flutter run --dart-define-from-file=.env.json
```

Không truyền `.env.json` thì app vẫn chạy được bằng **dữ liệu mẫu** trong bộ
nhớ — tiện để xem giao diện, nhưng thoát ra là mất hết.

### Tạo tài khoản quản trị

App chỉ cho đăng ký phụ huynh và học sinh; vai trò quản trị phải phong bằng tay.
Đó là cố ý — nếu không thì ai đăng ký cũng tự nhận là quản trị và đọc được dữ
liệu cả trường.

1. Trong app, đăng ký một tài khoản bình thường bằng email của bạn.
2. Supabase → **SQL Editor** → chạy:

```sql
update nguoi_dung set vai_tro = 'quanTri' where email = 'email-cua-ban@gmail.com';
```

3. Trong app đăng xuất rồi đăng nhập lại. Giờ sẽ thấy ba thẻ quản trị.

### Nhập danh mục: trường, môn, thầy cô

Vai trò quản trị → thẻ **Danh mục**. Ba tab, nút **Thêm** ở góc đổi theo tab
đang mở; chạm vào một mục để sửa hoặc xóa.

- **Trường** — học sinh chọn trường lúc đăng ký (hoặc sau, ở **Tài khoản** →
  chạm dòng *Trường*). Nút bản đồ góc trên quản lý **tỉnh**: tỉnh chỉ để lọc
  danh sách cho gọn khi có nhiều trường, không phải một tầng phân quyền —
  quản trị nào cũng thấy hết.
- **Môn** — không có môn thì học sinh không viết nổi báo cáo đầu tiên. Danh
  mục trống thì có nút *Nạp danh mục mẫu* (12 môn cấp hai).
- **Thầy cô** — hai loại:
  - *Trên lớp*: gắn với **trường** và môn. Học sinh chỉ thấy thầy cô của
    trường mình khi viết báo cáo hay xếp tiết.
  - *Dạy thêm*: chỉ cần môn, có thể ghi tỉnh để lọc. Đây là thầy dùng chung;
    còn thầy dạy thêm riêng của từng nhà thì **học sinh (hoặc bố mẹ) tự
    thêm** — ngay trong ô chọn thầy cô lúc viết báo cáo, hoặc ở **Tài khoản**
    → *Thầy cô dạy thêm*. Thầy riêng chỉ nhà đó và quản trị thấy.

Tài khoản đăng ký từ trước khi có danh mục vẫn hiện tên trường gõ tay; vào
**Tài khoản** chọn lại trường một lần là xong.

### Danh mục bài học theo sách giáo khoa

Từ năm học 2026–2027 cả nước dùng chung bộ **Kết nối tri thức với cuộc sống**,
nên danh mục chỉ có một bộ sách. Khối lớp của học sinh suy từ tên lớp em khai
("8A4" → lớp 8); khối nào có dữ liệu thì khi viết báo cáo, dưới ô môn học hiện
thêm ô **Bài học trong sách**: chạm để tìm (gõ "bài 6", "phân số"…), hoặc bấm
gợi ý *Bài kế tiếp* — bài đứng ngay sau bài gần nhất em đã ghi cho môn đó.
Không chọn cũng được, báo cáo vẫn gửi bình thường.

Phụ huynh mở báo cáo thấy tấm **bài học**: tên bài, vài dòng tóm tắt và mấy
câu *Hỏi con thử* — đáp án giấu sau một cái chạm.

Dữ liệu nằm ở `tools/bai_hoc/lop8/*.txt` (mỗi sách một file, dạng chữ dễ
sửa), sinh thành `supabase/09_bai_hoc_lop8.sql` bằng:

```
python tools/bai_hoc/tao_sql.py
```

Tên bài lấy theo mục lục sách; tóm tắt và câu hỏi do tôi viết từ mục lục và
yêu cầu cần đạt của Chương trình GDPT 2018 (Thông tư 32/2018) — chưa phải
lời sách, nên chỗ nào thấy chưa ổn thì quản trị sửa ngay trong app: thẻ
**Danh mục** → tab **Bài học** → chọn lớp, môn → chạm vào bài. Bài đã sửa
tay được đánh dấu, chạy lại file SQL không ghi đè. Muốn thêm khối khác: tạo
thư mục `tools/bai_hoc/lop9/`, viết theo cùng dạng, chạy script rồi chạy
file SQL sinh ra.

### Nối phụ huynh với con

Hai đường, dùng đường nào cũng được:

- **Mã mời** — máy con: **Hồ sơ** → **Tạo mã mời**, hiện ra sáu số, sống 15 phút.
  Máy bố mẹ: **Hồ sơ** → **Nhập mã mời**. Mỗi mã dùng đúng một lần.
- **Quản trị gán tay** — vai trò quản trị → **Người dùng** → chọn phụ huynh →
  **Nối với học sinh**.

---

## Phần 3 — Đóng gói APK cài nội bộ

### Tạo khóa ký

Android không cho cài APK chưa ký. Tự ký là đủ, chỉ cần làm một lần:

```bash
keytool -genkey -v -keystore android/so-lien-lac.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias so-lien-lac
```

Nó hỏi mật khẩu và vài dòng thông tin — điền gì cũng được, nhưng **giữ lại file
`.jks` và mật khẩu**. Mất thì các máy đã cài sẽ không nhận được bản cập nhật
nữa, phải gỡ ra cài lại từ đầu và mất hết dữ liệu cục bộ.

Tạo `android/key.properties`:

```properties
storePassword=mật-khẩu-vừa-đặt
keyPassword=mật-khẩu-vừa-đặt
keyAlias=so-lien-lac
storeFile=../so-lien-lac.jks
```

Cả hai file đều đã nằm trong `.gitignore`.

### Build

```bash
python tools/dong_goi.py
```

Script build ba file rồi **tự kiểm từng file** — số mục trong zip, manifest,
quyền INTERNET, chữ ký — và từ chối nếu có file hỏng. Đừng build tay bằng
`flutter build apk --split-per-abi`: AGP 9 có lỗi làm APK arm64 ra thiếu toàn
bộ tài nguyên nhưng vẫn được ký, nhìn ngoài không biết.

| File | Cỡ | Gửi cho ai |
|---|---|---|
| `app-release.apk` | ~54 MB | Không rõ máy gì — cài đâu cũng chạy |
| `app-arm64-v8a-release.apk` | ~19 MB | Máy từ 2017 trở đi |
| `app-armeabi-v7a-release.apk` | ~17 MB | Máy cũ 32-bit |

Đều ở `build/app/outputs/flutter-apk/`. Gửi qua Zalo hay chép bằng USB sang máy
cần cài.

Mỗi máy chỉ dùng **một loại file** từ đầu đến cuối. Bản tách kiến trúc mang mã
phiên bản lớn hơn bản gộp (Flutter cộng thêm 1000 hoặc 2000), nên máy đã cài
bản tách mà sau đó cài bản gộp thì Android coi là hạ cấp và từ chối.

Trên máy nhận, lần đầu Android sẽ hỏi cho phép cài ứng dụng từ nguồn này —
**Cài đặt** → **Vẫn cài**.

> Lần build đầu Gradle phải tải vài trăm MB thư viện. Mạng chậm thì việc này lâu
> hơn cả phần còn lại cộng lại; cứ để chạy nền.

---

## Phần 4 — Thông báo đẩy (không bắt buộc)

Con gửi báo cáo → máy bố mẹ rung. Bố mẹ nhắc nhở hay ghi nhận xét → máy con
rung. 20:00 con chưa viết báo cáo → nhắc con. 20:00 Chủ nhật → bố mẹ nhận một
dòng tổng kết tuần của từng đứa (*"Xong 18/21 bài · có báo cáo 6/7 ngày"*).
Không bật thì app vẫn chạy đủ, chỉ là phải mở app mới thấy.

Dữ liệu vẫn nằm hết trên Supabase. Firebase ở đây chỉ làm đúng một việc: đưa
tin xuống điện thoại — trên Android không có đường nào khác để đánh thức một
app đã tắt. Cả hai bên đều trong gói miễn phí.

```
bao_cao / nhac_nho có hàng mới ──trigger──▶ hàng đợi `thong_bao`
pg_cron 20:00 (HS chưa viết bài) ──────────▶ (den_id, tiêu đề, nội dung)
                                                   │ webhook (pg_net)
                                                   ▼
                                      Edge Function gui-thong-bao
                                      đọc token của den_id → FCM → máy
```

### Bước 1. Tạo project Firebase — 5 phút

1. [console.firebase.google.com](https://console.firebase.google.com) →
   **Add project** → đặt tên tùy ý → tắt Google Analytics (không cần) → tạo.
2. Trong project: **Add app** → biểu tượng Android → *Android package name*
   nhập đúng `vn.hoctap.theodoi_hoctap` → **Register app**.
3. **Download google-services.json** → đặt vào `android/app/google-services.json`.
   File này đã nằm trong `.gitignore`; thiếu nó app vẫn build, chỉ không có
   thông báo đẩy.
4. Bánh răng → **Project settings** → tab **Service accounts** →
   **Generate new private key** → tải file JSON về. Đây là khóa để máy chủ
   gửi tin, **không** đưa vào app, không commit.

### Bước 2. Tạo Edge Function trên Supabase

1. Supabase → **Edge Functions** → **Deploy a new function** → *Via Editor*
   → tên `gui-thong-bao` → dán toàn bộ
   [`supabase/functions/gui-thong-bao/index.ts`](supabase/functions/gui-thong-bao/index.ts)
   → **Deploy**.
2. **Nhìn cột URL** trong danh sách function và bấm nút copy. Deploy qua
   Editor thì Supabase tự đặt đường dẫn ngẫu nhiên kiểu
   `…/functions/v1/dynamic-processor` — cái tên `gui-thong-bao` chỉ là nhãn
   hiển thị, không phải địa chỉ. Địa chỉ này dùng ở bước 3; ghi nhầm
   `/gui-thong-bao` thì mọi lời gọi đều 404 và không có gì tới máy.
3. Mở function vừa tạo → **Details** → **tắt "Verify JWT"**. Trigger trong
   Postgres gọi thẳng, không có JWT; xác thực bằng mã bí mật ở bước sau.
4. **Edge Functions** → **Secrets** → thêm hai secret:
   - `FCM_SERVICE_ACCOUNT` — dán **nguyên nội dung** file JSON tải ở bước 1.4.
   - `MA_BI_MAT_WEBHOOK` — một chuỗi ngẫu nhiên dài, tự nghĩ (ví dụ 32 ký tự
     lẫn chữ và số). Nhớ lại để dùng ở bước 3.

Có Supabase CLI thì thay bằng
`supabase functions deploy gui-thong-bao --no-verify-jwt` và
`supabase secrets set FCM_SERVICE_ACCOUNT="$(cat khoa.json)" MA_BI_MAT_WEBHOOK=...`
— deploy bằng CLI thì đường dẫn đúng là `/functions/v1/gui-thong-bao`.

### Bước 3. Nối Postgres với Edge Function

Mở `supabase/07_thong_bao_may_chu.sql`, sửa hai dòng đầu:

```sql
('url_gui_thong_bao', '<địa chỉ copy ở bước 2.2>'),
('ma_bi_mat_webhook', '<chuỗi bí mật ở bước 2.4>')
```

Rồi dán cả file vào **SQL Editor** → **Run**. File này bật hai
extension `pg_net` và `pg_cron`, đặt lịch nhắc 20:00 mỗi tối và tổng kết tuần
20:00 Chủ nhật (13:00 UTC).

### Bước 4. Build lại app

`google-services.json` chỉ được đọc lúc build, nên build lại APK (Phần 3) và
cài đè. Mở app, đăng nhập — Android 13 trở lên sẽ hỏi quyền hiện thông báo,
bấm **Cho phép**. Máy nào đăng nhập rồi là tự đăng ký nhận; đăng xuất thì tự
gỡ.

### Thử

Máy con viết một báo cáo → máy bố mẹ phải rung trong vài giây. Không thấy gì
thì vào **SQL Editor**:

```sql
select tao_luc, tieu_de, da_gui_luc, loi from thong_bao order by tao_luc desc limit 10;
```

| Thấy gì | Nghĩa là | Làm gì |
|---|---|---|
| Không có hàng nào | Trigger chưa có | Chạy lại `06_thong_bao.sql` |
| Có hàng, `da_gui_luc` trống | Edge Function chưa được gọi tới — thường là sai địa chỉ | Chạy `select status_code, left(content, 100) from net._http_response order by created desc limit 5;` — thấy `404` thì `url_gui_thong_bao` trong `cau_hinh` không khớp cột **URL** của function (bước 2.2); sửa xong chạy `select tb_goi_lai(id) from thong_bao where da_gui_luc is null;` |
| `loi` = `người nhận chưa có máy nào đăng ký` | Máy bố mẹ chưa đăng nhập lại sau khi cài bản mới | Đăng xuất, đăng nhập lại; từ chối quyền thông báo thì cũng vào đây |
| `loi` = `401 …` | Mã bí mật hai bên khác nhau | So `MA_BI_MAT_WEBHOOK` với hàng `ma_bi_mat_webhook` |
| `loi` = `403 …` hoặc `PERMISSION_DENIED` | Service account chưa có quyền gửi | Firebase → Project settings → Cloud Messaging → bật **Firebase Cloud Messaging API (V1)** |
| Máy Xiaomi/Oppo/Vivo không rung dù `loi` trống | Hãng chặn app chạy nền | Cài đặt → Ứng dụng → Sổ liên lạc → bật *Tự khởi động*, tắt *Tối ưu pin* |

Gửi lại những hàng chưa đi: `select tb_goi_lai(id) from thong_bao where da_gui_luc is null;`

---

## Phần 5 — Bản web trên GitHub Pages

Cùng mã nguồn, chạy được trong trình duyệt (máy tính hoặc điện thoại, thêm
vào màn hình chính như một app). Giao diện tự xếp theo bề ngang: điện thoại
có thanh điều hướng dưới; cửa sổ từ 720 px có thanh bên trái; từ 1100 px
nội dung xếp hai cột (bộ khung ở `lib/core/layout/`). Khác bản cài: chưa có
thông báo đẩy, và bài viết lúc mất mạng chỉ giữ trong phiên đang mở chứ
không cất xuống máy.

Nhánh trên GitHub:

| Nhánh | Dùng cho |
|---|---|
| `master` | Mã nguồn chung — mọi thay đổi làm ở đây |
| `mobile` | Bản cài điện thoại: mỗi lần phát hành APK thì gộp `master` vào đây rồi chạy `python tools/dong_goi.py` |
| `web` | Bản web: đẩy lên nhánh này là GitHub tự build và đưa lên Pages (`.github/workflows/web.yml`) |

Phát hành bản web mới:

```bash
git checkout web
git merge master
git push
```

Vài phút sau trang ở `https://<tài-khoản>.github.io/<tên-repo>/` đổi theo.
Lần đầu cần ba việc trong Settings của repo trên GitHub:

1. **Pages** → Source chọn **GitHub Actions**.
2. **Secrets and variables → Actions** → thêm `SUPABASE_URL` và
   `SUPABASE_PUBLISHABLE_KEY` (đúng hai giá trị trong `.env.json`). Thiếu thì
   bản web vẫn lên nhưng chạy bằng dữ liệu mẫu.
3. Repo phải **public** — tài khoản GitHub miễn phí không bật được Pages cho
   repo private.

Nếu tài khoản GitHub chưa chạy được Actions (tab Actions báo *You can't
perform that action at this time* — GitHub khóa với tài khoản mới hoặc chưa
xác minh), vẫn đưa web lên được từ máy mình, không qua Actions:

```bash
python tools/dua_len_web.py
```

Script build web, đẩy sản phẩm lên nhánh `gh-pages` và trỏ Pages vào nhánh
đó. Lúc này Pages ở chế độ *Deploy from a branch*; khi Actions chạy được thì
đổi lại Source = **GitHub Actions** để nhánh `web` tự deploy.

Chạy web tại máy để xem trước: `flutter run -d chrome --dart-define-from-file=.env.json`.

## Khi có lỗi

| Hiện tượng | Nguyên nhân | Cách xử lý |
|---|---|---|
| `relation "nguoi_dung" does not exist` | Chạy `02_bao_mat.sql` trước `01_bang.sql` | Chạy lại từ file 01 theo đúng thứ tự |
| `permission denied for schema auth` | Đang dùng công cụ nối ngoài chứ không phải SQL Editor | Dán vào SQL Editor trên trang Supabase |
| Đăng ký xong không đăng nhập được | Chưa tắt **Confirm email** | Bước 3 |
| `Email rate limit exceeded` | Chưa tắt **Confirm email**, đã hết 2 thư/giờ | Bước 3, rồi đăng ký lại ngay |
| `Email address … is invalid` | Tên miền mail tạm bị chặn | Dùng tên miền thật; `ten+hs1@gmail.com` cũng được |
| Đăng nhập xong màn hình trắng | Hồ sơ chưa được tạo | Kiểm tra `02_bao_mat.sql` đã chạy chưa — trigger tạo hồ sơ nằm ở cuối file đó |
| App vẫn hiện dữ liệu mẫu | Thiếu `--dart-define-from-file` | Kiểm tra `.env.json` và câu lệnh chạy |
| `Mã mời không đúng hoặc đã hết hạn` | Mã sống 15 phút và dùng một lần | Bảo con tạo mã mới |
| Phụ huynh không thấy gì | Chưa nối với con | Nhập mã mời, hoặc quản trị gán tay |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Máy đang có bản ký bằng khóa khác | Gỡ bản cũ rồi cài lại |

Xem thêm [DESIGN.md](DESIGN.md) về giao diện và [DATA.md](DATA.md) về dữ liệu.
