const assets: Record<string, { urls: string[]; type: string }> = {
  supabase: { urls: [
    "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.js",
    "https://unpkg.com/@supabase/supabase-js@2/dist/umd/supabase.js"
  ], type: "text/javascript; charset=utf-8" },
  charts: { urls: [
    "https://cdn.jsdelivr.net/npm/lightweight-charts@4.2.0/dist/lightweight-charts.standalone.production.js",
    "https://unpkg.com/lightweight-charts@4.2.0/dist/lightweight-charts.standalone.production.js"
  ], type: "text/javascript; charset=utf-8" },
  lucide: { urls: [
    "https://cdn.jsdelivr.net/npm/lucide@0.468.0/dist/umd/lucide.min.js",
    "https://unpkg.com/lucide@0.468.0/dist/umd/lucide.min.js"
  ], type: "text/javascript; charset=utf-8" },
};

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Cache-Control": "public, max-age=86400"
};

async function fetchFirstAvailable(urls: string[], timeoutMs = 8000): Promise<Response | null> {
  for (const target of urls) {
    try {
      const response = await fetch(target, {
        headers: { accept: "*/*" },
        signal: AbortSignal.timeout(timeoutMs)
      });
      if (!response.ok) continue;
      const contentType = response.headers.get("content-type") || "";
      if (!contentType.toLowerCase().startsWith("image/")) continue;
      return response;
    } catch (_) {
      // Try the next independent public logo source.
    }
  }
  return null;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "GET") return new Response("Method not allowed", { status: 405, headers: cors });

  const url = new URL(req.url);
  const key = url.searchParams.get("asset") || "";

  if (key === "logo") {
    const symbol = String(url.searchParams.get("symbol") || "").toLowerCase();
    if (!/^[a-z0-9]{2,20}$/.test(symbol)) {
      return new Response("Invalid symbol", { status: 400, headers: cors });
    }

    const encoded = encodeURIComponent(symbol);
    const response = await fetchFirstAvailable([
      "https://cdn.jsdelivr.net/gh/spothq/cryptocurrency-icons@master/128/color/" + encoded + ".png",
      "https://assets.coincap.io/assets/icons/" + encoded + "@2x.png"
    ]);
    if (!response) return new Response("", { status: 404, headers: cors });

    return new Response(response.body, {
      headers: {
        ...cors,
        "Content-Type": response.headers.get("content-type") || "image/png",
        "Cache-Control": "public, max-age=604800",
        "X-DigiArz-Logo-Source": new URL(response.url).hostname
      }
    });
  }

  const item = assets[key];
  if (!item) return new Response("Not found", { status: 404, headers: cors });

  let lastStatus = 502;
  for (const target of item.urls) {
    try {
      const response = await fetch(target, {
        headers: { accept: "*/*" },
        signal: AbortSignal.timeout(12000)
      });
      if (!response.ok) {
        lastStatus = response.status;
        continue;
      }
      return new Response(response.body, {
        headers: {
          ...cors,
          "Content-Type": item.type,
          "X-DigiArz-Asset-Source": new URL(target).hostname
        }
      });
    } catch (_) {}
  }

  return new Response("Asset provider unavailable", { status: lastStatus, headers: cors });
});
