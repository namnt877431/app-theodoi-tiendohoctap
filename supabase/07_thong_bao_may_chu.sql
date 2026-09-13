-- =============================================================================
-- Thông báo đẩy — phần cần dịch vụ của Supabase.
--
-- Hai việc: (1) mỗi hàng mới trong `thong_bao` gọi Edge Function gui-thong-bao
-- qua pg_net; (2) pg_cron gọi nhac_toi_chua_viet_bao_cao() 20:00 mỗi tối và
-- tong_ket_tuan() 20:00 tối Chủ nhật (giờ VN).
--
-- Chạy SAU khi đã tạo Edge Function và điền hai dòng cấu hình bên dưới. Chạy
-- lại được nhiều lần.
-- =============================================================================

-- ------------------------------------------------------------- cấu hình
--
-- Sửa hai giá trị này trước khi chạy:
--   url_gui_thong_bao  — địa chỉ Edge Function, dạng
--                        https://<project-ref>.supabase.co/functions/v1/gui-thong-bao
--   ma_bi_mat_webhook  — một chuỗi ngẫu nhiên dài, đặt giống hệt trong secret
--                        MA_BI_MAT_WEBHOOK của Edge Function.

insert into cau_hinh (khoa, gia_tri) values
  ('url_gui_thong_bao', 'https://THAY-PROJECT-REF.supabase.co/functions/v1/gui-thong-bao'),
  ('ma_bi_mat_webhook', 'THAY-BANG-CHUOI-NGAU-NHIEN-DAI')
on conflict (khoa) do update set gia_tri = excluded.gia_tri;

-- --------------------------------------------------------------- webhook

create extension if not exists pg_net with schema extensions;

-- Gọi Edge Function ngay khi có hàng mới. Không có cấu hình thì hàng vẫn nằm
-- trong hàng đợi, không mất — điền cấu hình xong gửi lại được bằng tay.
create or replace function tb_goi_edge_function() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_url    text;
  v_bi_mat text;
begin
  select gia_tri into v_url    from cau_hinh where khoa = 'url_gui_thong_bao';
  select gia_tri into v_bi_mat from cau_hinh where khoa = 'ma_bi_mat_webhook';
  if v_url is null or v_url like '%THAY-PROJECT-REF%' then
    return new;
  end if;
  perform net.http_post(
    url     := v_url,
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'x-ma-bi-mat',  coalesce(v_bi_mat, '')),
    body    := jsonb_build_object(
                 'id',       new.id,
                 'den_id',   new.den_id,
                 'tieu_de',  new.tieu_de,
                 'noi_dung', new.noi_dung,
                 'du_lieu',  new.du_lieu)
  );
  return new;
end $$;

drop trigger if exists thong_bao_goi_edge_function on thong_bao;
create trigger thong_bao_goi_edge_function
  after insert on thong_bao
  for each row execute function tb_goi_edge_function();

-- ------------------------------------------------------------- nhắc tối

create extension if not exists pg_cron with schema pg_catalog;
grant usage on schema cron to postgres;

-- 13:00 UTC là 20:00 giờ Việt Nam. cron.schedule cùng tên thì ghi đè, nên
-- chạy lại file này không tạo thêm việc trùng.
select cron.schedule(
  'nhac-toi-chua-viet-bao-cao',
  '0 13 * * *',
  $$select nhac_toi_chua_viet_bao_cao()$$
);

-- Tổng kết tuần cho bố mẹ: 20:00 giờ VN Chủ nhật.
select cron.schedule(
  'tong-ket-tuan',
  '0 13 * * 0',
  $$select tong_ket_tuan()$$
);

-- ------------------------------------------------------------ gửi lại tay
--
-- Trigger chỉ nổ lúc insert, nên hàng nào chưa gửi được (da_gui_luc null,
-- hoặc cột loi có chữ) thì kích lại bằng tay trong SQL Editor:
--
--   select tb_goi_lai(id) from thong_bao where da_gui_luc is null;

create or replace function tb_goi_lai(p_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_url    text;
  v_bi_mat text;
  r        thong_bao;
begin
  select * into r from thong_bao where id = p_id;
  if not found then return; end if;
  select gia_tri into v_url    from cau_hinh where khoa = 'url_gui_thong_bao';
  select gia_tri into v_bi_mat from cau_hinh where khoa = 'ma_bi_mat_webhook';
  perform net.http_post(
    url     := v_url,
    headers := jsonb_build_object('Content-Type', 'application/json',
                                  'x-ma-bi-mat', coalesce(v_bi_mat, '')),
    body    := jsonb_build_object('id', r.id, 'den_id', r.den_id,
                                  'tieu_de', r.tieu_de, 'noi_dung', r.noi_dung,
                                  'du_lieu', r.du_lieu)
  );
end $$;

revoke execute on function tb_goi_lai(uuid) from public, anon, authenticated;
