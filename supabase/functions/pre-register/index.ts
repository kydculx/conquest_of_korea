const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const NOTIFY_TO = "kydculx@gmail.com";

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}

Deno.serve(async (req: Request) => {
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
    if (!RESEND_API_KEY) {
      throw new Error("RESEND_API_KEY 환경변수가 설정되지 않았습니다.");
    }

    const { email } = await req.json();

    if (typeof email !== "string" || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) {
      return jsonResponse({ success: false, error: "invalid_email" }, 400);
    }

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "찜! 모험 사전체험 <onboarding@resend.dev>",
        to: [NOTIFY_TO],
        subject: "[찜! 모험] Android 사전체험 신청",
        text: `Android 비공개 사전체험 신청이 접수됐습니다.\n\n신청 이메일: ${email.trim()}\n접수 시각: ${new Date().toISOString()}`,
      }),
    });

    if (!res.ok) {
      const errText = await res.text();
      throw new Error(`메일 발송 실패: ${errText}`);
    }

    return jsonResponse({ success: true });
  } catch (error) {
    return jsonResponse({ success: false, error: (error as Error).message }, 500);
  }
});
