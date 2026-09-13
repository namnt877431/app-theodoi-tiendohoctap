-- =============================================================================
-- Mã mời — nối phụ huynh với con
--
-- Học sinh sinh một mã sáu số, đọc cho bố mẹ nhập. Mã sống 15 phút và chỉ dùng
-- được một lần.
--
-- Cả hai việc đều làm bằng hàm `security definer` chứ không để client tự ghi
-- bảng. Nhờ vậy phép kiểm tra "mã này có thật, còn hạn, chưa ai dùng không"
-- chạy trong một transaction ở server, và phụ huynh không bao giờ được quyền
-- tự chèn một dòng vào bảng lien_ket.
-- =============================================================================

create or replace function tao_ma_moi()
returns ma_moi
language plpgsql security definer set search_path = public as $$
declare
  v_ma  text;
  v_kq  ma_moi;
begin
  if not exists (
    select 1 from nguoi_dung
     where id = auth.uid() and vai_tro = 'hocSinh' and hoat_dong
  ) then
    raise exception 'Chỉ tài khoản học sinh mới tạo được mã mời';
  end if;

  -- Vô hiệu mã cũ trước: mỗi học sinh chỉ nên có đúng một mã sống, để lỡ đọc
  -- nhầm mã cũ cho bố mẹ thì cũng không nối vào được.
  update ma_moi set da_dung = true
   where hoc_sinh_id = auth.uid() and not da_dung;

  for i in 1..8 loop
    v_ma := lpad(floor(random() * 1000000)::int::text, 6, '0');
    begin
      insert into ma_moi (ma, hoc_sinh_id, het_han)
      values (v_ma, auth.uid(), now() + interval '15 minutes')
      returning * into v_kq;
      return v_kq;
    exception when unique_violation then
      -- Trùng mã đang sống của người khác, bốc số khác.
      null;
    end;
  end loop;

  raise exception 'Chưa sinh được mã mời, thử lại sau một lát';
end $$;

create or replace function dung_ma_moi(p_ma text)
returns nguoi_dung
language plpgsql security definer set search_path = public as $$
declare
  v_hoc_sinh uuid;
  v_kq       nguoi_dung;
begin
  if not exists (
    select 1 from nguoi_dung
     where id = auth.uid() and vai_tro = 'phuHuynh' and hoat_dong
  ) then
    raise exception 'Chỉ tài khoản phụ huynh mới nhập được mã mời';
  end if;

  if p_ma !~ '^[0-9]{6}$' then
    raise exception 'Mã mời gồm đúng 6 chữ số';
  end if;

  -- Khóa hàng lại trong lúc kiểm tra: hai người cùng nhập một mã thì chỉ
  -- người đầu tiên nối được.
  select hoc_sinh_id into v_hoc_sinh
    from ma_moi
   where ma = p_ma and not da_dung and het_han > now()
     for update;

  if v_hoc_sinh is null then
    raise exception 'Mã mời không đúng hoặc đã hết hạn';
  end if;

  update ma_moi set da_dung = true where ma = p_ma;

  insert into lien_ket (phu_huynh_id, hoc_sinh_id)
  values (auth.uid(), v_hoc_sinh)
  on conflict do nothing;

  select * into v_kq from nguoi_dung where id = v_hoc_sinh;
  return v_kq;
end $$;

revoke all on function tao_ma_moi()      from public, anon;
revoke all on function dung_ma_moi(text) from public, anon;
grant execute on function tao_ma_moi()      to authenticated;
grant execute on function dung_ma_moi(text) to authenticated;
