import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';

import { moiTruong, napNen, PH1, PH2, HS1, HS2, QT } from './moi_truong.mjs';

let env;
before(async () => { env = await moiTruong(); });
after(async () => { await env.cleanup(); });
beforeEach(async () => { await napNen(env); });

const nhu = (uid) => env.authenticatedContext(uid).firestore();

describe('Báo cáo là lời của học sinh', () => {
  it('học sinh viết, sửa và xóa báo cáo của mình', async () => {
    const db = nhu(HS1);
    await assertSucceeds(setDoc(doc(db, 'hocSinh', HS1, 'baoCao', 'bc2'), {
      hocSinhId: HS1, ngay: new Date(), khoaNgay: '2026-09-11',
      loai: 'trenLop', monId: 'm_toan', noiDung: 'Bài mới',
      trangThai: 'xong', anh: [], phuHuynhDaXem: false, taoLuc: new Date(),
    }));
    await assertSucceeds(updateDoc(doc(db, 'hocSinh', HS1, 'baoCao', 'bc1'), {
      trangThai: 'xong',
    }));
    await assertSucceeds(deleteDoc(doc(db, 'hocSinh', HS1, 'baoCao', 'bc2')));
  });

  it('học sinh không viết được báo cáo vào sổ của bạn', async () => {
    await assertFails(setDoc(doc(nhu(HS1), 'hocSinh', HS2, 'baoCao', 'bc9'), {
      hocSinhId: HS2, noiDung: 'Giả mạo', loai: 'trenLop',
      monId: 'm_toan', trangThai: 'xong', ngay: new Date(), taoLuc: new Date(),
    }));
  });

  it('phụ huynh chỉ viết được nhận xét, không sửa được nội dung hay trạng thái', async () => {
    const db = nhu(PH1);
    const bc = doc(db, 'hocSinh', HS1, 'baoCao', 'bc1');

    await assertSucceeds(updateDoc(bc, { nhanXetPhuHuynh: 'Cố lên con', phuHuynhDaXem: true }));
    await assertFails(updateDoc(bc, { noiDung: 'Bố sửa lời của con' }));
    await assertFails(updateDoc(bc, { trangThai: 'xong' }));
    await assertFails(deleteDoc(bc));
  });

  it('phụ huynh lạ không chạm được vào báo cáo của trẻ khác', async () => {
    await assertFails(updateDoc(doc(nhu(PH2), 'hocSinh', HS1, 'baoCao', 'bc1'), {
      nhanXetPhuHuynh: 'Xin chào',
    }));
  });
});

describe('Thời khóa biểu', () => {
  it('cả học sinh lẫn phụ huynh đã nối đều xếp được tiết', async () => {
    const tiet = {
      hocSinhId: HS1, thu: 3, tiet: 2, buoi: 'sang', monId: 'm_toan', loai: 'trenLop',
    };
    await assertSucceeds(setDoc(doc(nhu(HS1), 'hocSinh', HS1, 'tietHoc', 't2'), tiet));
    await assertSucceeds(setDoc(doc(nhu(PH1), 'hocSinh', HS1, 'tietHoc', 't3'), tiet));
    await assertFails(setDoc(doc(nhu(PH2), 'hocSinh', HS1, 'tietHoc', 't4'), tiet));
  });
});

describe('Nhắc nhở', () => {
  const loiNhac = (den) => ({
    tuId: PH1, denId: den, noiDung: 'Làm nốt bài nhé', taoLuc: new Date(), daDoc: false,
  });

  it('phụ huynh đã nối gửi được lời nhắc cho con', async () => {
    await assertSucceeds(
      setDoc(doc(nhu(PH1), 'hocSinh', HS1, 'nhacNho', 'nn2'), loiNhac(HS1)),
    );
  });

  it('người lạ không gửi được lời nhắc vào máy trẻ khác', async () => {
    await assertFails(
      setDoc(doc(nhu(PH2), 'hocSinh', HS1, 'nhacNho', 'nn3'), loiNhac(HS1)),
    );
  });

  it('không ai ký tên người khác lên lời nhắc của mình', async () => {
    await assertFails(
      setDoc(doc(nhu(PH1), 'hocSinh', HS1, 'nhacNho', 'nn4'), {
        ...loiNhac(HS1), tuId: PH2,
      }),
    );
  });

  it('chỉ học sinh đánh dấu đã đọc, phụ huynh không đánh dấu hộ', async () => {
    await assertSucceeds(
      updateDoc(doc(nhu(HS1), 'hocSinh', HS1, 'nhacNho', 'nn1'), { daDoc: true }),
    );
    await assertFails(
      updateDoc(doc(nhu(PH1), 'hocSinh', HS1, 'nhacNho', 'nn1'), { daDoc: true }),
    );
  });
});

describe('Danh mục dùng chung', () => {
  it('chỉ quản trị sửa được môn học và thầy cô', async () => {
    await assertSucceeds(
      setDoc(doc(nhu(QT), 'monHoc', 'm_van'), { ten: 'Ngữ văn', vietTat: 'Văn' }),
    );
    await assertFails(
      setDoc(doc(nhu(HS1), 'monHoc', 'm_gia'), { ten: 'Môn giả', vietTat: 'Giả' }),
    );
    await assertFails(
      setDoc(doc(nhu(PH1), 'giaoVien', 'gv_gia'), {
        hoTen: 'Thầy giả', monId: 'm_toan', loai: 'trenLop',
      }),
    );
  });
});
