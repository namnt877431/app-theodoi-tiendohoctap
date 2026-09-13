  ) as v(ten, vai, kieu, cau, so)
  loop
    if t.vai is null then
      perform set_config('request.jwt.claims', '', true);
      perform set_config('role', 'anon', true);
    else
      perform set_config('request.jwt.claims',
        json_build_object('sub', t.vai::text, 'role', 'authenticated')::text, true);
      perform set_config('role', 'authenticated', true);
    end if;

    ghi := null;
    begin
      if t.kieu = 'thay' then
        execute 'select count(*) from (' || t.cau || ') x' into n;
        ok := (n = t.so);
        if not ok then ghi := 'mong thấy ' || t.so || ' hàng, thực tế ' || n; end if;
      elsif t.kieu = 'duoc' then
        execute t.cau;
        ok := true;
      else
        execute t.cau;
        get diagnostics n = row_count;
        ok := (n = 0);
        if not ok then ghi := 'lẽ ra bị chặn, nhưng đã đụng tới ' || n || ' hàng'; end if;
      end if;
    exception when others then
      -- Bị chặn thì đây là kết quả đúng; còn lại là hỏng thật.
      ok  := (t.kieu = 'chan');
      ghi := case when ok then null else sqlerrm end;
    end;

    perform set_config('role', chu, true);

    if ok then
      so_dat := so_dat + 1;
    else
      so_tru := so_tru + 1;
      bao := bao || E'\n  ✗ ' || t.ten || coalesce(' — ' || ghi, '');
    end if;
  end loop;

  perform set_config('request.jwt.claims', '', true);
  perform set_config('role', chu, true);

