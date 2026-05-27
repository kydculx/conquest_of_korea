import { JWT } from "npm:google-auth-library@^9.0.0"

// Deno 환경 변수에서 Firebase 서비스 계정 키 JSON을 획득합니다.
const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");

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
    const { fcm_token, title, body, data_payload } = await req.json();

    if (!fcm_token) {
      throw new Error("fcm_token 파라미터가 누락되었습니다.");
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

    // 3. FCM v1 API 호출로 푸시 전송 (notification 객체 필수 포함)
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;
    const fcmResponse = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${access_token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: fcm_token,
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
