import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc, getDoc, arrayUnion } from 'firebase/firestore';

import { moiTruong, napNen, napMa, PH1, PH2, HS1, HS2, QT } from './moi_truong.mjs';

let env;
before(async () => { env = await moiTruong(); });
after(async () => { await env.cleanup(); });
beforeEach(async () => { await napNen(env); });

const nhu = (uid) => env.authenticatedContext(uid).firestore();

describe('Nối phụ huynh với con bằng mã mời', () => {
  it('không có mã thì không tự thêm con vào danh sách của mình', async () => {
    await assertFails(updateDoc(doc(nhu(PH2), 'nguoiDung', PH2), {
      conIds: arrayUnion(HS1),
    }));
  });

  it('bịa một mã không tồn tại cũng không nối được', async () => {
    await assertFails(updateDoc(doc(nhu(PH2), 'nguoiDung', PH2), {
      conIds: arrayUnion(HS1),
      maMoiDaDung: '000000',
    }));
  });

  it('mã hợp lệ nhưng trỏ tới học sinh khác thì không nối được đứa mình muốn', async () => {
    await napMa(env, '111111', HS2);
    await assertFails(updateDoc(doc(nhu(PH2), 'nguoiDung', PH2), {
      conIds: arrayUnion(HS1),
      maMoiDaDung: '111111',
    }));
  });

  it('mã đã dùng rồi thì không nối được nữa', async () => {
    await napMa(env, '222222', HS1, { daDung: true });
    await assertFails(updateDoc(doc(nhu(PH2), 'nguoiDung', PH2), {
      conIds: arrayUnion(HS1),
      maMoiDaDung: '222222',
    }));
  });

  it('mã hết hạn thì không nối được', async () => {
    await napMa(env, '333333', HS1, { phutConLai: -1 });
    await assertFails(updateDoc(doc(nhu(PH2), 'nguoiDung', PH2), {
      conIds: arrayUnion(HS1),
      maMoiDaDung: '333333',
    }));
  });

  it('mã đúng, còn hạn, chưa dùng thì nối được', async () => {
    await napMa(env, '444444', HS1);
    await assertSucceeds(updateDoc(doc(nhu(PH2), 'nguoiDung', PH2), {
      conIds: arrayUnion(HS1),
      maMoiDaDung: '444444',
    }));

    const sau = await getDoc(doc(nhu(PH2), 'nguoiDung', PH2));
    if (!sau.data().conIds.includes(HS1)) {
      throw new Error('Nối xong mà conIds không có học sinh');
    }
  });

  it('một mã chỉ mở đúng một đứa, không lén thêm hai', async () => {
    await napMa(env, '555555', HS1);
    await assertFails(updateDoc(doc(nhu(PH2), 'nguoiDung', PH2), {
      conIds: [HS1, HS2],
      maMoiDaDung: '555555',
    }));
  });

  it('bỏ theo dõi một đứa thì không cần mã', async () => {
    await assertSucceeds(updateDoc(doc(nhu(PH1), 'nguoiDung', PH1), { conIds: [] }));
  });
});

describe('Mã mời', () => {
  it('học sinh chỉ sinh được mã cho chính mình', async () => {
    const hetHan = new Date(Date.now() + 15 * 60 * 1000);
    await assertSucceeds(setDoc(doc(nhu(HS1), 'maMoi', '666666'), {
      hocSinhId: HS1, hetHan, daDung: false,
    }));
    await assertFails(setDoc(doc(nhu(HS1), 'maMoi', '777777'), {
      hocSinhId: HS2, hetHan, daDung: false,
    }));
  });

  it('không ai tạo sẵn một mã đã đánh dấu là dùng rồi', async () => {
    await assertFails(setDoc(doc(nhu(HS1), 'maMoi', '888888'), {
      hocSinhId: HS1, hetHan: new Date(Date.now() + 900000), daDung: true,
    }));
  });
});

describe('Đăng ký và tự nâng quyền', () => {
  const moi = 'nguoi_moi';

  it('tự tạo hồ sơ cho chính mình khi đăng ký', async () => {
    await assertSucceeds(setDoc(doc(nhu(moi), 'nguoiDung', moi), {
      hoTen: 'Người Mới', vaiTro: 'phuHuynh', conIds: [], hoatDong: true,
    }));
  });

  it('không tạo được hồ sơ cho người khác', async () => {
    await assertFails(setDoc(doc(nhu(moi), 'nguoiDung', 'ai_do'), {
      hoTen: 'Ai Đó', vaiTro: 'phuHuynh', conIds: [], hoatDong: true,
    }));
  });

  it('không ai tự phong mình làm quản trị', async () => {
    await assertFails(setDoc(doc(nhu(moi), 'nguoiDung', moi), {
      hoTen: 'Kẻ Gian', vaiTro: 'quanTri', conIds: [], hoatDong: true,
    }));
    await assertFails(updateDoc(doc(nhu(PH1), 'nguoiDung', PH1), { vaiTro: 'quanTri' }));
  });

  it('không ai đăng ký kèm sẵn một danh sách con', async () => {
    await assertFails(setDoc(doc(nhu(moi), 'nguoiDung', moi), {
      hoTen: 'Kẻ Gian', vaiTro: 'phuHuynh', conIds: [HS1], hoatDong: true,
    }));
  });

  it('người bị khóa không tự mở khóa cho mình', async () => {
    await assertFails(updateDoc(doc(nhu(PH1), 'nguoiDung', PH1), { hoatDong: false }));
  });

  it('sửa thông tin cá nhân của chính mình thì được', async () => {
    await assertSucceeds(updateDoc(doc(nhu(PH1), 'nguoiDung', PH1), {
      hoTen: 'Phụ Huynh Một Đổi Tên', soDienThoai: '0900 000 000',
    }));
  });

  it('quản trị khóa được tài khoản và gán con bằng tay', async () => {
    await assertSucceeds(updateDoc(doc(nhu(QT), 'nguoiDung', PH2), { hoatDong: false }));
    await assertSucceeds(updateDoc(doc(nhu(QT), 'nguoiDung', PH2), {
      conIds: arrayUnion(HS2),
    }));
  });
});
