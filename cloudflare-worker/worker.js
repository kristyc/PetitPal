/**
 * PetitPal Cloudflare Worker (MVP)
 * Endpoints:
 *  - GET  /health
 *  - POST /api/keys/save
 *  - GET  /api/keys/get
 *  - POST /api/chat
 *  - POST /api/family/create_invite
 *  - POST /api/family/accept_invite
 *  - GET  /api/family/list
 *
 * Storage keys (KV):
 *  - keys:{deviceId}      -> encrypted backup blob (ciphertext/nonce/salt...)
 *  - family:{familyId}    -> { members: [{device_id, name}], owner_device_id, created_at }
 *  - invites:{token}      -> { family_id, member_name, issued_at }
 *
 * NOTE: This Worker expects encrypted key backups for persistence. For live /api/chat calls,
 * pass the needed provider key in the request body under "live_keys" (temporary in-MVP path).
 * This avoids the Worker needing to decrypt at rest. Do NOT log these keys. They are NOT stored.
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "Content-Type, X-Device-ID, X-Family-ID",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS"
    };
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      if (url.pathname === "/health" && request.method === "GET") {
        return json({ ok: true, version: "1.0.0" }, corsHeaders);
      }

      if (url.pathname === "/api/keys/save" && request.method === "POST") {
        const deviceId = request.headers.get("X-Device-ID");
        if (!deviceId) return badRequest("Missing X-Device-ID", corsHeaders);
        const body = await request.json();
        if (!body) return badRequest("Missing body", corsHeaders);

        // Prefer encrypted payload shape
        if (body.ciphertext && body.nonce && body.salt) {
          await env["petitpal-kv"].put(`keys:${deviceId}`, JSON.stringify(body));
          return json({ stored: true, key: `keys:${deviceId}` }, corsHeaders);
        }

        // Legacy/plain (discouraged) — still accepted to unblock migrations
        if (body.keys && typeof body.keys === "object") {
          const legacy = { keys: body.keys, created_at: new Date().toISOString() };
          await env["petitpal-kv"].put(`keys:${deviceId}`, JSON.stringify(legacy));
          return json({ stored: true, key: `keys:${deviceId}`, legacy: true }, corsHeaders);
        }

        return badRequest("Invalid payload", corsHeaders);
      }

      if (url.pathname === "/api/keys/get" && request.method === "GET") {
        const deviceId = request.headers.get("X-Device-ID");
        if (!deviceId) return badRequest("Missing X-Device-ID", corsHeaders);
        const val = await env["petitpal-kv"].get(`keys:${deviceId}`);
        if (!val) return notFound("No backup found", corsHeaders);
        return new Response(val, { headers: { "Content-Type": "application/json", ...corsHeaders } });
      }

      if (url.pathname === "/api/family/create_invite" && request.method === "POST") {
        const deviceId = request.headers.get("X-Device-ID");
        if (!deviceId) return badRequest("Missing X-Device-ID", corsHeaders);
        const { member_name } = await request.json();
        if (!member_name) return badRequest("member_name required", corsHeaders);

        // Create or reuse a family for this device
        const familyId = cryptoRandomId(10);
        const inviteToken = cryptoRandomId(16);

        // Persist family record
        const familyKey = `family:${familyId}`;
        const familyObj = {
          owner_device_id: deviceId,
          created_at: new Date().toISOString(),
          members: [{ device_id: deviceId, name: "Owner" }]
        };
        await env["petitpal-kv"].put(familyKey, JSON.stringify(familyObj));

        // Persist invite
        const inviteKey = `invites:${inviteToken}`;
        const inviteObj = {
          family_id: familyId,
          member_name,
          issued_at: new Date().toISOString()
        };
        await env["petitpal-kv"].put(inviteKey, JSON.stringify(inviteObj), { expirationTtl: 60 * 60 * 24 * 7 }); // 7 days

        const deeplink = `petitpal://invite/${familyId}/${encodeURIComponent(member_name)}`;
        return json({ family_id: familyId, invite_token: inviteToken, deeplink }, corsHeaders);
      }

      if (url.pathname === "/api/family/accept_invite" && request.method === "POST") {
        const deviceId = request.headers.get("X-Device-ID");
        if (!deviceId) return badRequest("Missing X-Device-ID", corsHeaders);
        const { invite_token } = await request.json();
        if (!invite_token) return badRequest("invite_token required", corsHeaders);

        const inviteKey = `invites:${invite_token}`;
        const inviteRaw = await env["petitpal-kv"].get(inviteKey);
        if (!inviteRaw) return notFound("Invite not found or expired", corsHeaders);
        const invite = JSON.parse(inviteRaw);

        const familyKey = `family:${invite.family_id}`;
        const famRaw = await env["petitpal-kv"].get(familyKey);
        let family = famRaw ? JSON.parse(famRaw) : { created_at: new Date().toISOString(), members: [] };
        // Avoid duplicates
        if (!family.members.find(m => m.device_id === deviceId)) {
          family.members.push({ device_id: deviceId, name: invite.member_name || "Member" });
        }
        await env["petitpal-kv"].put(familyKey, JSON.stringify(family));
        // Optionally consume invite (delete)
        await env["petitpal-kv"].delete(inviteKey);

        return json({ family_id: invite.family_id, member_name: invite.member_name }, corsHeaders);
      }

      if (url.pathname === "/api/family/list" && request.method === "GET") {
        const familyId = request.headers.get("X-Family-ID");
        if (!familyId) return badRequest("Missing X-Family-ID", corsHeaders);
        const famRaw = await env["petitpal-kv"].get(`family:${familyId}`);
        if (!famRaw) return notFound("Family not found", corsHeaders);
        return new Response(famRaw, { headers: { "Content-Type": "application/json", ...corsHeaders } });
      }

      if (url.pathname === "/api/chat" && request.method === "POST") {
        const deviceId = request.headers.get("X-Device-ID");
        if (!deviceId) return badRequest("Missing X-Device-ID", corsHeaders);
        const { text, provider_hint = null, live_keys = {} } = await request.json();
        if (!text || typeof text !== "string") return badRequest("text required", corsHeaders);

        const { model, reason } = pickModel(text, provider_hint);
        const start = Date.now();
        const { ok, responseText, error } = await callProvider(model, text, live_keys);
        const duration_ms = Date.now() - start;

        if (!ok) {
          return new Response(JSON.stringify({ error: error || "Provider error" }), {
            status: 500,
            headers: { "Content-Type": "application/json", ...corsHeaders }
          });
        }

        // naive summary: first 2 sentences or first 180 chars
        const summary_tts = summarizeForTTS(responseText);
        const body = {
          model_used: model,
          auto_switched: provider_hint ? provider_hint !== model : true,
          reason,
          summary_tts,
          text: responseText,
          duration_ms,
          telemetry_id: cryptoRandomId(8)
        };
        return json(body, corsHeaders);
      }

      return new Response("Not Found", { status: 404, headers: corsHeaders });
    } catch (e) {
      return new Response(JSON.stringify({ error: e.message || "Unhandled error" }), {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders }
      });
    }
  }
};

function json(obj, headers={}) { return new Response(JSON.stringify(obj), { headers: { "Content-Type": "application/json", ...headers }}); }
function badRequest(msg, headers) { return new Response(JSON.stringify({ error: msg }), { status: 400, headers: { "Content-Type": "application/json", ...headers }}); }
function notFound(msg, headers) { return new Response(JSON.stringify({ error: msg }), { status: 404, headers: { "Content-Type": "application/json", ...headers }}); }

function cryptoRandomId(len=8) {
  const alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let s = "";
  const arr = new Uint8Array(len);
  crypto.getRandomValues(arr);
  for (let i=0;i<len;i++){ s += alphabet[arr[i] % alphabet.length]; }
  return s;
}

function pickModel(text, provider_hint) {
  if (provider_hint) return { model: provider_hint, reason: "hint" };
  const t = text.toLowerCase();
  const isNews = /(news|happening|current|today|latest|recent)/.test(t);
  const isHowTo = /(how to|how do|step by step|instructions|guide)/.test(t);
  const isQuick = /(what is|define|quick|brief)/.test(t);
  const isChat = /(i'm feeling|think|believe|opinion|chat)/.test(t);

  if (isNews)   return { model: "grok", reason: "news" };
  if (isHowTo)  return { model: "deepseek", reason: "how_to" };
  if (isQuick)  return { model: "gemini", reason: "quick" };
  if (isChat)   return { model: "openai", reason: "conversation" };
  return { model: "openai", reason: "default" };
}

async function callProvider(model, text, live_keys) {
  try {
    if (model === "openai") {
      const key = live_keys.openai;
      if (!key) return { ok: false, error: "Missing OpenAI key in live_keys.openai" };
      const r = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": `Bearer ${key}` },
        body: JSON.stringify({ model: "gpt-4o-mini", messages: [{ role:"user", content: text }] })
      });
      if (!r.ok) return { ok: false, error: `OpenAI ${r.status}` };
      const j = await r.json();
      const responseText = j.choices?.[0]?.message?.content || "";
      return { ok: true, responseText };
    }
    if (model === "gemini") {
      const key = live_keys.gemini;
      if (!key) return { ok: false, error: "Missing Gemini key in live_keys.gemini" };
      const r = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${key}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ contents: [{ parts: [{ text }]}]})
      });
      if (!r.ok) return { ok: false, error: `Gemini ${r.status}` };
      const j = await r.json();
      const responseText = j.candidates?.[0]?.content?.parts?.map(p=>p.text).join("\n") || "";
      return { ok: true, responseText };
    }
    if (model === "grok") {
      const key = live_keys.grok;
      if (!key) return { ok: false, error: "Missing Grok key in live_keys.grok" };
      const r = await fetch("https://api.x.ai/v1/chat/completions", {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": `Bearer ${key}` },
        body: JSON.stringify({ model: "grok-2-mini", messages: [{ role:"user", content: text }] })
      });
      if (!r.ok) return { ok: false, error: `Grok ${r.status}` };
      const j = await r.json();
      const responseText = j.choices?.[0]?.message?.content || "";
      return { ok: true, responseText };
    }
    if (model === "deepseek") {
      const key = live_keys.deepseek;
      if (!key) return { ok: false, error: "Missing DeepSeek key in live_keys.deepseek" };
      const r = await fetch("https://api.deepseek.com/chat/completions", {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": `Bearer ${key}` },
        body: JSON.stringify({ model: "deepseek-chat", messages: [{ role:"user", content: text }] })
      });
      if (!r.ok) return { ok: false, error: `DeepSeek ${r.status}` };
      const j = await r.json();
      const responseText = j.choices?.[0]?.message?.content || "";
      return { ok: true, responseText };
    }
    return { ok: false, error: "Unknown model" };
  } catch (e) {
    return { ok: false, error: e.message || "network" };
  }
}

function summarizeForTTS(s) {
  try {
    const end = s.indexOf(".", 0);
    if (end > 180 || end === -1) return (s.length > 180 ? s.slice(0, 180) + "…" : s);
    const end2 = s.indexOf(".", end+1);
    const cut = end2 !== -1 ? end2+1 : end+1;
    return s.slice(0, cut);
  } catch { return s.slice(0, 180); }
}
