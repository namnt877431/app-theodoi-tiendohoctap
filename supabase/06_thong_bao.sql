-- =============================================================================
-- Thông báo đẩy — phần dữ liệu và luật "ai nhận gì".
--
-- Cách đi của một thông báo:
--
--   bao_cao / nhac_nho có hàng mới ──trigger──▶ hàng đợi `thong_bao`
--   pg_cron 20:00 (HS chưa viết bài) ──────────▶ (den_id, tiêu đề, nội dung)
--                                                     │ webhook (file 07)
--                                                     ▼
--                                        Edge Function gui-thong-bao
--                                        đọc token của den_id → FCM → máy
--
-- File này chỉ dựng bảng, luật và các trigger xếp hàng — chạy được ở bất kỳ
-- Postgres nào, kể cả bộ kiểm thử. Phần cần dịch vụ của Supabase (pg_net,
-- pg_cron) nằm ở 07_thong_bao_may_chu.sql.
-- =============================================================================

-- Máy nào của ai. Một người có thể có nhiều máy; token do FCM cấp và đổi
-- thỉnh thoảng, app ghi đè mỗi lần mở.
create table if not exists thiet_bi (
  token         text primary key,
  nguoi_dung_id uuid not null references nguoi_dung(id) on delete cascade,
  nen_tang      text not null default 'android',
  cap_nhat_luc  timestamptz not null default now()
);

create index if not exists thiet_bi_nguoi_dung_idx on thiet_bi(nguoi_dung_id);

-- Hàng đợi. Mỗi hàng là một thông báo cho một người; Edge Function đọc token
-- của người đó rồi gửi, ghi lại `da_gui_luc` và lỗi nếu có. Giữ lại hàng đã
-- gửi để còn xem app có gửi đúng người không.
create table if not exists thong_bao (
  id         uuid primary key default gen_random_uuid(),
  den_id     uuid not null references nguoi_dung(id) on delete cascade,
  tieu_de    text not null,
  noi_dung   text not null,
  du_lieu    jsonb not null default '{}',
  tao_luc    timestamptz not null default now(),
  da_gui_luc timestamptz,
  loi        text
);

create index if not exists thong_bao_den_idx on thong_bao(den_id, tao_luc desc);

-- Cấu hình phía máy chủ: địa chỉ Edge Function và mã bí mật của webhook.
-- Không cấp quyền cho vai trò API nào — chỉ trigger (security definer) đọc.
create table if not exists cau_hinh (
  khoa    text primary key,
  gia_tri text not null
);

grant select, insert, update, delete on thiet_bi to authenticated;
grant select on thong_bao to authenticated;
revoke all on thiet_bi, thong_bao, cau_hinh from anon;
revoke all on cau_hinh from authenticated;

alter table thiet_bi enable row level security;
alter table thong_bao enable row level security;
alter table cau_hinh  enable row level security;

-- Máy của ai người đó quản. Không ai đăng ký token hộ người khác — nếu không
-- một người có thể nhận thông báo (kèm nội dung báo cáo) của nhà khác.
drop policy if exists tb_cua_toi on thiet_bi;
create policy tb_cua_toi on thiet_bi for all to authenticated
  using (nguoi_dung_id = auth.uid()) with check (nguoi_dung_id = auth.uid());

-- Hàng đợi chỉ do trigger ghi. Người dùng đọc được phần gửi cho mình.
drop policy if exists tbao_doc on thong_bao;
create policy tbao_doc on thong_bao for select to authenticated
  using (den_id = auth.uid() or la_quan_tri());

-- ---------------------------------------------------------------- xếp hàng

-- Học sinh gửi báo cáo → mỗi phụ huynh đã nối với em.
create or replace function tb_bao_cao_moi() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_ten text;
  v_mon text;
begin
  select ho_ten into v_ten from nguoi_dung where id = new.hoc_sinh_id;
  select ten into v_mon from mon_hoc where id = new.mon_id;
  insert into thong_bao (den_id, tieu_de, noi_dung, du_lieu)
  select lk.phu_huynh_id,
         coalesce(v_ten, 'Con') || ' vừa gửi báo cáo',
         coalesce(v_mon, 'Môn khác') || ' · ' || left(new.noi_dung, 90),
         jsonb_build_object('loai', 'bao_cao',
                            'bao_cao_id', new.id,
                            'hoc_sinh_id', new.hoc_sinh_id)
    from lien_ket lk
   where lk.hoc_sinh_id = new.hoc_sinh_id;
  return new;
end $$;

drop trigger if exists bao_cao_thong_bao on bao_cao;
create trigger bao_cao_thong_bao
  after insert on bao_cao
  for each row execute function tb_bao_cao_moi();

-- Phụ huynh ghi nhận xét → học sinh. Chỉ khi lời nhận xét thật sự đổi và
-- người sửa không phải chính em (em tự sửa báo cáo thì gửi cả bản ghi lên,
-- nhận xét đi kèm không đổi nên cũng không lọt qua đây).
create or replace function tb_nhan_xet_moi() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_mon text;
begin
  if new.nhan_xet_phu_huynh is not distinct from old.nhan_xet_phu_huynh
     or nullif(trim(coalesce(new.nhan_xet_phu_huynh, '')), '') is null
     or auth.uid() = new.hoc_sinh_id then
    return new;
  end if;
  select ten into v_mon from mon_hoc where id = new.mon_id;
  insert into thong_bao (den_id, tieu_de, noi_dung, du_lieu)
  values (new.hoc_sinh_id,
          'Bố mẹ vừa nhận xét bài ' || coalesce(v_mon, 'của con'),
          left(new.nhan_xet_phu_huynh, 100),
          jsonb_build_object('loai', 'nhan_xet',
                             'bao_cao_id', new.id,
                             'hoc_sinh_id', new.hoc_sinh_id));
  return new;
end $$;

drop trigger if exists bao_cao_thong_bao_nhan_xet on bao_cao;
create trigger bao_cao_thong_bao_nhan_xet
  after update on bao_cao
  for each row execute function tb_nhan_xet_moi();

-- Phụ huynh gửi lời nhắc → học sinh.
create or replace function tb_nhac_nho_moi() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_ten text;
begin
  select ho_ten into v_ten from nguoi_dung where id = new.tu_id;
  insert into thong_bao (den_id, tieu_de, noi_dung, du_lieu)
  values (new.den_id,
          coalesce(v_ten, 'Bố mẹ') || ' nhắc con',
          left(new.noi_dung, 100),
          jsonb_build_object('loai', 'nhac_nho',
                             'nhac_nho_id', new.id,
                             'hoc_sinh_id', new.den_id));
  return new;
end $$;

drop trigger if exists nhac_nho_thong_bao on nhac_nho;
create trigger nhac_nho_thong_bao
  after insert on nhac_nho
  for each row execute function tb_nhac_nho_moi();

-- Tối chưa viết báo cáo → nhắc học sinh. pg_cron gọi hàm này 20:00 mỗi tối
-- (file 07). Chỉ nhắc em nào đã cài app (có thiết bị) và hôm nay — theo giờ
-- Việt Nam — chưa có báo cáo nào. Trả về số em được nhắc.
create or replace function nhac_toi_chua_viet_bao_cao() returns int
language plpgsql security definer set search_path = public as $$
declare
  v_hom_nay date := (now() at time zone 'Asia/Ho_Chi_Minh')::date;
  v_so int;
begin
  with da_xep as (
    insert into thong_bao (den_id, tieu_de, noi_dung, du_lieu)
    select nd.id,
           'Hôm nay con chưa viết báo cáo',
           'Ghi lại hôm nay học gì để bố mẹ biết nhé.',
           jsonb_build_object('loai', 'nhac_toi')
      from nguoi_dung nd
     where nd.vai_tro = 'hocSinh' and nd.hoat_dong
       and exists (select 1 from thiet_bi tb where tb.nguoi_dung_id = nd.id)
       and not exists (select 1 from bao_cao bc
                        where bc.hoc_sinh_id = nd.id and bc.ngay = v_hom_nay)
    returning 1
  )
  select count(*) into v_so from da_xep;
  return v_so;
end $$;

-- Chỉ máy chủ (pg_cron, SQL Editor) gọi hàm này. Người dùng qua API không có
-- lý do gì để tự kích một đợt nhắc cả trường.
revoke execute on function nhac_toi_chua_viet_bao_cao() from public, anon, authenticated;

-- Tối Chủ nhật → mỗi phụ huynh một dòng tổng kết tuần cho từng đứa con.
-- pg_cron gọi 20:00 giờ VN Chủ nhật (file 07). Tuần tính từ thứ Hai tới
-- Chủ nhật hôm đó. Chỉ gửi cho phụ huynh đã cài app; con chưa viết bài nào
-- cả tuần thì cũng nói, vì đó chính là lúc bố mẹ cần biết.
create or replace function tong_ket_tuan() returns int
language plpgsql security definer set search_path = public as $$
declare
  v_hom_nay date := (now() at time zone 'Asia/Ho_Chi_Minh')::date;
  v_dau     date := v_hom_nay - ((extract(isodow from v_hom_nay)::int) - 1);
  v_so      int;
begin
  with tuan as (
    select lk.phu_huynh_id,
           hs.id as hoc_sinh_id,
           regexp_replace(hs.ho_ten, '^.*\s', '') as ten_goi,
           count(bc.id)                                       as tong,
           count(bc.id) filter (where bc.trang_thai = 'xong') as xong,
           count(distinct bc.ngay)                            as so_ngay,
           coalesce(sum(bc.so_phut), 0)                       as phut
      from lien_ket lk
      join nguoi_dung hs on hs.id = lk.hoc_sinh_id and hs.hoat_dong
      left join bao_cao bc on bc.hoc_sinh_id = hs.id
                          and bc.ngay between v_dau and v_hom_nay
     where exists (select 1 from thiet_bi tb where tb.nguoi_dung_id = lk.phu_huynh_id)
     group by lk.phu_huynh_id, hs.id, hs.ho_ten
  ), da_xep as (
    insert into thong_bao (den_id, tieu_de, noi_dung, du_lieu)
    select phu_huynh_id,
           'Tuần này của ' || ten_goi,
           case
             when tong = 0 then 'Chưa có báo cáo nào tuần này — hỏi con xem sao nhé.'
             else 'Xong ' || xong || '/' || tong || ' bài · có báo cáo ' || so_ngay || '/7 ngày'
                  || case when phut >= 60
                          then ' · ' || round(phut / 60.0, 1) || 'h học'
                          else '' end
           end,
           jsonb_build_object('loai', 'tong_ket_tuan',
                              'hoc_sinh_id', hoc_sinh_id,
                              'tu', v_dau, 'den', v_hom_nay)
      from tuan
    returning 1
  )
  select count(*) into v_so from da_xep;
  return v_so;
end $$;

revoke execute on function tong_ket_tuan() from public, anon, authenticated;
