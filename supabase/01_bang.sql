-- =============================================================================
-- Sổ liên lạc — lược đồ dữ liệu
--
-- Chạy toàn bộ file này trong Supabase → SQL Editor, một lần, theo thứ tự
-- 01 → 02 → 03. Chạy lại được nhiều lần mà không hỏng gì.
-- =============================================================================

-- Hồ sơ người dùng, khóa một-một với auth.users của Supabase.
-- Mật khẩu và email đăng nhập do Supabase Auth giữ; bảng này chỉ giữ phần
-- nghiệp vụ: vai trò, lớp, trường.
create table if not exists nguoi_dung (
  id            uuid primary key references auth.users(id) on delete cascade,
  ho_ten        text not null,
  vai_tro       text not null check (vai_tro in ('phuHuynh', 'hocSinh', 'quanTri')),
  email         text,
  so_dien_thoai text,
  lop           text,
  truong        text,
  hoat_dong     boolean not null default true,
  tao_luc       timestamptz not null default now()
);

-- `truong` (chữ) là cột cũ, từ hồi học sinh gõ tay tên trường lúc đăng ký. Giờ
-- học sinh chọn trường từ danh mục, khóa bằng `truong_id`; cột chữ giữ lại
-- cho tài khoản đăng ký trước khi có danh mục, và làm chỗ ghi tên trường
-- để mở bảng ra vẫn đọc được.

-- Phụ huynh nào theo dõi học sinh nào.
--
-- Ở bản Firestore đây là một mảng `conIds` nằm trong hồ sơ phụ huynh, và phải
-- bịa thêm trường `maMoiDaDung` để luật bảo mật kiểm tra được. Postgres có
-- bảng quan hệ thật nên chỉ cần khóa chính ghép là xong.
create table if not exists lien_ket (
  phu_huynh_id uuid not null references nguoi_dung(id) on delete cascade,
  hoc_sinh_id  uuid not null references nguoi_dung(id) on delete cascade,
  tao_luc      timestamptz not null default now(),
  primary key (phu_huynh_id, hoc_sinh_id)
);

create index if not exists lien_ket_hoc_sinh_idx on lien_ket(hoc_sinh_id);

-- Danh mục dùng chung. Id để dạng text cho dễ đọc khi mở bảng ra xem.
create table if not exists mon_hoc (
  id       text primary key,
  ten      text not null,
  viet_tat text not null
);

-- Tỉnh và trường. Học sinh chọn trường lúc đăng ký; thầy cô trên lớp gắn với
-- trường, nên mỗi em chỉ thấy thầy cô của trường mình. Tỉnh chỉ để quản trị
-- lọc danh sách cho gọn — không phải một tầng phân quyền, quản trị nào cũng
-- thấy hết.
create table if not exists tinh (
  id  text primary key,
  ten text not null
);

create table if not exists truong (
  id      text primary key,
  ten     text not null,
  tinh_id text references tinh(id) on delete set null
);

create index if not exists truong_tinh_idx on truong(tinh_id);

alter table nguoi_dung
  add column if not exists truong_id text references truong(id) on delete set null;

-- Ba cột sau cùng quyết định ai thấy một thầy cô:
--
--   trenLop  → `truong_id` bắt buộc (app ép, DB không ép để dữ liệu cũ chưa
--              gắn trường vẫn còn hiện cho mọi người). Học sinh chỉ thấy thầy
--              cô trường mình.
--   hocThem  → theo môn. `chu_id` null là thầy dùng chung do quản trị nhập,
--              có `tinh_id` để lọc theo tỉnh; `chu_id` có giá trị là thầy
--              riêng của một học sinh, chỉ nhà em đó và quản trị thấy.
create table if not exists giao_vien (
  id            text primary key,
  ho_ten        text not null,
  mon_id        text references mon_hoc(id) on delete set null,
  loai          text not null check (loai in ('trenLop', 'hocThem')),
  noi_day       text,
  so_dien_thoai text,
  truong_id     text references truong(id) on delete set null,
  tinh_id       text references tinh(id) on delete set null,
  chu_id        uuid references nguoi_dung(id) on delete cascade
);

-- Dự án dựng từ bản trước thì bảng đã có, thêm cột vào cho khớp.
alter table giao_vien
  add column if not exists truong_id text references truong(id) on delete set null,
  add column if not exists tinh_id   text references tinh(id) on delete set null,
  add column if not exists chu_id    uuid references nguoi_dung(id) on delete cascade;

create index if not exists giao_vien_truong_idx on giao_vien(truong_id);
create index if not exists giao_vien_chu_idx    on giao_vien(chu_id);

-- Thời khóa biểu. `thu` đánh số 2..8 đúng cách người Việt gọi, 8 là Chủ nhật.
create table if not exists tiet_hoc (
  id           uuid primary key default gen_random_uuid(),
  hoc_sinh_id  uuid not null references nguoi_dung(id) on delete cascade,
  thu          int  not null check (thu between 2 and 8),
  tiet         int  not null check (tiet between 1 and 12),
  buoi         text not null check (buoi in ('sang', 'chieu', 'toi')),
  mon_id       text references mon_hoc(id) on delete set null,
  loai         text not null check (loai in ('trenLop', 'hocThem')),
  giao_vien_id text references giao_vien(id) on delete set null,
  phong        text,
  bat_dau      text,
  ket_thuc     text
);

create index if not exists tiet_hoc_hoc_sinh_idx on tiet_hoc(hoc_sinh_id, thu, buoi, tiet);

create table if not exists bao_cao (
  id                 uuid primary key default gen_random_uuid(),
  hoc_sinh_id        uuid not null references nguoi_dung(id) on delete cascade,
  ngay               date not null,
  loai               text not null check (loai in ('trenLop', 'hocThem')),
  mon_id             text references mon_hoc(id) on delete set null,
  giao_vien_id       text references giao_vien(id) on delete set null,
  noi_dung           text not null,
  trang_thai         text not null check (trang_thai in ('chuaLam', 'dangLam', 'xong')),
  anh                text[] not null default '{}',
  so_phut            int check (so_phut is null or so_phut >= 0),
  nhan_xet_phu_huynh text,
  phu_huynh_da_xem   boolean not null default false,
  tao_luc            timestamptz not null default now()
);

create index if not exists bao_cao_hoc_sinh_ngay_idx on bao_cao(hoc_sinh_id, ngay desc);

-- Danh mục bài học theo sách giáo khoa (từ 2026-2027 cả nước dùng chung bộ
-- "Kết nối tri thức"). Học sinh chọn bài thay vì gõ tên; phụ huynh đọc tóm
-- tắt và mấy câu hỏi để kiểm tra con. Dữ liệu nạp từ 09_bai_hoc_lop*.sql
-- (sinh bởi tools/bai_hoc/tao_sql.py); quản trị sửa tóm tắt được trong app.
create table if not exists bai_hoc (
  id           text primary key,
  mon_id       text not null references mon_hoc(id) on delete cascade,
  lop          int  not null check (lop between 1 and 12),
  hoc_ki       int  check (hoc_ki in (1, 2)),
  chuong       text,
  thu_tu       int  not null,
  ten          text not null,
  tom_tat      text,
  kiem_tra     text[] not null default '{}',
  -- Quản trị đã sửa tay tóm tắt/câu hỏi: chạy lại file dữ liệu không ghi đè.
  sua_tay      boolean not null default false,
  cap_nhat_luc timestamptz not null default now()
);

create index if not exists bai_hoc_lop_mon_idx on bai_hoc(lop, mon_id, thu_tu);

-- Báo cáo gắn với bài nào trong danh mục; null là bài không có trong danh mục
-- (học thêm, ôn tập tự do) hoặc học sinh không chọn.
alter table bao_cao add column if not exists bai_hoc_id text references bai_hoc(id) on delete set null;

create table if not exists nhac_nho (
  id          uuid primary key default gen_random_uuid(),
  tu_id       uuid not null references nguoi_dung(id) on delete cascade,
  den_id      uuid not null references nguoi_dung(id) on delete cascade,
  noi_dung    text not null,
  han_luc     timestamptz,
  da_doc      boolean not null default false,
  bao_cao_id  uuid references bao_cao(id) on delete set null,
  tao_luc     timestamptz not null default now()
);

create index if not exists nhac_nho_den_idx on nhac_nho(den_id, tao_luc desc);

-- Mã mời sáu số để phụ huynh nối vào tài khoản con. Sống 15 phút, dùng một lần.
create table if not exists ma_moi (
  ma          text primary key check (ma ~ '^[0-9]{6}$'),
  hoc_sinh_id uuid not null references nguoi_dung(id) on delete cascade,
  het_han     timestamptz not null,
  da_dung     boolean not null default false,
  tao_luc     timestamptz not null default now()
);

create index if not exists ma_moi_hoc_sinh_idx on ma_moi(hoc_sinh_id);

-- Cấp quyền chạm tới bảng cho vai trò của người đã đăng nhập.
--
-- Dự án Supabase mới thường bật sẵn "Automatically expose new tables" và tự
-- làm việc này; ghi rõ ra đây để ai tắt ô đó thì app vẫn chạy.
--
-- Quyền này chỉ mở cửa vào bảng. Đọc hay ghi được dòng nào là chuyện của RLS ở
-- file 02, và mặc định ở đó là cấm.
grant usage on schema public to authenticated;
grant select, insert, update, delete on
  nguoi_dung, lien_ket, mon_hoc, giao_vien, tinh, truong, bai_hoc,
  tiet_hoc, bao_cao, nhac_nho, ma_moi
  to authenticated;

-- Người chưa đăng nhập không chạm được gì — trừ danh sách tỉnh và trường,
-- vì màn đăng ký phải hiện được danh sách trường trước khi có tài khoản. Đó
-- là tên trường công khai, không có gì riêng tư.
revoke all on
  nguoi_dung, lien_ket, mon_hoc, giao_vien, bai_hoc,
  tiet_hoc, bao_cao, nhac_nho, ma_moi
  from anon;
grant usage on schema public to anon;
grant select on tinh, truong to anon;
