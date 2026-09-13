  -- ------------------------------------------------------------- tổng kết
  --
  -- Ngoại lệ dưới đây là CỐ Ý. Không mở được giao dịch tường minh (lý do ở đầu
  -- file), nên ném ngoại lệ là cách duy nhất hoàn tác sạch dữ liệu thử. Đọc
  -- nội dung thông báo, đừng nhìn màu của khung.

  if so_tru > 0 then
    raise exception E'KIỂM THỬ PHÂN QUYỀN — % đạt, % TRƯỢT trên tổng %.\n%\n\nDữ liệu thử đã được hoàn tác.',
      so_dat, so_tru, so_dat + so_tru, bao;
  else
    raise exception E'KIỂM THỬ PHÂN QUYỀN — tất cả % phép thử đều ĐẠT.\n\nKhông có gì hỏng. Ngoại lệ này là cố ý: nó hoàn tác toàn bộ dữ liệu thử.',
      so_dat;
  end if;
end
$ktr$;
