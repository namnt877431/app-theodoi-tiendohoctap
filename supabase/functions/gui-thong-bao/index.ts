// Edge Function gui-thong-bao — nhận một hàng của bảng `thong_bao` (do trigger
// tb_goi_edge_function gửi qua pg_net), tra token các máy của người nhận rồi
// đẩy qua FCM HTTP v1. Firebase ở đây chỉ là ống gửi; dữ liệu vẫn ở Supabase.
//
// Secrets cần đặt (Dashboard → Edge Functions → Secrets):
//   FCM_SERVICE_ACCOUNT  — nội dung file JSON service account của Firebase
//   MA_BI_MAT_WEBHOOK    — chuỗi giống hệt hàng `ma_bi_mat_webhook` trong bảng cau_hinh
// SUPABASE_URL và SUPABASE_SERVICE_ROLE_KEY được Supabase cấp sẵn.
//
// Triển khai với "Verify JWT" TẮT: pg_net gọi thẳng không kèm JWT, xác thực
// bằng header x-ma-bi-mat thay vào đó.

import { createClient } from "npm:@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "npm:jose@5";

type ThongBao = {
  id: string;
  den_id: string;
  tieu_de: string;
  noi_dung: string;
  du_lieu?: Record<string, unknown>;
};

const taiKhoanDichVu = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT") ?? "{}");
const maBiMat = Deno.env.get("MA_BI_MAT_WEBHOOK") ?? "";

const db = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// Access token của Google sống một giờ; giữ lại để mỗi thông báo không phải
// ký JWT và gọi OAuth thêm một lượt.
let tokenGoogle: { token: string; hetHan: number } | null = null;

async function layTokenGoogle(): Promise<string> {
  if (tokenGoogle && tokenGoogle.hetHan > Date.now() + 60_000) {
    return tokenGoogle.token;
  }
  const khoa = await importPKCS8(taiKhoanDichVu.private_key, "RS256");
  const jwt = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256" })
    .setIssuer(taiKhoanDichVu.client_email)
    .setAudience(taiKhoanDichVu.token_uri)
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(khoa);

  const r = await fetch(taiKhoanDichVu.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!r.ok) throw new Error(`OAuth Google ${r.status}: ${await r.text()}`);
  const j = await r.json();
  tokenGoogle = {
    token: j.access_token,
    hetHan: Date.now() + Number(j.expires_in ?? 3600) * 1000,
  };
  return tokenGoogle.token;
}

/// FCM chỉ nhận `data` là chuỗi → chuỗi.
function duLieuChuoi(d: Record<string, unknown> | undefined) {
  const ra: Record<string, string> = {};
  for (const [k, v] of Object.entries(d ?? {})) {
    if (v !== null && v !== undefined) ra[k] = String(v);
  }
  return ra;
}

async function guiMotMay(tb: ThongBao, token: string): Promise<string | null> {
  const r = await fetch(
    `https://fcm.googleapis.com/v1/projects/${taiKhoanDichVu.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${await layTokenGoogle()}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: tb.tieu_de, body: tb.noi_dung },
          data: duLieuChuoi(tb.du_lieu),
          android: {
            priority: "high",
            notification: { sound: "default", default_vibrate_timings: true },
          },
        },
      }),
    },
  );
  if (r.ok) return null;

  const loi = await r.text();
  // Máy gỡ app hoặc token cũ: xóa để lần sau khỏi gửi vào chỗ trống.
  if (r.status === 404 || loi.includes("UNREGISTERED") || loi.includes("INVALID_ARGUMENT")) {
    await db.from("thiet_bi").delete().eq("token", token);
    return null;
  }
  return `${r.status} ${loi.slice(0, 200)}`;
}

Deno.serve(async (req) => {
  if (maBiMat && req.headers.get("x-ma-bi-mat") !== maBiMat) {
    return new Response("Sai mã bí mật", { status: 401 });
  }
  if (!taiKhoanDichVu.private_key) {
    return new Response("Chưa đặt secret FCM_SERVICE_ACCOUNT", { status: 500 });
  }

  const tb = (await req.json()) as ThongBao;
  const { data: mays, error } = await db
    .from("thiet_bi")
    .select("token")
    .eq("nguoi_dung_id", tb.den_id);
  if (error) return new Response(error.message, { status: 500 });

  const loi: string[] = [];
  for (const { token } of mays ?? []) {
    const l = await guiMotMay(tb, token);
    if (l) loi.push(l);
  }
  if (!mays?.length) loi.push("người nhận chưa có máy nào đăng ký");

  await db
    .from("thong_bao")
    .update({
      da_gui_luc: new Date().toISOString(),
      loi: loi.length ? loi.join("; ") : null,
    })
    .eq("id", tb.id);

  return new Response(JSON.stringify({ so_may: mays?.length ?? 0, loi }), {
    headers: { "Content-Type": "application/json" },
  });
});
