import { JWT } from "npm:google-auth-library@^9.0.0"
import { createClient } from "npm:@supabase/supabase-js@2.39.0"

// Deno 환경 변수에서 Firebase 서비스 계정 키 JSON을 획득합니다.
const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

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
    const { fcm_token, topic, title, body, data_payload } = await req.json();

    if (!fcm_token && !topic) {
      throw new Error("fcm_token 또는 topic 파라미터 중 하나는 필수입니다.");
    }

    // 1대1 개인 알림(토픽 'user_userId') DB 수준 차단 필터링 개시
    if (topic && topic.startsWith("user_")) {
      const userId = topic.replace("user_", "");
      if (supabaseUrl && supabaseServiceKey && userId) {
        try {
          const supabase = createClient(supabaseUrl, supabaseServiceKey);
          const { data: profile, error } = await supabase
            .from("profiles")
            .select("is_notifications_enabled, notif_territory_attack, notif_satellite_complete, notif_system_notice")
            .eq("id", userId)
            .maybeSingle();

          if (error) {
            console.error(`⚠️ DB 프로필 조회 실패 (user: ${userId}):`, error.message);
          } else if (profile) {
            // 마스터 알림 스위치 꺼짐 여부
            if (profile.is_notifications_enabled === false) {
              console.log(`🔔 [알림 마스터 차단] 요원(${userId})의 마스터 알림 비활성화로 푸시 취소`);
              return new Response(JSON.stringify({ success: true, filtered: true, reason: "master_disabled" }), {
                headers: {
                  "Content-Type": "application/json",
                  "Access-Control-Allow-Origin": "*",
                },
              });
            }

            // 개별 알림 타입 쿼리
            const notificationType = data_payload?.type || (data_payload && data_payload.type);
            if (notificationType) {
              let shouldFilter = false;
              let filterReason = "";

              if (notificationType === "territory_attack" && profile.notif_territory_attack === false) {
                shouldFilter = true;
                filterReason = "territory_attack_disabled";
              } else if (notificationType === "satellite_complete" && profile.notif_satellite_complete === false) {
                shouldFilter = true;
                filterReason = "satellite_complete_disabled";
              } else if (notificationType === "system_notice" && profile.notif_system_notice === false) {
                shouldFilter = true;
                filterReason = "system_notice_disabled";
              }

              if (shouldFilter) {
                console.log(`🔔 [알림 세부 차단] 요원(${userId})의 '${notificationType}' 알림 비활성화로 푸시 취소 (${filterReason})`);
                return new Response(JSON.stringify({ success: true, filtered: true, reason: filterReason }), {
                  headers: {
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*",
                  },
                });
              }
            }
          }
        } catch (dbErr) {
          console.error("⚠️ 알림 필터링 DB 쿼리 중 예외 발생:", (dbErr as Error).message);
        }
      }
    }

    // 1. google-auth-library를 사용해 Firebase Admin용 JWT 클라이언트 생성 (Deno & Node 호환)
    const jwtClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });

    // 2. Google OAuth Access Token 발급 요청
    const tokenResponse = await jwtClient.authorize();
    const access_token = tokenResponse.access_token;

    if (!access_token) {
      throw new Error("Google OAuth 토큰 획득에 실패했습니다.");
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
            title: title || "전술 경보",
            body: body || "새로운 작전 명령이 도착했습니다.",
          },
          data: data_payload || {},
          android: {
            priority: "high",
          },
          apns: {
            payload: {
              aps: {
                alert: {
                  title: title || "전술 경보",
                  body: body || "새로운 작전 명령이 도착했습니다.",
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
