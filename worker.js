export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Device-ID",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    };
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }
    if (url.pathname === "/health") {
      return new Response(JSON.stringify({ ok: true, version: "0.2.0" }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }

    if (url.pathname === "/api/voice_chat" && request.method === "POST") {
      const auth = request.headers.get("Authorization");
      if (!auth || !auth.startsWith("Bearer ")) {
        return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
          status: 401, headers: { "Content-Type": "application/json", ...corsHeaders },
        });
      }
      const mime = request.headers.get("Content-Type") || "audio/m4a";
      const audioBytes = await request.arrayBuffer();
      const audioBlob = new Blob([audioBytes], { type: mime });
      const form = new FormData();
      form.append("file", audioBlob, "audio.m4a");
      form.append("model", "whisper-1");

      const tr = await fetch("https://api.openai.com/v1/audio/transcriptions", {
        method: "POST",
        headers: { "Authorization": auth },
        body: form,
      });
      if (!tr.ok) {
        const err = await tr.text();
        return new Response(JSON.stringify({ error: "Transcription failed", status: tr.status, details: err }), {
          status: 502, headers: { "Content-Type": "application/json", ...corsHeaders },
        });
      }
      const trJson = await tr.json();
      const transcript = trJson?.text || "";

      const model = "gpt-4o-mini";
      const chat = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": auth,
        },
        body: JSON.stringify({
          model,
          messages: [
            { role: "system", content: "You are a concise nutrition assistant. Keep answers short and clear." },
            { role: "user", content: transcript },
          ],
          temperature: 0.2,
        }),
      });
      if (!chat.ok) {
        const err = await chat.text();
        return new Response(JSON.stringify({ error: "Chat failed", status: chat.status, details: err }), {
          status: 502, headers: { "Content-Type": "application/json", ...corsHeaders },
        });
      }
      const data = await chat.json();
      const answer = data?.choices?.[0]?.message?.content ?? "";

      return new Response(JSON.stringify({ transcript, text: answer }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }

    if (url.pathname === "/api/chat" && request.method === "POST") {
      const auth = request.headers.get("Authorization");
      if (!auth || !auth.startsWith("Bearer ")) {
        return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
          status: 401, headers: { "Content-Type": "application/json", ...corsHeaders },
        });
      }
      let body;
      try { body = await request.json(); } catch {
        return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
          status: 400, headers: { "Content-Type": "application/json", ...corsHeaders },
        });
      }
      const text = body?.text || "";
      const model = body?.model || "gpt-4o-mini";
      if (!text || typeof text !== "string") {
        return new Response(JSON.stringify({ error: "Missing text" }), {
          status: 400, headers: { "Content-Type": "application/json", ...corsHeaders },
        });
      }
      const response = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": auth,
        },
        body: JSON.stringify({
          model,
          messages: [
            { role: "system", content: "You are a concise nutrition assistant. Keep answers short and clear." },
            { role: "user", content: text },
          ],
          temperature: 0.2,
        }),
      });
      if (!response.ok) {
        const err = await response.text();
        return new Response(JSON.stringify({ error: "Upstream error", status: response.status, details: err }), {
          status: 502, headers: { "Content-Type": "application/json", ...corsHeaders },
        });
      }
      const data = await response.json();
      const answer = data?.choices?.[0]?.message?.content ?? "";
      return new Response(JSON.stringify({ model_used: model, text: answer }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }

    return new Response("Not found", { status: 404, headers: corsHeaders });
  },
};
