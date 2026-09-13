  -- ------------------------------------------------------------- mã mời
  --
  -- Đây là chỗ duy nhất một người lạ được phép trở thành phụ huynh của một đứa
  -- trẻ. Không xếp vào bảng phép thử ở trên được, vì phải bắt lấy mã vừa sinh
  -- rồi mang đi dùng lại.

  perform set_config('request.jwt.claims',
    json_build_object('sub', '33333333-3333-3333-3333-333333333333', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    v_ma := tao_ma_moi();
    ok  := v_ma.ma ~ '^[0-9]{6}$'
       and v_ma.hoc_sinh_id = '33333333-3333-3333-3333-333333333333'
       and v_ma.het_han > now()
       and not v_ma.da_dung;
    ghi := case when ok then null else 'mã trả về không hợp lệ: ' || v_ma::text end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ HS sinh được mã mời sáu số, còn hạn, chưa dùng' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '11111111-1111-1111-1111-111111111111', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    perform tao_ma_moi();
    ok := false; ghi := 'lẽ ra bị chặn vì sai vai trò';
  exception when others then ok := true;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ PH không sinh được mã mời' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    select count(*) into n from ma_moi;
    ok := (n = 0); ghi := case when ok then null else 'thấy ' || n || ' hàng' end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ PH không đọc trộm được bảng mã mời' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '44444444-4444-4444-4444-444444444444', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    select count(*) into n from ma_moi;
    ok := (n = 0); ghi := case when ok then null else 'thấy ' || n || ' hàng' end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ HS khác không đọc trộm được mã mời của bạn' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '33333333-3333-3333-3333-333333333333', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    select count(*) into n from ma_moi;
    ok := (n = 1); ghi := case when ok then null else 'thấy ' || n || ' hàng' end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ HS đọc được mã mời của chính mình' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '44444444-4444-4444-4444-444444444444', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    perform dung_ma_moi(v_ma.ma);
    ok := false; ghi := 'lẽ ra bị chặn vì sai vai trò';
  exception when others then ok := true;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ HS không dùng được mã mời' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    perform dung_ma_moi('12ab34');
    ok := false; ghi := 'lẽ ra bị chặn vì không phải sáu chữ số';
  exception when others then ok := true;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ Mã sai định dạng bị từ chối' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    perform dung_ma_moi(lpad(((v_ma.ma::int + 1) % 1000000)::text, 6, '0'));
    ok := false; ghi := 'lẽ ra bị chặn vì không có mã đó';
  exception when others then ok := true;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ Mã không tồn tại bị từ chối' || coalesce(' — ' || ghi, '');
  end if;

  -- Mã hết hạn: chèn bằng quyền chủ rồi thử nhập.
  insert into ma_moi (ma, hoc_sinh_id, het_han)
  values ('000001', '33333333-3333-3333-3333-333333333333', now() - interval '1 minute');

  perform set_config('request.jwt.claims',
    json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    perform dung_ma_moi('000001');
    ok := false; ghi := 'lẽ ra bị chặn vì đã quá mười lăm phút';
  exception when others then ok := true;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ Mã hết hạn bị từ chối' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    v_hs := dung_ma_moi(v_ma.ma);
    ok  := (v_hs.id = '33333333-3333-3333-3333-333333333333');
    ghi := case when ok then null else 'nối nhầm sang học sinh khác' end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ PH nhập mã đúng thì nối được với con' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    select count(*) into n from bao_cao where hoc_sinh_id = '33333333-3333-3333-3333-333333333333';
    ok := (n = 1); ghi := case when ok then null else 'thấy ' || n || ' báo cáo' end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ Nối xong thì PH đọc được báo cáo của con' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    perform dung_ma_moi(v_ma.ma);
    ok := false; ghi := 'lẽ ra bị chặn vì mã chỉ dùng một lần';
  exception when others then ok := true;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ Mã đã dùng thì không dùng lại được' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '33333333-3333-3333-3333-333333333333', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    perform tao_ma_moi();
    perform tao_ma_moi();
    perform set_config('role', chu, true);
    select count(*) into n from ma_moi where hoc_sinh_id = '33333333-3333-3333-3333-333333333333' and not da_dung;
    ok  := (n = 1);
    ghi := case when ok then null else 'còn ' || n || ' mã đang sống' end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ Sinh mã mới thì mọi mã cũ hết hiệu lực' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims', '', true);
  perform set_config('role', chu, true);

