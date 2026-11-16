// 관리자 푸시 알림 작성용 번역 함수.
// GOOGLE_TRANSLATE_API_KEY가 설정되어 있으면 공식 Cloud Translation API를,
// 없으면 Google 번역 웹 엔드포인트를 사용한다.
const GOOGLE_TRANSLATE_API_KEY = Deno.env.get("GOOGLE_TRANSLATE_API_KEY");

const ALLOWED_TARGETS = new Set([
  "en", "zh", "zh_TW", "ja", "es", "fr", "de", "pt", "it",
]);

const TARGET_CODE_MAP: Record<string, string> = {
  zh: "zh-CN",
  zh_TW: "zh-TW",
};

const MAX_TEXTS_CHARS = 5000;
const MAX_TARGETS = 10;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type TranslationResult = Record<string, { title: string; body: string }>;

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json; charset=utf-8" },
  });
}

function decodeHtmlEntities(value: string): string {
  return value
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");
}

async function translateWithCloud(texts: string[], target: string): Promise<string[]> {
  if (!GOOGLE_TRANSLATE_API_KEY) throw new Error("GOOGLE_TRANSLATE_API_KEY is missing");

  const response = await fetch(
    `https://translation.googleapis.com/language/translate/v2?key=${encodeURIComponent(GOOGLE_TRANSLATE_API_KEY)}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        q: texts,
        source: "ko",
        target,
        format: "text",
      }),
      signal: AbortSignal.timeout(15000),
    },
  );

  const data = await response.json();
  if (!response.ok) {
    throw new Error(data?.error?.message || `Cloud Translation HTTP ${response.status}`);
  }

  const translations = data?.data?.translations;
  if (!Array.isArray(translations) || translations.length !== texts.length) {
    throw new Error("Cloud Translation 응답 형식이 올바르지 않습니다.");
  }

  return translations.map((item: { translatedText?: string }) =>
    decodeHtmlEntities(String(item?.translatedText ?? ""))
  );
}

async function translateWithWeb(text: string, target: string): Promise<string> {
  const url = new URL("https://translate.googleapis.com/translate_a/single");
  url.searchParams.set("client", "gtx");
  url.searchParams.set("sl", "ko");
  url.searchParams.set("tl", target);
  url.searchParams.set("dt", "t");
  url.searchParams.set("q", text);

  const response = await fetch(url, {
    headers: { "User-Agent": "Mozilla/5.0" },
    signal: AbortSignal.timeout(15000),
  });

  if (!response.ok) {
    throw new Error(`Google 번역 HTTP ${response.status}`);
  }

  const data = await response.json();
  const translated = (data?.[0] ?? [])
    .map((segment: unknown) => Array.isArray(segment) ? String(segment[0] ?? "") : "")
    .join("");

  if (!translated) throw new Error("Google 번역 응답이 비어 있습니다.");
  return translated;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "POST 요청만 지원합니다." }, 405);
  }

  try {
    const payload = await req.json();
    const rawTargets = Array.isArray(payload?.targets) ? payload.targets : [];
    const targets = [...new Set(rawTargets.map((value: unknown) => String(value)))]
      .filter((value) => ALLOWED_TARGETS.has(value))
      .slice(0, MAX_TARGETS);

    const title = String(payload?.texts?.title ?? "").trim();
    const body = String(payload?.texts?.body ?? "").trim();

    if (targets.length === 0) {
      throw new Error("번역할 대상 언어(targets)가 필요합니다.");
    }
    if (!title && !body) {
      throw new Error("번역할 한국어 제목 또는 본문이 필요합니다.");
    }
    if (title.length + body.length > MAX_TEXTS_CHARS) {
      throw new Error(`한 번에 ${MAX_TEXTS_CHARS.toLocaleString()}자까지만 번역할 수 있습니다.`);
    }

    const provider = GOOGLE_TRANSLATE_API_KEY ? "google-cloud" : "google-web";
    const translations: TranslationResult = {};

    for (const target of targets) {
      const apiTarget = TARGET_CODE_MAP[target] ?? target;

      if (provider === "google-cloud") {
        const texts = [title, body].filter(Boolean);
        const translated = await translateWithCloud(texts, apiTarget);
        let index = 0;
        translations[target] = {
          title: title ? translated[index++] : "",
          body: body ? translated[index++] : "",
        };
      } else {
        translations[target] = {
          title: title ? await translateWithWeb(title, apiTarget) : "",
          body: body ? await translateWithWeb(body, apiTarget) : "",
        };
      }
    }

    return jsonResponse({ provider, translations });
  } catch (error) {
    console.error("translate function error:", error);
    return jsonResponse(
      { error: error instanceof Error ? error.message : "번역 중 오류가 발생했습니다." },
      500,
    );
  }
});
