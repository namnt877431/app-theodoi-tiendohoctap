import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, getDocs, collection } from 'firebase/firestore';

import { moiTruong, napNen, PH1, PH2, HS1, HS2, QT } from './moi_truong.mjs';

let env;
before(async () => { env = await moiTruong(); });
after(async () => { await env.cleanup(); });
beforeEach(async () => { await napNen(env); });

const nhu = (uid) => env.authenticatedContext(uid).firestore();
const khach = () => env.unauthenticatedContext().firestore();

describe('Ai đọc được dữ liệu học tập', () => {
  it('phụ huynh đã nối đọc được báo cáo của con mình', async () => {
    await assertSucceeds(getDoc(doc(nhu(PH1), 'hocSinh', HS1, 'baoCao', 'bc1')));
  });

  it('phụ huynh lạ KHÔNG đọc được báo cáo của học sinh không phải con mình', async () => {
    await assertFails(getDoc(doc(nhu(PH2), 'hocSinh', HS1, 'baoCao', 'bc1')));
  });

  it('học sinh đọc được báo cáo của mình, không đọc được của bạn', async () => {
    await assertSucceeds(getDoc(doc(nhu(HS1), 'hocSinh', HS1, 'baoCao', 'bc1')));
    await assertFails(getDoc(doc(nhu(HS1), 'hocSinh', HS2, 'baoCao', 'bc1')));
  });

  it('người chưa đăng nhập không đọc được gì', async () => {
    await assertFails(getDoc(doc(khach(), 'hocSinh', HS1, 'baoCao', 'bc1')));
    await assertFails(getDoc(doc(khach(), 'nguoiDung', HS1)));
    await assertFails(getDocs(collection(khach(), 'monHoc')));
  });

  it('truy vấn cả danh sách báo cáo cũng theo đúng quyền đó', async () => {
    // Đây mới là đường app dùng thật: nó tải cả danh sách chứ không đọc lẻ
    // từng bản ghi. Truy vấn danh sách được xét bằng luật khác với đọc lẻ.
    const ds = collection(nhu(PH1), 'hocSinh', HS1, 'baoCao');
    await assertSucceeds(getDocs(ds));
    await assertFails(getDocs(collection(nhu(PH2), 'hocSinh', HS1, 'baoCao')));
    await assertSucceeds(getDocs(collection(nhu(HS1), 'hocSinh', HS1, 'tietHoc')));
    await assertFails(getDocs(collection(nhu(HS2), 'hocSinh', HS1, 'nhacNho')));
  });

  it('quản trị đọc được của mọi học sinh', async () => {
    await assertSucceeds(getDoc(doc(nhu(QT), 'hocSinh', HS1, 'baoCao', 'bc1')));
    await assertSucceeds(getDoc(doc(nhu(QT), 'hocSinh', HS2, 'baoCao', 'bc1')));
  });

  it('thời khóa biểu và nhắc nhở đi theo cùng một quyền', async () => {
    await assertSucceeds(getDoc(doc(nhu(PH1), 'hocSinh', HS1, 'tietHoc', 't1')));
    await assertSucceeds(getDoc(doc(nhu(PH1), 'hocSinh', HS1, 'nhacNho', 'nn1')));
    await assertFails(getDoc(doc(nhu(PH2), 'hocSinh', HS1, 'tietHoc', 't1')));
    await assertFails(getDoc(doc(nhu(PH2), 'hocSinh', HS1, 'nhacNho', 'nn1')));
  });
});

describe('Hồ sơ người dùng', () => {
  it('phụ huynh đọc được hồ sơ con mình, không đọc được hồ sơ trẻ khác', async () => {
    await assertSucceeds(getDoc(doc(nhu(PH1), 'nguoiDung', HS1)));
    await assertFails(getDoc(doc(nhu(PH1), 'nguoiDung', HS2)));
  });

  it('chỉ quản trị mới liệt kê được toàn bộ tài khoản', async () => {
    await assertSucceeds(getDocs(collection(nhu(QT), 'nguoiDung')));
    await assertFails(getDocs(collection(nhu(PH1), 'nguoiDung')));
  });

  it('ai đã đăng nhập cũng đọc được danh mục môn học', async () => {
    await assertSucceeds(getDocs(collection(nhu(HS1), 'monHoc')));
  });
});
