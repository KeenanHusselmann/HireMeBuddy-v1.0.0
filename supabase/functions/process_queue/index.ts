// Supabase Edge Function: process_queue
// Polls `notification_queue` for unprocessed notifications, sends FCM to user device tokens,
// and marks notifications as processed.
// Required environment variables:
// - SERVICE_ACCOUNT_JSON (raw JSON or base64)
// - PROJECT_ID (optional; defaults to service account project_id)
// - SUPABASE_URL
// - SUPABASE_SERVICE_ROLE_KEY

import { serve } from 'https://deno.land/std@0.203.0/http/server.ts'

function loadEnvJson(name: string) {
  const raw = Deno.env.get(name) || '';
  if (!raw) throw new Error(`${name} not set`);
  try { return JSON.parse(raw); } catch { try { return JSON.parse(atob(raw)); } catch { throw new Error(`${name} not valid JSON`) } }
}

function base64url(input: string) { return input.replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/,''); }

async function signJwt(payload: string, privateKeyPem: string) {
  const pem = privateKeyPem.replace(/-----BEGIN PRIVATE KEY-----/,'').replace(/-----END PRIVATE KEY-----/,'').replace(/\s+/g,'');
  const pkcs8 = Uint8Array.from(atob(pem), c=>c.charCodeAt(0));
  const key = await crypto.subtle.importKey('pkcs8', pkcs8.buffer, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(payload));
  const sigBase64 = btoa(String.fromCharCode(...new Uint8Array(sig)));
  return base64url(sigBase64);
}

async function getAccessToken(sa: any) {
  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + 3600;
  const header = base64url(btoa(JSON.stringify({ alg: 'RS256', typ: 'JWT' })));
  const claim = base64url(btoa(JSON.stringify({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp,
    iat
  })));
  const assertionPayload = `${header}.${claim}`;
  const signature = await signJwt(assertionPayload, sa.private_key);
  const jwt = `${assertionPayload}.${signature}`;
  const resp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${encodeURIComponent(jwt)}`
  });
  if (!resp.ok) throw new Error(`token fetch failed: ${await resp.text()}`);
  const j = await resp.json();
  return j.access_token as string;
}

async function sendFcm(accessToken: string, projectId: string, token: string, notification: any, data?: Record<string,string>) {
  const body: any = { message: { token, notification } };
  if (data) body.message.data = data;
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const r = await fetch(url, { method: 'POST', headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  if (!r.ok) throw new Error(`fcm send failed: ${await r.text()}`);
  return r.json();
}

serve(async (req) => {
  try {
    const sa = loadEnvJson('SERVICE_ACCOUNT_JSON');
    const projectId = Deno.env.get('PROJECT_ID') || sa.project_id;
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || ''; if (!SUPABASE_URL) throw new Error('SUPABASE_URL not set');
    const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''; if (!SERVICE_ROLE) throw new Error('SUPABASE_SERVICE_ROLE_KEY not set');

    // Fetch unprocessed notifications
    const qUrl = `${SUPABASE_URL}/rest/v1/notification_queue?processed=eq.false&select=*`;
    const qResp = await fetch(qUrl, { headers: { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}` } });
    if (!qResp.ok) throw new Error(`failed to fetch queue: ${await qResp.text()}`);
    const queue = await qResp.json();
    if (!Array.isArray(queue) || queue.length === 0) return new Response(JSON.stringify({ ok: true, processed: 0 }), { status: 200 });

    const accessToken = await getAccessToken(sa);
    let processedCount = 0;
    for (const item of queue) {
      const recipient = item.recipient_id;
      const payload = item.message_payload || {};
      // fetch device tokens for recipient
      const tUrl = `${SUPABASE_URL}/rest/v1/device_tokens?user_id=eq.${recipient}&select=token`;
      const tResp = await fetch(tUrl, { headers: { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}` } });
      if (!tResp.ok) { console.error('failed to fetch tokens', await tResp.text()); continue; }
      const tokens = (await tResp.json()).map((r: any) => r.token).filter(Boolean);
      if (tokens.length === 0) {
        // mark as processed to avoid infinite loop
        await fetch(`${SUPABASE_URL}/rest/v1/notification_queue?id=eq.${item.id}`, { method: 'PATCH', headers: { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ processed: true, processed_at: new Date().toISOString() }) });
        processedCount++;
        continue;
      }
      const notification = payload.notification || { title: 'Notification', body: '' };
      const data = payload.data || undefined;
      for (const token of tokens) {
        try { await sendFcm(accessToken, projectId, token, notification, data); } catch (e) { console.error('fcm send error', String(e)); }
      }
      await fetch(`${SUPABASE_URL}/rest/v1/notification_queue?id=eq.${item.id}`, { method: 'PATCH', headers: { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ processed: true, processed_at: new Date().toISOString() }) });
      processedCount++;
    }
    return new Response(JSON.stringify({ ok: true, processed: processedCount }), { status: 200 });
  } catch (e) {
    return new Response(JSON.stringify({ ok: false, error: String(e) }), { status: 500 });
  }
});
