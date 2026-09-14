-- =============================================================================
-- Phần thưởng theo chuỗi ngày có báo cáo — "7 ngày liền → đi ăn kem".
--
-- Bố mẹ treo, app đếm, bố mẹ trao. Hai loại:
--   chuoi  "7 ngày liền báo cáo → kem" — đếm ngày có bao_cao kể từ tu_ngay;
--          lap_lai thì cứ mỗi moc ngày một lần.
--   diem   "điểm giữa kì Toán từ 8 trở lên → quà" — đếm trên diem_thi (file
--          11); mon_id null là môn nào cũng được, ki_thi null là giữa hay cuối
--          kì đều được. Mỗi bài đạt là một lần.
-- Số lần đạt KHÔNG lưu: app tính từ dữ liệu, nên không ai ghi được "đã đạt"
-- bằng tay, kể cả con. so_lan_trao là số lần bố mẹ đã trao; đạt trừ trao là
-- số quà còn nợ.
--
-- Chạy sau 02_bao_mat.sql (dùng các hàm xem_duoc, la_phu_huynh_cua,
-- la_quan_tri). Chạy lại nhiều lần không sao.
-- =============================================================================

create table if not exists phan_thuong (
  id          uuid primary key default gen_random_uuid(),
  hoc_sinh_id uuid not null references nguoi_dung(id) on delete cascade,
  tao_boi     uuid not null references nguoi_dung(id) on delete cascade,
  moc         int  not null check (moc between 1 and 365),
  ten         text not null check (length(trim(ten)) between 1 and 120),
  tu_ngay     date not null default (now() at time zone 'Asia/Ho_Chi_Minh')::date,
  lap_lai     boolean not null default false,
  so_lan_trao int  not null default 0 check (so_lan_trao >= 0),
  trao_luc    timestamptz,
  loai        text not null default 'chuoi' check (loai in ('chuoi', 'diem')),
  mon_id      text references mon_hoc(id) on delete set null,
  ki_thi      text check (ki_thi is null or ki_thi in ('giuaKi', 'cuoiKi')),
  diem_toi_thieu numeric(4, 2) check (diem_toi_thieu is null or diem_toi_thieu between 0 and 10),
  tao_luc     timestamptz not null default now()
);

-- Dự án dựng bảng từ bản trước khi có lặp lại và thưởng điểm thi.
alter table phan_thuong add column if not exists lap_lai boolean not null default false;
alter table phan_thuong add column if not exists so_lan_trao int not null default 0;
alter table phan_thuong add column if not exists loai text not null default 'chuoi';
alter table phan_thuong add column if not exists mon_id text references mon_hoc(id) on delete set null;
alter table phan_thuong add column if not exists ki_thi text;
alter table phan_thuong add column if not exists diem_toi_thieu numeric(4, 2);

create index if not exists phan_thuong_hs_idx on phan_thuong(hoc_sinh_id, moc);

grant select, insert, update, delete on phan_thuong to authenticated;
revoke all on phan_thuong from anon;

alter table phan_thuong enable row level security;

-- Con thấy quà treo cho mình, bố mẹ thấy quà của con, quản trị thấy hết.
drop policy if exists pt_doc on phan_thuong;
create policy pt_doc on phan_thuong for select to authenticated
  using (xem_duoc(hoc_sinh_id));

-- Chỉ bố mẹ đã nối với em mới treo, và treo dưới tên mình.
drop policy if exists pt_tao on phan_thuong;
create policy pt_tao on phan_thuong for insert to authenticated
  with check ((la_phu_huynh_cua(hoc_sinh_id) and tao_boi = auth.uid()) or la_quan_tri());

-- Sửa, trao, treo lại, xóa: bố mẹ của em hoặc quản trị. Con không đụng được
-- — kể cả đánh dấu đã trao, vì cái dấu đó là của bố mẹ.
drop policy if exists pt_sua on phan_thuong;
create policy pt_sua on phan_thuong for update to authenticated
  using (la_phu_huynh_cua(hoc_sinh_id) or la_quan_tri())
  with check (la_phu_huynh_cua(hoc_sinh_id) or la_quan_tri());

drop policy if exists pt_xoa on phan_thuong;
create policy pt_xoa on phan_thuong for delete to authenticated
  using (la_phu_huynh_cua(hoc_sinh_id) or la_quan_tri());
