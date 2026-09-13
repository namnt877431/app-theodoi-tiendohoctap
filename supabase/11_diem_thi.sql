-- =============================================================================
-- Sổ điểm — bốn cột như sổ ở trường: miệng, 15 phút, 1 tiết (giuaKi, hệ số
-- 2), học kỳ (cuoiKi, hệ số 3). Điểm là số thang 10, hoặc Đ/CĐ với môn chấm
-- bằng nhận xét (cột `dat`) — đúng một trong hai.
--
-- Con hay bố mẹ đều ghi được, và sửa/xóa được — điểm ghi nhầm là chuyện
-- thường, không cần khóa. Phần thưởng loại "điểm thi" (10_phan_thuong.sql)
-- đếm trên bảng này.
--
-- Chạy sau 02_bao_mat.sql và 05_danh_muc.sql. Chạy lại nhiều lần không sao.
-- =============================================================================

create table if not exists diem_thi (
  id          uuid primary key default gen_random_uuid(),
  hoc_sinh_id uuid not null references nguoi_dung(id) on delete cascade,
  mon_id      text not null references mon_hoc(id) on delete cascade,
  loai        text not null check (loai in ('mieng', 'muoiLamPhut', 'giuaKi', 'cuoiKi')),
  hoc_ki      int  not null check (hoc_ki in (1, 2)),
  diem        numeric(4, 2) check (diem is null or diem between 0 and 10),
  dat         boolean,
  ngay        date not null default (now() at time zone 'Asia/Ho_Chi_Minh')::date,
  ghi_chu     text check (ghi_chu is null or length(ghi_chu) <= 200),
  tao_boi     uuid references nguoi_dung(id) on delete set null,
  tao_luc     timestamptz not null default now()
);

create index if not exists diem_thi_hs_idx on diem_thi(hoc_sinh_id, ngay desc);

-- Bản đầu chỉ có "thường xuyên"; giờ tách thành miệng và 15 phút. Gỡ ràng
-- buộc cũ, dời dữ liệu, đặt lại ràng buộc — chạy trên bảng mới cũng không sao.
alter table diem_thi drop constraint if exists diem_thi_loai_check;
update diem_thi set loai = 'mieng' where loai = 'thuongXuyen';
alter table diem_thi add constraint diem_thi_loai_check
  check (loai in ('mieng', 'muoiLamPhut', 'giuaKi', 'cuoiKi'));

-- Môn chấm Đ/CĐ: thêm cột `dat`, cho `diem` trống, và bắt đúng một trong hai.
alter table diem_thi add column if not exists dat boolean;
alter table diem_thi alter column diem drop not null;
alter table diem_thi drop constraint if exists diem_thi_diem_hoac_dat;
alter table diem_thi add constraint diem_thi_diem_hoac_dat
  check ((diem is null) <> (dat is null));

grant select, insert, update, delete on diem_thi to authenticated;
revoke all on diem_thi from anon;

alter table diem_thi enable row level security;

-- Con thấy điểm của mình, bố mẹ thấy điểm của con, quản trị thấy hết.
drop policy if exists dt_doc on diem_thi;
create policy dt_doc on diem_thi for select to authenticated
  using (xem_duoc(hoc_sinh_id));

-- Ghi: chính em, bố mẹ đã nối với em, hoặc quản trị — và ghi dưới tên mình.
drop policy if exists dt_tao on diem_thi;
create policy dt_tao on diem_thi for insert to authenticated
  with check (xem_duoc(hoc_sinh_id) and (tao_boi is null or tao_boi = auth.uid()));

drop policy if exists dt_sua on diem_thi;
create policy dt_sua on diem_thi for update to authenticated
  using (xem_duoc(hoc_sinh_id)) with check (xem_duoc(hoc_sinh_id));

drop policy if exists dt_xoa on diem_thi;
create policy dt_xoa on diem_thi for delete to authenticated
  using (xem_duoc(hoc_sinh_id));
