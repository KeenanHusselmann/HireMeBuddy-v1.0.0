// Supabase Edge Function: enqueue_and_send
// Accepts JSON POST: { recipient_id: string, message_payload: { title, body, type }, data?: Record<string,string> }
// Uses SUPABASE_SERVICE_ROLE_KEY to read device_tokens and insert queue rows if delivery fails.

import { serve } from 'https://deno.land/std@0.203.0/http/server.ts'

function loadServiceAccount() {
  const raw = Deno.env.get('SERVICE_ACCOUNT_JSON') || '';
  if (!raw) throw new Error('SERVICE_ACCOUNT_JSON not set');
  try { return JSON.parse(raw); } catch (e) {
    try {
      const decoded = atob(raw);
      return JSON.parse(decoded);
    } catch (e2) { throw new Error('SERVICE_ACCOUNT_JSON not valid JSON'); }
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
  const claimJson = JSON.stringify({ iss: sa.client_email, scope: 'https://www.googleapis.com/auth/firebase.messaging', aud: 'https://oauth2.googleapis.com/token', exp, iat });
  const header = base64urlFromBytes(new TextEncoder().encode(headerJson));
  const claim = base64urlFromBytes(new TextEncoder().encode(claimJson));
  const assertionPayload = `${header}.${claim}`;
  const signature = await signJwt(assertionPayload, sa.private_key);
  const jwt = `${assertionPayload}.${signature}`;

  const resp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${encodeURIComponent(jwt)}`
  });
  const text = await resp.text();
  if (!resp.ok) throw new Error(`token fetch failed: ${text}`);
  const j = JSON.parse(text);
  return j.access_token as string;
}

async function sendFcmDirect(accessToken: string, projectId: string, token: string, notification: any, data?: Record<string,string>) {
  // Merge notification.type into data payload for deep linking
  const fcmData = data ? { ...data } : {};
  if (notification.type) {
    fcmData.type = notification.type;
  }
  
  const message: any = {
    token,
    notification: { title: notification.title || 'Notification', body: notification.body || '' },
    android: { priority: 'HIGH', notification: { default_sound: true } },
    apns: { headers: { 'apns-priority': '10' }, payload: { aps: { alert: { title: notification.title || 'Notification', body: notification.body || '' }, 'content-available': 1 } } }
  };
  // Always include data even if empty to ensure type is present
  message.data = fcmData;
  
  const body = { message };
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const r = await fetch(url, { method: 'POST', headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  const text = await r.text();
  if (!r.ok) throw new Error(`fcm send failed: ${text}`);
  return JSON.parse(text);
}

serve(async (req) => {
  try {
    if (req.method !== 'POST') return new Response(JSON.stringify({ ok: false, error: 'POST required' }), { status: 400 });
    const body = await req.json();
    const recipientId: string = body.recipient_id;
    const message_payload = body.message_payload || { title: 'Notification', body: '' };
    const data = body.data;
    if (!recipientId) return new Response(JSON.stringify({ ok: false, error: 'recipient_id required' }), { status: 400 });

    const sa = loadServiceAccount();
    const projectId = Deno.env.get('PROJECT_ID') || sa.project_id;

    // get service role key and supabase url
    const sr = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    if (!sr || !supabaseUrl) throw new Error('SUPABASE_SERVICE_ROLE_KEY or SUPABASE_URL not set');
    const headers = { 'apikey': sr, 'Authorization': `Bearer ${sr}` } as Record<string,string>;

    // Authenticate caller: require Authorization header from client and validate with Supabase
    const callerAuth = req.headers.get('authorization') || req.headers.get('Authorization');
    if (!callerAuth) {
      return new Response(JSON.stringify({ ok: false, error: 'Missing Authorization header' }), { 
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Validate input parameters
    if (!recipientId || typeof recipientId !== 'string') {
      return new Response(JSON.stringify({ ok: false, error: 'Invalid recipient_id' }), { 
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    if (!message_payload || typeof message_payload !== 'object') {
      return new Response(JSON.stringify({ ok: false, error: 'Invalid message_payload' }), { 
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Check if caller is using service role key (skip user auth check)
    const isServiceRole = callerAuth.includes(sr);
    if (!isServiceRole) {
      // Validate as user token
      try {
        const userResp = await fetch(`${supabaseUrl.replace(/\/$/,'')}/auth/v1/user`, { headers: { Authorization: callerAuth } });
        if (!userResp.ok) {
          return new Response(JSON.stringify({ ok: false, error: 'Invalid auth token' }), { 
            status: 401,
            headers: { 'Content-Type': 'application/json' }
          });
        }
      } catch (e) {
        return new Response(JSON.stringify({ ok: false, error: 'Auth check failed' }), { 
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        });
      }
    }

    // fetch active device tokens for recipient
    const tokensUrl = `${supabaseUrl.replace(/\/$/,'')}/rest/v1/device_tokens?select=*&user_id=eq.${recipientId}&is_active=eq.true`;
    const tkResp = await fetch(tokensUrl, { headers });
    const tkText = await tkResp.text();
    if (!tkResp.ok) throw new Error(`device_tokens fetch failed: ${tkText}`);
    const tokens = JSON.parse(tkText) as Array<any>;

    if (!tokens || tokens.length === 0) {
      // insert into queue for later processing
      const insertUrl = `${supabaseUrl.replace(/\/$/,'')}/rest/v1/notification_queue`;
      const payload = { recipient_id: recipientId, message_payload, processed: false };
      const ins = await fetch(insertUrl, { method: 'POST', headers: { ...headers, 'Content-Type': 'application/json' }, body: JSON.stringify(payload) });
      const insText = await ins.text();
      if (!ins.ok) throw new Error(`enqueue failed: ${insText}`);
      return new Response(JSON.stringify({ ok: true, queued: true }), { status: 200, headers: { 'Content-Type': 'application/json' } });
    }

    // We have tokens — try immediate send
    const accessToken = await getAccessToken(sa);
    const results: any[] = [];
    for (const t of tokens) {
      try {
        const r = await sendFcmDirect(accessToken, projectId, t.token, message_payload, data);
        results.push({ token: t.token, result: r });
      } catch (err) {
        results.push({ token: t.token, error: String(err) });
      }
    }

    // insert an audit row marking processed=true
    try {
      const insertUrl = `${supabaseUrl.replace(/\/$/,'')}/rest/v1/notification_queue`;
      const payload = { recipient_id: recipientId, message_payload, processed: true };
      await fetch(insertUrl, { method: 'POST', headers: { ...headers, 'Content-Type': 'application/json' }, body: JSON.stringify(payload) });
    } catch (e) {
      // Audit insert failed - log but don't fail request
    }

    return new Response(JSON.stringify({ ok: true, sent: true, results }), { status: 200, headers: { 'Content-Type': 'application/json' } });
  } catch (e) {
    return new Response(JSON.stringify({ ok: false, error: String(e) }), { status: 500, headers: { 'Content-Type': 'application/json' } });
  }
});
