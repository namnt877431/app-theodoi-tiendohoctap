# Sổ liên lạc — app theo dõi tiến độ học tập

App Android (Flutter) cho ba vai trò: **phụ huynh**, **học sinh**, **quản trị**.

- **Phụ huynh** xem báo cáo học tập từng ngày của con, tách theo hạng mục *bài tập
  trên lớp* và *bài tập học thêm* (gom tiếp theo từng thầy cô), nhập/sửa thời khóa
  biểu, và gửi nhắc nhở lên app của con.
- **Học sinh** nhập thời khóa biểu, viết báo cáo hằng ngày kèm ảnh bài làm (không
  bắt buộc), cập nhật trạng thái, và đọc lời nhắc của bố mẹ.
- **Quản trị** quản lý tài khoản, khóa/mở, liên kết phụ huynh với học sinh, và
  xem danh mục môn học cùng thầy cô.

Hướng thiết kế và lý do đằng sau từng quyết định: [DESIGN.md](DESIGN.md).
Sơ đồ dữ liệu, phân quyền, cách mã mời hoạt động: [DATA.md](DATA.md).

## Xem thử ngay, chưa cần Firebase

```bash
flutter pub get
flutter run -d chrome    # xem nhanh trên trình duyệt
flutter run              # cắm máy Android hoặc mở emulator
```

Chưa cấu hình Firebase thì app tự chạy bằng dữ liệu mẫu trong bộ nhớ. Ở màn
đăng nhập, bấm **Xem thử với dữ liệu mẫu** rồi chọn vai trò là vào thẳng — dữ
liệu lớp 9A2, hai tuần báo cáo, tám thầy cô trong đó ba người dạy thêm. Có dải
nhắc "Đang xem thử" ở đầu màn hình, và mọi thay đổi mất khi tắt app.

Lần chạy đầu cần mạng vì `google_fonts` tải font về máy.

## Trạng thái

Đã có design system, toàn bộ màn hình cho ba vai trò, và tầng dữ liệu chạy trên
Firebase (Auth email/mật khẩu, Firestore, Storage cho ảnh bài làm).

Chưa làm: thông báo đẩy khi phụ huynh gửi nhắc nhở — cần Cloud Function, xem
phần [Chi phí](#chi-phí).

---

# Dựng Firebase từ đầu

Làm một lần, mất khoảng 20 phút. Cần một tài khoản Google và Node.js (máy đã có).

> **Không tìm thấy mục nào trong Console?** Firebase đổi bố cục menu khá thường
> xuyên, nên tên nhóm dưới đây có thể lệch. Đường đi không bao giờ hỏng là ô
> **Search for products** ở góc trên bên trái: gõ `Firestore`, `Authentication`
> hay `Storage` là tới thẳng.

## Bước 0 — Cài hai công cụ dòng lệnh

```bash
npm install -g firebase-tools
firebase login

dart pub global activate flutterfire_cli
```

`firebase login` mở trình duyệt cho bạn đăng nhập Google. Nếu gõ `flutterfire`
mà máy báo không tìm thấy lệnh, thêm đường dẫn này vào PATH:

- Windows: `%LOCALAPPDATA%\Pub\Cache\bin`
- macOS / Linux: `$HOME/.pub-cache/bin`

Firebase CLI cần **JDK 21 trở lên** cho phần emulator. Máy đã cài Android Studio
thì dùng JDK có sẵn trong đó:

```bash
export JAVA_HOME="/c/Program Files/Android/Android Studio/jbr"
export PATH="$JAVA_HOME/bin:$PATH"
```

## Bước 1 — Tạo project

1. Mở <https://console.firebase.google.com> → **Add project**.
2. Đặt tên, ví dụ `so-lien-lac`. Console tự sinh một **Project ID** kiểu
   `so-lien-lac-a1b2c` ở ngay dưới ô tên — **ghi lại chuỗi này**, các lệnh sau
   dùng tới nó và về sau không đổi được.
3. Trang Google Analytics: **tắt đi**. App này không dùng, bật vào chỉ thêm một
   bước tạo tài khoản Analytics.
4. Bấm **Create project**, đợi khoảng một phút.

Tạo xong, Console lập tức mời bạn **"Add Firebase to your Android app"** với ô
*Android package name*. **Bỏ qua màn này** — bấm dấu **X** góc trên bên trái.

Đó là đường đăng ký app bằng tay. `flutterfire configure` ở bước 5 làm đúng
việc đó giúp bạn, lại còn sinh thêm `firebase_options.dart` mà màn này không
tạo. Làm tay ở đây chỉ tốn thêm công chứ không thay thế được lệnh kia.

*(Nếu vẫn muốn đăng ký tay: package name là `vn.hoctap.theodoi_hoctap`.)*

## Bước 2 — Tạo Firestore Database

Đây là nơi chứa hồ sơ, thời khóa biểu, báo cáo và nhắc nhở.

1. Menu trái → **Databases & Storage** → **Firestore** → **Create database**.
2. **Chọn `Start in production mode`**, không chọn test mode.

   Test mode mở toang cho cả thiên hạ đọc ghi trong 30 ngày. Đây là dữ liệu học
   tập của trẻ con, và ở bước 5 mình sẽ đẩy bộ luật riêng lên thay thế.
   Production mode chặn hết cho tới lúc đó, đúng như mong muốn.

3. **Location: `asia-southeast1 (Singapore)`** — gần Việt Nam nhất nên độ trễ
   thấp nhất. Chọn xong **không đổi được nữa**, muốn đổi phải tạo project mới.
4. **Enable**.

Xong bước này, vào tab **Data** sẽ thấy một database rỗng. Đừng tạo collection
bằng tay — app tự tạo khi có người đăng ký tài khoản đầu tiên.

## Bước 3 — Bật đăng nhập bằng email

1. Menu trái → **Security** → **Authentication** → **Get started**.
2. Tab **Sign-in method**. Console bày ra một lưới provider chia ba cột —
   *Native providers*, *Additional providers*, *Custom providers*. Cái cần dùng
   là ô **đầu tiên** của cột **Native providers**: **Email/Password**
   (biểu tượng phong bì).
3. Bấm vào ô đó, panel mở ra với hai công tắc:
   - **Email/Password** → gạt sang **Enable** ✅
   - **Email link (passwordless sign-in)** → **để nguyên tắt** ❌
4. **Save**. Quay lại tab này sẽ thấy Email/Password nằm trong danh sách đã bật,
   trạng thái *Enabled*.

Đừng bật Google, Facebook hay Phone. App chỉ dùng email và mật khẩu; mỗi
provider bật thừa là một đường vào phải lo bảo mật mà chẳng ai dùng.

## Bước 4 — Tạo Storage cho ảnh bài làm

1. Menu trái → **Databases & Storage** → **Storage** → **Get started**.
2. Chọn **production mode**, và **cùng location `asia-southeast1`** với Firestore.

**Nếu Console bắt nâng lên gói Blaze mới cho tạo bucket:** Firebase đã đổi chính
sách này với project mới, nên khả năng cao bạn sẽ gặp. Hai đường đi:

- **Nâng Blaze.** Vẫn miễn phí trong hạn mức Spark cũ, nhưng phải gắn thẻ. Vào
  **Usage and billing → Budgets & alerts** đặt ngưỡng cảnh báo để khỏi giật mình.
- **Bỏ qua Storage.** App chạy bình thường, chỉ riêng chức năng chụp ảnh bài làm
  là không dùng được — nó vốn đã là tuỳ chọn. Khi ấy bước 5 bỏ phần `storage`
  trong lệnh deploy.

## Bước 5 — Nối app với project

Chạy ở thư mục gốc dự án:

```bash
flutterfire configure
```

Nó hỏi ba thứ:

| Câu hỏi | Chọn |
|---|---|
| Select a Firebase project | project vừa tạo ở bước 1 |
| Which platforms | `android` (thêm `web` nếu muốn chạy trên trình duyệt) |
| Android application id | để nguyên `vn.hoctap.theodoi_hoctap` |

Lệnh này sinh ra `lib/firebase_options.dart`, `android/app/google-services.json`
và tự thêm plugin Google Services vào Gradle. Cả ba đều nằm trong `.gitignore`
vì chúng gắn với project riêng của bạn.

Không phải sửa dòng code nào: [main.dart](lib/main.dart) gọi
`Firebase.initializeApp()` trong một khối `try` — cấu hình chạy được thì nó dùng
Firebase, không thì rơi về dữ liệu mẫu.

## Bước 6 — Đẩy luật bảo mật lên

```bash
firebase use --add          # chọn project, đặt bí danh "default"
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Không có Storage thì bỏ phần `,storage` ở cuối.

**Đừng bỏ qua bước này.** Production mode ở bước 2 đang chặn *tất cả*, kể cả app
của bạn — chưa deploy rules thì đăng nhập xong sẽ báo `permission-denied`. Bộ
luật trong [firestore.rules](firestore.rules) mới là thứ mở đúng những cánh cửa
cần mở. Ai đọc được gì: xem bảng trong [DATA.md](DATA.md).

## Bước 7 — Chạy thử

```bash
flutter run
```

Giờ màn đầu tiên là **Đăng nhập** thật, không còn dải "Đang xem thử". Bấm
**Tạo tài khoản mới**, chọn vai trò **Phụ huynh**, điền email và mật khẩu.

Vào lại Console kiểm tra: **Authentication → Users** có một dòng, và
**Firestore → Data** có collection `nguoiDung` với đúng một tài liệu. Nếu cả hai
đều có, tầng dữ liệu đã thông.

## Bước 8 — Tạo tài khoản quản trị

Luật bảo mật cố tình không cho ai tự đăng ký làm quản trị, nên người đầu tiên
phải phong bằng tay:

1. Console → **Firestore Database** → **Data** → mở `nguoiDung` → chọn tài liệu
   vừa tạo ở bước 7 (id của nó là UID bên tab Authentication).
2. Sửa trường `vaiTro` từ `phuHuynh` thành `quanTri`.
3. Trong app: đăng xuất rồi đăng nhập lại — sẽ vào giao diện quản trị.

## Bước 9 — Nạp danh mục môn học

Firestore đang trống nên chưa có môn nào, mà không có môn thì học sinh không
viết nổi báo cáo đầu tiên.

Đăng nhập bằng tài khoản quản trị → tab **Môn & thầy cô** → **Nạp danh mục mẫu**.
Bộ chuẩn gồm 12 môn cấp hai và 8 thầy cô mẫu; sửa lại cho khớp trường mình.

## Bước 10 — Nối phụ huynh với con

1. Học sinh đăng ký tài khoản riêng (vai trò **Học sinh**), vào **Tài khoản** →
   **Tạo mã mời** → đọc sáu số cho bố mẹ.
2. Phụ huynh vào **Tài khoản** → **Thêm con** → nhập mã.

Mã sống 15 phút và chỉ dùng được một lần. Quản trị cũng gán tay được trong
**Người dùng → Liên kết con**.

## Gặp lỗi thì tra ở đây

| Triệu chứng | Nguyên nhân thường gặp |
|---|---|
| App vẫn hiện dải **"Đang xem thử"** sau khi cấu hình xong | `Firebase.initializeApp()` ném lỗi nên app rơi về dữ liệu mẫu. Xem log chạy, [main.dart](lib/main.dart) in ra lý do cụ thể. Hay gặp nhất là chưa chạy lại `flutter run` sau `flutterfire configure` — bước đó đổi file Gradle nên phải build lại, hot reload không đủ. |
| `No Firebase App '[DEFAULT]' has been created` | Chưa chạy `flutterfire configure`, hoặc thiếu `android/app/google-services.json`. |
| Đăng nhập báo **"Cách đăng nhập này chưa được bật"** | Quên bước 3 — chưa bật Email/Password trong Authentication. |
| `permission-denied` ngay sau khi đăng nhập | Chưa deploy rules (bước 6). Production mode chặn tất cả cho tới khi bộ luật riêng được đẩy lên. |
| Đăng nhập báo **"Tài khoản này chưa có hồ sơ"** | Đăng ký lúc rules chưa deploy: người dùng được tạo bên Authentication nhưng hồ sơ Firestore bị chặn. Deploy rules xong, xóa user đó trong **Authentication → Users**, rồi đăng ký lại. |
| Quản trị vẫn thấy giao diện phụ huynh | Sửa `vaiTro` xong phải đăng xuất rồi đăng nhập lại; vai trò đọc một lần lúc mở phiên. |
| Nhập mã mời báo **"Mã mời không đúng"** dù vừa tạo | Mã cũ bị vô hiệu khi học sinh bấm tạo mã lần nữa. Đọc lại mã đang hiện trên màn hình con. |
| Tải ảnh lên thất bại | Chưa tạo Storage, hoặc chưa deploy `storage.rules`. |
| `flutterfire: command not found` | Thiếu thư mục pub-cache trong PATH, xem bước 0. |
| Build Android tải Gradle rất chậm | Lần build đầu Gradle tự tải bản phân phối ~130 MB từ `services.gradle.org`, cộng thêm SDK Firebase cho Android từ Maven. Đây là chi phí một lần, các lần sau lấy từ cache trong `~/.gradle`. |

## Chi phí

Không dùng Cloud Functions — việc kiểm tra mã mời làm bằng luật bảo mật chứ
không bằng code chạy trên server, nên phần Firestore và Auth nằm gọn trong hạn
mức miễn phí. Ảnh nén còn 70% chất lượng trước khi tải lên và chặn ở 8 MB mỗi tấm.

Hai chỗ có thể phải lên gói Blaze:

- **Storage** cho ảnh bài làm — xem ghi chú ở bước 4.
- **Thông báo đẩy** khi phụ huynh gửi nhắc nhở. Hiện nhắc nhở chỉ hiện trong
  app; muốn đẩy ra ngoài thì thêm `firebase_messaging` và một Cloud Function.

## Cấu trúc

```
lib/
  core/
    theme/      tokens.dart (màu, nhịp, bán kính) · typography.dart · app_theme.dart
    widgets/    trang_vo.dart (trang vở có lề mang nghĩa) · common.dart
    utils/      ngay.dart (định dạng ngày giờ tiếng Việt)
  data/
    models/     NguoiDung · MonHoc · GiaoVien · TietHoc · BaoCao · NhacNho · MaMoi
                cùng phần chuyển đổi sang/từ Firestore
    repositories/
                hoc_tap_repository.dart   ← hợp đồng dữ liệu
                firebase_repository.dart  ← Auth + Firestore + Storage
                mock_repository.dart      ← in-memory, cho xem thử và cho test
    mock/       seed.dart
    app_state.dart   ChangeNotifier: phiên đăng nhập + bộ nhớ đệm
  features/
    auth/       cổng phân luồng · đăng nhập · đăng ký · mã mời · xem thử
    parent/     trang chủ · báo cáo · nhắc nhở · soạn nhắc nhở
    student/    trang chủ · lịch sử báo cáo
    shared/     thời khóa biểu · soạn/sửa tiết · soạn báo cáo · chi tiết báo cáo · hồ sơ
    admin/      tổng quan · người dùng · liên kết · môn & thầy cô

firestore.rules · storage.rules · firestore.indexes.json · firebase.json
test_rules/     kiểm thử luật bảo mật trên emulator
```

## Kiểm thử

```bash
flutter analyze
flutter test
```

Luật bảo mật có bộ kiểm thử riêng, chạy trên Firestore Emulator để chứng minh
bằng hành vi rằng phụ huynh lạ không đọc được dữ liệu của con nhà khác, và
không ai nối được tài khoản nếu không cầm mã mời hợp lệ:

```bash
cd test_rules && npm install && npm test
```

Chạy hoàn toàn cục bộ trên project ảo `demo-solienlac`, không đụng tới dữ liệu
thật và không cần tài khoản Firebase. Chi tiết: [test_rules/README.md](test_rules/README.md).
