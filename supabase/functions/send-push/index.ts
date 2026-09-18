import { JWT } from "npm:google-auth-library@^9.0.0"
import { createClient } from "npm:@supabase/supabase-js@2.39.0"

// Deno 환경 변수에서 Firebase 서비스 계정 키 JSON 및 Supabase 접속 정보를 획득합니다.
const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

// [차단 정책] true면 프로필 조회 실패 시에도 발송하지 않음(fail-closed).
const FAIL_CLOSED_ON_DB_ERROR = true;

type GateResult = { allowed: boolean; reason: string };

/**
 * 단일 사용자의 메인 알림 수신 동의(is_notifications_enabled) 상태를 DB에서 조회하여 발송 허용 여부를 판정합니다.
 */
async function checkUserGate(
  supabaseUrl: string,
  supabaseServiceKey: string,
  userId: string,
): Promise<GateResult> {
  try {
    const normalizedUserId = userId.trim().toLowerCase();
    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const { data: profile, error } = await supabase
      .from("profiles")
      .select("is_notifications_enabled")
      .eq("id", normalizedUserId)
      .maybeSingle();

    if (error || !profile) {
      console.error(`DB profile lookup failed (user: ${normalizedUserId}):`, error?.message ?? "not found");
      return FAIL_CLOSED_ON_DB_ERROR
        ? { allowed: false, reason: "db_unavailable" }
        : { allowed: true, reason: "db_unavailable_passthrough" };
    }

    // 마스터 알림 스위치 검사
    if (profile.is_notifications_enabled !== true) {
      console.log(`Push blocked: notifications disabled (user: ${normalizedUserId})`);
      return { allowed: false, reason: "notifications_disabled" };
    }

    return { allowed: true, reason: "ok" };
  } catch (dbErr) {
    console.error("Push gate DB exception:", (dbErr as Error).message);
    return FAIL_CLOSED_ON_DB_ERROR
      ? { allowed: false, reason: "db_unavailable" }
      : { allowed: true, reason: "db_unavailable_passthrough" };
  }
}

/**
 * FCM v1 API 단건 발송 헬퍼
 */
async function sendSingleFcmMessage(
  projectId: string,
  accessToken: string,
  target: { token?: string; topic?: string },
  title: string,
  body: string,
  dataPayload?: Record<string, unknown>,
): Promise<Response> {
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  // FCM data 필드는 반드시 string-string 형태여야 안전함
  const safeData: Record<string, string> = {};
  if (dataPayload && typeof dataPayload === "object") {
    for (const [k, v] of Object.entries(dataPayload)) {
      safeData[k] = typeof v === "string" ? v : JSON.stringify(v ?? "");
    }
  }

  return await fetch(fcmUrl, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        ...target,
        notification: {
          title: title || "점령 알림",
          body: body || "새로운 소식이 도착했습니다.",
        },
        data: safeData,
        android: {
          priority: "high",
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: title || "점령 알림",
                body: body || "새로운 소식이 도착했습니다.",
              },
              contentAvailable: true,
              sound: "default",
            },
          },
        },
      },
    }),
  });
}

Deno.serve(async (req: Request) => {
  // CORS 프리플라이트 요청 처리 (Flutter 웹/클라이언트 호출 대응)
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    if (!serviceAccountJson) {
      throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON 환경변수가 설정되지 않았습니다.");
    }

    const serviceAccount = JSON.parse(serviceAccountJson);
    const rawBody = await req.json();
    const { fcm_token, topic, title, body, data_payload, user_id } = rawBody;

    if (!fcm_token && !topic) {
      throw new Error("fcm_token 또는 topic 파라미터 중 하나는 필수입니다.");
    }

    // 개인 대상 발송 여부 판단
    const resolvedUserId: string | null =
      (typeof user_id === "string" && user_id.trim().length > 0)
        ? user_id.trim()
        : (topic && topic.startsWith("user_") ? topic.replace("user_", "").trim() : null);

    // Google OAuth Access Token 발급
    const jwtClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: [
        "https://www.googleapis.com/auth/firebase.messaging",
        "https://www.googleapis.com/auth/firebase",
      ],
    });

    const tokenResponse = await jwtClient.authorize();
    const access_token = tokenResponse.access_token;
    if (!access_token) {
      throw new Error("Google OAuth 토큰 획득에 실패했습니다.");
    }

    // =========================================================================
    // CASE 1: 1대1 개인 대상 발송 (user_id 또는 user_{uuid} 토픽 또는 fcm_token)
    // =========================================================================
    if (resolvedUserId && supabaseUrl && supabaseServiceKey) {
      const gate = await checkUserGate(supabaseUrl, supabaseServiceKey, resolvedUserId);
      if (!gate.allowed) {
        console.log(`Push filtered: ${gate.reason} (user: ${resolvedUserId})`);
        return new Response(JSON.stringify({ success: true, filtered: true, reason: gate.reason }), {
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        });
      }

      const messageTarget: Record<string, string> = {};
      if (fcm_token) {
        messageTarget.token = fcm_token;
      } else if (topic) {
        messageTarget.topic = topic;
      }

      const fcmResponse = await sendSingleFcmMessage(
        serviceAccount.project_id,
        access_token,
        messageTarget,
        title,
        body,
        data_payload,
      );

      if (!fcmResponse.ok) {
        const errText = await fcmResponse.text();
        throw new Error(`FCM 푸시 전송 실패: ${errText}`);
      }

      const result = await fcmResponse.json();
      return new Response(JSON.stringify({ success: true, result }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
    }

    // =========================================================================
    // CASE 2: 전역/그룹 토픽 브로드캐스트
    // 알림 수신에 동의한 활성 사용자들에게만 개인 토픽(user_{id})으로 안전 발송합니다.
    // =========================================================================
    if (!resolvedUserId && topic && supabaseUrl && supabaseServiceKey) {
      const supabase = createClient(supabaseUrl, supabaseServiceKey);

      // 알림이 켜져 있는 사용자 필터
      const { data: eligibleUsers, error: dbErr } = await supabase
        .from("profiles")
        .select("id")
        .eq("is_notifications_enabled", true);

      if (dbErr) {
        console.error("Eligible recipients DB query failed:", dbErr.message);
        throw new Error(`수신 대상자 조회 실패: ${dbErr.message}`);
      }

      const recipients = eligibleUsers || [];
      console.log(`Broadcast push: filtered ${recipients.length} eligible recipients`);

      if (recipients.length === 0) {
        return new Response(JSON.stringify({
          success: true,
          filtered: true,
          reason: "no_eligible_recipients",
          sent_count: 0,
        }), {
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        });
      }

      // 각 동의 사용자들의 개인 토픽(user_{id})으로 병렬 발송
      const sendPromises = recipients.map((user) =>
        sendSingleFcmMessage(
          serviceAccount.project_id,
          access_token,
          { topic: `user_${user.id}` },
          title,
          body,
          data_payload,
        )
      );

      const results = await Promise.allSettled(sendPromises);
      const successCount = results.filter((r) => r.status === "fulfilled" && (r.value as Response).ok).length;

      return new Response(JSON.stringify({
        success: true,
        broadcast: true,
        total_eligible: recipients.length,
        sent_count: successCount,
      }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
    }

    // =========================================================================
    // CASE 3: 기타 토큰 단건 발송
    // =========================================================================
    const messageTarget: Record<string, string> = {};
    if (fcm_token) {
      messageTarget.token = fcm_token;
    } else if (topic) {
      messageTarget.topic = topic;
    }

    const fcmResponse = await sendSingleFcmMessage(
      serviceAccount.project_id,
      access_token,
      messageTarget,
      title,
      body,
      data_payload,
    );

    if (!fcmResponse.ok) {
      const errText = await fcmResponse.text();
      throw new Error(`FCM 푸시 전송 실패: ${errText}`);
    }

    const result = await fcmResponse.json();
    return new Response(JSON.stringify({ success: true, result }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });

  } catch (error) {
    console.error("send-push error:", (error as Error).message);
    return new Response(JSON.stringify({ success: false, error: (error as Error).message }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }
});
