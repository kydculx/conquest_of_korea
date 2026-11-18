import { createClient } from "npm:@supabase/supabase-js@2.39.0"

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const NOTIFY_TO = "kydculx@gmail.com";
const NOTIFY_FROM = "찜! 모험 문의 <onboarding@resend.dev>";
const MAX_PER_HOUR = 5;
const CATEGORIES = new Set(["bug", "feature", "account", "etc"]);

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const CATEGORY_LABELS: Record<string, string> = {
  bug: "버그 신고",
  feature: "기능 건의",
  account: "계정/데이터",
  etc: "기타",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json; charset=utf-8" },
  });
}

function toTrimmedString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function stripHeaderBreaks(value: string): string {
  return value.replace(/[\r\n]+/g, " ");
}

async function resolveUserId(authHeader: string | null): Promise<string | null> {
  const token = authHeader?.replace(/^Bearer\s+/i, "").trim();
  if (!token || !SUPABASE_URL || !SUPABASE_ANON_KEY) {
    return null;
  }
  try {
    const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: { persistSession: false },
    });
    const { data, error } = await client.auth.getUser(token);
    if (error) {
      console.warn("문의 사용자 확인 실패:", error.message);
      return null;
    }
    return data.user?.id ?? null;
  } catch (error) {
    console.warn("문의 사용자 확인 예외:", error);
    return null;
  }
}

async function sendNotificationEmail(payload: {
  category: string;
  title: string;
  content: string;
  email: string;
  locale: string;
  appVersion: string;
  platform: string;
  userId: string | null;
  inquiryId: string;
}): Promise<void> {
  if (!RESEND_API_KEY) {
    console.warn("RESEND_API_KEY가 없어 문의 알림 메일을 건너뜁니다.");
    return;
  }

  const categoryLabel = CATEGORY_LABELS[payload.category] ?? payload.category;
  const lines = [
    "앱에서 새 문의가 접수됐습니다.",
    "",
    `유형: ${categoryLabel}`,
    `제목: ${payload.title}`,
    `회신 이메일: ${payload.email}`,
    `언어: ${payload.locale || "-"}`,
    `앱 버전: ${payload.appVersion || "-"}`,
    `플랫폼: ${payload.platform || "-"}`,
    `사용자 ID: ${payload.userId ?? "비로그인"}`,
    `문의 ID: ${payload.inquiryId}`,
    "",
    "내용:",
    payload.content,
  ];

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: NOTIFY_FROM,
      to: [NOTIFY_TO],
      subject: `[찜! 모험] ${stripHeaderBreaks(categoryLabel)} - ${stripHeaderBreaks(payload.title)}`,
      text: lines.join("\n"),
    }),
  });

  if (!response.ok) {
    throw new Error(`메일 발송 실패: ${await response.text()}`);
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return jsonResponse({ success: false, error: "method_not_allowed" }, 405);
  }

  try {
    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      throw new Error("Supabase 서비스 설정이 없습니다.");
    }

    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") {
      return jsonResponse({ success: false, error: "invalid_body" }, 400);
    }

    const record = body as Record<string, unknown>;
    const category = toTrimmedString(record.category) || "etc";
    const title = toTrimmedString(record.title);
    const content = toTrimmedString(record.content);
    const email = toTrimmedString(record.email).toLowerCase();
    const locale = toTrimmedString(record.locale).slice(0, 20);
    const appVersion = toTrimmedString(record.app_version).slice(0, 40);
    const platform = toTrimmedString(record.platform).slice(0, 20);

    if (!CATEGORIES.has(category)) {
      return jsonResponse({ success: false, error: "invalid_category" }, 400);
    }
    if (title.length < 2 || title.length > 120) {
      return jsonResponse({ success: false, error: "invalid_title" }, 400);
    }
    if (content.length < 5 || content.length > 5000) {
      return jsonResponse({ success: false, error: "invalid_content" }, 400);
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254) {
      return jsonResponse({ success: false, error: "invalid_email" }, 400);
    }

    const userId = await resolveUserId(req.headers.get("Authorization"));
    const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false },
    });

    const since = new Date(Date.now() - 60 * 60 * 1000).toISOString();
    const recentQuery = admin
      .from("user_inquiries")
      .select("id", { count: "exact", head: true })
      .gte("created_at", since);
    const { count, error: countError } = await (userId
      ? recentQuery.eq("user_id", userId)
      : recentQuery.eq("email", email));

    if (countError) throw countError;
    if ((count ?? 0) >= MAX_PER_HOUR) {
      return jsonResponse({ success: false, error: "rate_limited" }, 429);
    }

    const { data: inserted, error: insertError } = await admin
      .from("user_inquiries")
      .insert({
        user_id: userId,
        email,
        category,
        title,
        content,
        locale: locale || null,
        app_version: appVersion || null,
        platform: platform || null,
      })
      .select("id")
      .single();

    if (insertError) throw insertError;

    try {
      await sendNotificationEmail({
        category,
        title,
        content,
        email,
        locale,
        appVersion,
        platform,
        userId,
        inquiryId: String(inserted?.id ?? ""),
      });
    } catch (mailError) {
      console.error("문의 알림 메일 발송 실패:", mailError);
    }

    return jsonResponse({ success: true, id: inserted?.id ?? null });
  } catch (error) {
    console.error("문의 접수 실패:", error);
    return jsonResponse({ success: false, error: "server_error" }, 500);
  }
});
