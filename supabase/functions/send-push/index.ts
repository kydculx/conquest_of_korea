import { JWT } from "npm:google-auth-library@^9.0.0"
import { createClient } from "npm:@supabase/supabase-js@2.39.0"

// Deno 환경 변수에서 Firebase 서비스 계정 키 JSON을 획득합니다.
const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

// [차단 정책] true면 프로필 조회 실패 시에도 발송하지 않음(fail-closed).
// false면 조회 실패 시 발송 진행(fail-open, 기존 동작).
const FAIL_CLOSED_ON_DB_ERROR = true;

type GateResult = { allowed: boolean; reason: string };

async function checkUserGate(
  supabaseUrl: string,
  supabaseServiceKey: string,
  userId: string,
  dataPayload: Record<string, unknown> | undefined,
): Promise<GateResult> {
  try {
    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const { data: profile, error } = await supabase
      .from("profiles")
      .select("is_notifications_enabled, notif_territory_attack, notif_satellite_complete, notif_system_notice")
      .eq("id", userId)
      .maybeSingle();

    if (error || !profile) {
      console.error(`DB profile lookup failed (user: ${userId}):`, error?.message ?? "not found");
      return FAIL_CLOSED_ON_DB_ERROR
        ? { allowed: false, reason: "db_unavailable" }
        : { allowed: true, reason: "db_unavailable_passthrough" };
    }

    if (profile.is_notifications_enabled !== true) {
      console.log(`Push blocked: master disabled (user: ${userId})`);
      return { allowed: false, reason: "master_disabled" };
    }

    const notificationType = dataPayload?.type as string | undefined;
    if (notificationType === "territory_attack" && profile.notif_territory_attack !== true) {
      return { allowed: false, reason: "territory_attack_disabled" };
    }
    if (notificationType === "satellite_complete" && profile.notif_satellite_complete !== true) {
      return { allowed: false, reason: "satellite_complete_disabled" };
    }
    if (notificationType === "system_notice" && profile.notif_system_notice !== true) {
      return { allowed: false, reason: "system_notice_disabled" };
    }
    return { allowed: true, reason: "ok" };
  } catch (dbErr) {
    console.error("Push gate DB exception:", (dbErr as Error).message);
    return FAIL_CLOSED_ON_DB_ERROR
      ? { allowed: false, reason: "db_unavailable" }
      : { allowed: true, reason: "db_unavailable_passthrough" };
  }
}

async function serverUnsubscribeFromTopic(
  accessToken: string,
  fcmToken: string,
  topic: string,
): Promise<void> {
  try {
    const res = await fetch(
      `https://iid.googleapis.com/iid/v1/batchRemove`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          to: `/topics/${topic}`,
          registration_tokens: [fcmToken],
        }),
      },
    );
    if (!res.ok) {
      console.error("Server-side topic unsubscribe failed:", await res.text());
    }
  } catch (e) {
    console.error("Server-side topic unsubscribe exception:", (e as Error).message);
  }
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
    const { fcm_token, topic, title, body, data_payload, user_id } = await req.json();

    if (!fcm_token && !topic) {
      throw new Error("fcm_token 또는 topic 파라미터 중 하나는 필수입니다.");
    }

    const resolvedUserId: string | null =
      (typeof user_id === "string" && user_id.length > 0)
        ? user_id
        : (topic && topic.startsWith("user_") ? topic.replace("user_", "") : null);

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

    if (resolvedUserId && supabaseUrl && supabaseServiceKey) {
      const gate = await checkUserGate(supabaseUrl, supabaseServiceKey, resolvedUserId, data_payload);
      if (!gate.allowed) {
        if (fcm_token && topic) {
          await serverUnsubscribeFromTopic(access_token, fcm_token, topic);
        }
        return new Response(JSON.stringify({ success: true, filtered: true, reason: gate.reason }), {
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        });
      }
    }

    // 3. FCM v1 API 호출로 푸시 전송
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;
    
    // 대상 유형 지정 (token 또는 topic)
    const messageTarget: Record<string, string> = {};
    if (fcm_token) {
      messageTarget.token = fcm_token;
    } else if (topic) {
      messageTarget.topic = topic;
    }

    const fcmResponse = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${access_token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          ...messageTarget,
          notification: {
            title: title || "점령 알림",
            body: body || "새로운 소식이 도착했습니다.",
          },
          data: data_payload || {},
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
    return new Response(JSON.stringify({ success: false, error: (error as Error).message }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }
});
