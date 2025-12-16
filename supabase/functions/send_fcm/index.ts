// Supabase Edge Function: send_fcm
// Expects environment variable SERVICE_ACCOUNT_JSON (base64 or raw JSON) and PROJECT_ID
// POST body: { tokens: string[], notification: { title, body }, data?: Record<string,string> }

import { serve } from 'https://deno.land/std@0.203.0/http/server.ts'

const __DEBUG: string[] = [];

function loadServiceAccount() {
  const raw = Deno.env.get('SERVICE_ACCOUNT_JSON') || '';
  __DEBUG.push(`SERVICE_ACCOUNT_JSON present: ${!!raw}`);
  if (!raw) throw new Error('SERVICE_ACCOUNT_JSON not set');
  try {
    return JSON.parse(raw);
  } catch (e) {
    // maybe it's base64
    try {
      const decoded = atob(raw);
      return JSON.parse(decoded);
    } catch (e2) {
      throw new Error('SERVICE_ACCOUNT_JSON not valid JSON');
    }
  }
}

function base64urlFromBytes(bytes: Uint8Array) {
  let binary = '';
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  const b64 = btoa(binary);
  return b64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function base64urlFromString(b64: string) {
  return b64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function signJwt(payload: string, privateKeyPem: string) {
  // Convert PEM to PKCS8 binary
  const pem = privateKeyPem.replace(/-----BEGIN PRIVATE KEY-----/,'').replace(/-----END PRIVATE KEY-----/,'').replace(/\s+/g,'');
  const pkcs8 = Uint8Array.from(atob(pem), c=>c.charCodeAt(0));
  const key = await crypto.subtle.importKey('pkcs8', pkcs8.buffer, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(payload));
  const sigBase64 = btoa(String.fromCharCode(...new Uint8Array(sig)));
  return base64urlFromString(sigBase64);
}

async function getAccessToken(sa: any) {
  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + 3600;
  const headerJson = JSON.stringify({ alg: 'RS256', typ: 'JWT' });
  const claimJson = JSON.stringify({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp,
    iat
  });
  const header = base64urlFromBytes(new TextEncoder().encode(headerJson));
  const claim = base64urlFromBytes(new TextEncoder().encode(claimJson));
  const assertionPayload = `${header}.${claim}`;
  const signature = await signJwt(assertionPayload, sa.private_key);
  const jwt = `${assertionPayload}.${signature}`;

  const resp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${encodeURIComponent(jwt)}`
  });
  const text = await resp.text();
  __DEBUG.push(`token endpoint status=${resp.status} body=${text}`);
  if (!resp.ok) {
    throw new Error(`token fetch failed: ${text}`);
  }
  const j = JSON.parse(text);
  return j.access_token as string;
}

async function sendFcm(accessToken: string, projectId: string, token: string, notification: any, data?: Record<string,string>) {
  // Build message ensuring cross-platform system notification display when app is backgrounded.
  const message: any = {
    token,
    notification: {
      title: notification.title || 'Notification',
      body: notification.body || ''
    },
    android: {
      priority: 'HIGH',
      notification: {
        default_sound: true,
        default_vibrate_timings: true
      }
    },
    apns: {
      headers: {
        // immediate delivery
        'apns-priority': '10'
      },
      payload: {
        aps: {
          alert: {
            title: notification.title || 'Notification',
            body: notification.body || ''
          },
          'content-available': 1
        }
      }
    }
  };

  if (data) message.data = data;

  const body: any = { message };
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const r = await fetch(url, { method: 'POST', headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  if (!r.ok) throw new Error(`fcm send failed: ${await r.text()}`);
  return r.json();
}

serve(async (req) => {
  try {
    __DEBUG.push(`send_fcm invocation start: ${req.method} ${req.url}`);
    const sa = loadServiceAccount();
    __DEBUG.push(`loaded service account: client_email=${sa.client_email||null} project_id=${sa.project_id||null} private_key_len=${sa.private_key?sa.private_key.length:0}`);
    const projectId = Deno.env.get('PROJECT_ID') || sa.project_id;
    const body = await req.json();
    const tokens: string[] = body.tokens || [];
    const notification = body.notification || { title: 'Notification', body: '' };
    const data = body.data;

    const token = await getAccessToken(sa);
    __DEBUG.push(`access token length: ${token ? token.length : 0}`);
    const results = [];
    for (const t of tokens) {
      const r = await sendFcm(token, projectId, t, notification, data);
      results.push(r);
    }
    return new Response(JSON.stringify({ ok: true, results, debug: __DEBUG }), { status: 200 });
  } catch (e) {
    __DEBUG.push(`error: ${e.stack || String(e)}`);
    return new Response(JSON.stringify({ ok: false, error: String(e), debug: __DEBUG }), { status: 500 });
  }
});
