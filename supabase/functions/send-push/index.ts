import { JWT } from "npm:google-auth-library@^9.0.0"
import { createClient } from "npm:@supabase/supabase-js@2.39.0"

// Deno 환경 변수에서 Firebase 서비스 계정 키 JSON 및 Supabase 접속 정보를 획득합니다.
const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

// [차단 정책] true면 프로필 조회 실패 시에도 발송하지 않음(fail-closed).
const FAIL_CLOSED_ON_DB_ERROR = true;

// 앱 assets/translations/*.json의 문구와 동일하게 유지한다.
const NOTIFICATION_TEMPLATES: Record<string, Record<string, { title: string; body: string }>> = {
  territory_attack: {
    ko: { title: "⚠️ 영토 변경 알림", body: "다른 플레이어가 해당 구역을 점령하였습니다." },
    en: { title: "⚠️ Alert: Zone Lost!", body: "Another player has taken over your zone!" },
    zh: { title: "⚠️ 领土变更通知", body: "其他玩家已占用该区域。" },
    zh_TW: { title: "⚠️ 領土變更通知", body: "其他玩家已佔用該區域。" },
    ja: { title: "⚠️ 領土変更通知", body: "他のプレイヤーがこのエリアを占領しました。" },
    es: { title: "⚠️ Alerta: ¡Zona Perdida!", body: "¡Otro jugador ha tomado tu zona!" },
    fr: { title: "⚠️ Alerte: Zone Perdue !", body: "Un autre joueur a pris votre zone !" },
    de: { title: "⚠️ Alarm: Zone verloren!", body: "Ein anderer Spieler hat Ihre Zone übernommen!" },
    pt: { title: "⚠️ Alerta: Área Perdida!", body: "Outro jogador tomou sua área !" },
  },
  satellite_complete: {
    ko: { title: "영토 확보 알림", body: "✓ 영토 확보 완료. 새로운 영토를 획득하였습니다." },
    en: { title: "Territory Secured Notification", body: "✓ Territory capture complete! Secured new territory." },
    zh: { title: "领土获取通知", body: "✓ 领土获取完成。已获得新的领土。" },
    zh_TW: { title: "領土獲取通知", body: "✓ 領土獲取完成。已獲得新的領土。" },
    ja: { title: "領土獲得通知", body: "✓ 領土獲得完了。新しい領土を獲得しました。" },
    es: { title: "Alerta de Territorio Asegurado", body: "✓ ¡Captura completada! Nuevo territorio asegurado." },
    fr: { title: "Alerte de Territoire Sécurisé", body: "✓ Capture complétée ! Nouveau territoire sécurisé." },
    de: { title: "Territorium gesichert", body: "✓ Einnahme abgeschlossen! Neues Territorium gesichert." },
    pt: { title: "Alerta de Território Garantido", body: "✓ Captura concluída! Novo território garantido." },
  },
};

type GateResult = { allowed: boolean; reason: string; language?: string };

function normalizeLanguageCode(language: string | null | undefined): string {
  const normalized = String(language ?? "ko").trim().toLowerCase().replace(/-/g, "_");
  if (normalized.startsWith("zh")) {
    return normalized.includes("tw") || normalized.includes("hant") ? "zh_TW" : "zh";
  }
  return normalized.split("_")[0] || "ko";
}

function resolveNotificationTemplate(
  template: string | undefined,
  language: string | null | undefined,
): { title: string; body: string } | null {
  if (!template) return null;
  const templates = NOTIFICATION_TEMPLATES[template];
  if (!templates) return null;
  const code = normalizeLanguageCode(language);
  return templates[code] ?? templates.ko ?? templates.en ?? null;
}

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
      .select("is_notifications_enabled, language")
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

    return { allowed: true, reason: "ok", language: profile.language ?? "ko" };
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
    const { fcm_token, topic, title, body, data_payload, user_id, localized_notifications, template } = rawBody;

    if (!fcm_token && !topic && !localized_notifications) {
      throw new Error("fcm_token, topic 또는 localized_notifications 파라미터 중 하나는 필수입니다.");
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
    // CASE 0: 언어별 공지 — 언어 토픽(lang_*)으로 각 언어 메시지를 직접 발송
    // 앱이 알림 설정/언어에 따라 lang_* 토픽을 구독·해제하므로 개인 게이트는 생략한다.
    // =========================================================================
    if (localized_notifications && typeof localized_notifications === "object") {
      const entries = Object.entries(localized_notifications)
        .map(([lang, value]) => {
          const item = value as { title?: unknown; body?: unknown };
          return {
            lang: String(lang).trim(),
            title: typeof item?.title === "string" ? item.title.trim() : "",
            body: typeof item?.body === "string" ? item.body.trim() : "",
          };
        })
        .filter((item) => /^[a-zA-Z_]{2,10}$/.test(item.lang) && item.title && item.body);

      if (entries.length === 0) {
        throw new Error("localized_notifications에 유효한 제목/본문이 없습니다.");
      }

      const results = await Promise.all(
        entries.map(async (item) => {
          const languageTopic = `lang_${item.lang}`;
          const fcmResponse = await sendSingleFcmMessage(
            serviceAccount.project_id,
            access_token,
            { topic: languageTopic },
            item.title,
            item.body,
            data_payload,
          );

          if (!fcmResponse.ok) {
            const errText = await fcmResponse.text();
            return { lang: item.lang, topic: languageTopic, ok: false, error: errText };
          }

          const result = await fcmResponse.json();
          return { lang: item.lang, topic: languageTopic, ok: true, result };
        }),
      );

      const successCount = results.filter((result) => result.ok).length;
      return new Response(JSON.stringify({
        success: true,
        localized: true,
        total_languages: entries.length,
        sent_count: successCount,
        results,
      }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
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

      const templateContent = resolveNotificationTemplate(template, gate.language);
      const messageTitle = templateContent?.title ?? title;
      const messageBody = templateContent?.body ?? body;

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
        messageTitle,
        messageBody,
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
        .select("id, language")
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
      const sendPromises = recipients.map((user) => {
        const templateContent = resolveNotificationTemplate(template, user.language);
        return sendSingleFcmMessage(
          serviceAccount.project_id,
          access_token,
          { topic: `user_${user.id}` },
          templateContent?.title ?? title,
          templateContent?.body ?? body,
          data_payload,
        );
      });

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
