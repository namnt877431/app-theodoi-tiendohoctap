-- =============================================================================
-- Phần thưởng theo chuỗi ngày trọn vẹn — "7 ngày liền → đi ăn kem".
--
-- Bố mẹ treo, app đếm, bố mẹ trao. Đạt hay chưa KHÔNG lưu ở đây: app tính từ
-- bảng bao_cao (có chuỗi ≥ moc kể từ tu_ngay), nên không ai ghi được "đã đạt"
-- bằng tay, kể cả con. Trao xong thì "treo lại" — tu_ngay về hôm nay.
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
  trao_luc    timestamptz,
  tao_luc     timestamptz not null default now()
);

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
