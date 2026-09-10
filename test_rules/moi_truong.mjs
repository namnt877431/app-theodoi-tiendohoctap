import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';

// Tính theo vị trí file này, không theo thư mục đang chạy — bộ kiểm thử phải
// chạy được cả khi gọi từ gốc dự án lẫn từ trong test_rules.
const goc = join(dirname(fileURLToPath(import.meta.url)), '..');

/// Ba nhân vật xuyên suốt bộ kiểm thử:
///   ph1 là phụ huynh của hs1, ph2 là người lạ, qt là quản trị.
export const PH1 = 'ph1';
export const PH2 = 'ph2';
export const HS1 = 'hs1';
export const HS2 = 'hs2';
export const QT = 'qt1';

export async function moiTruong() {
  return initializeTestEnvironment({
    projectId: 'demo-solienlac',
    firestore: {
      rules: readFileSync(join(goc, 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
}

/// Nạp dữ liệu nền, bỏ qua luật — đây là trạng thái coi như đã có sẵn,
/// không phải thứ đang được kiểm thử.
export async function napNen(env, { conCuaPh1 = [HS1] } = {}) {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const { doc, setDoc } = await import('firebase/firestore');

    await setDoc(doc(db, 'nguoiDung', PH1), {
      hoTen: 'Phụ huynh Một', vaiTro: 'phuHuynh', conIds: conCuaPh1, hoatDong: true,
    });
    await setDoc(doc(db, 'nguoiDung', PH2), {
      hoTen: 'Phụ huynh Hai', vaiTro: 'phuHuynh', conIds: [], hoatDong: true,
    });
    await setDoc(doc(db, 'nguoiDung', HS1), {
      hoTen: 'Học sinh Một', vaiTro: 'hocSinh', lop: '9A2', conIds: [], hoatDong: true,
    });
    await setDoc(doc(db, 'nguoiDung', HS2), {
      hoTen: 'Học sinh Hai', vaiTro: 'hocSinh', lop: '8A4', conIds: [], hoatDong: true,
    });
    await setDoc(doc(db, 'nguoiDung', QT), {
      hoTen: 'Quản trị', vaiTro: 'quanTri', conIds: [], hoatDong: true,
    });

    await setDoc(doc(db, 'monHoc', 'm_toan'), { ten: 'Toán', vietTat: 'Toán' });

    for (const hs of [HS1, HS2]) {
      await setDoc(doc(db, 'hocSinh', hs, 'baoCao', 'bc1'), {
        hocSinhId: hs, ngay: new Date(), khoaNgay: '2026-09-10',
        loai: 'trenLop', monId: 'm_toan', noiDung: 'Bài 12 trang 47',
        trangThai: 'dangLam', anh: [], phuHuynhDaXem: false, taoLuc: new Date(),
      });
      await setDoc(doc(db, 'hocSinh', hs, 'tietHoc', 't1'), {
        hocSinhId: hs, thu: 2, tiet: 1, buoi: 'sang', monId: 'm_toan', loai: 'trenLop',
      });
      await setDoc(doc(db, 'hocSinh', hs, 'nhacNho', 'nn1'), {
        tuId: PH1, denId: hs, noiDung: 'Làm bài nhé', taoLuc: new Date(), daDoc: false,
      });
    }
  });
}

/// Mã mời còn hiệu lực, trỏ tới học sinh đã cho.
export async function napMa(env, ma, hocSinhId, { daDung = false, phutConLai = 15 } = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const { doc, setDoc } = await import('firebase/firestore');
    await setDoc(doc(ctx.firestore(), 'maMoi', ma), {
      hocSinhId,
      daDung,
      hetHan: new Date(Date.now() + phutConLai * 60 * 1000),
    });
  });
}
