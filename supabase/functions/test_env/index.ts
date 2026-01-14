import { serve } from 'https://deno.land/std@0.203.0/http/server.ts'

serve(async (req) => {
  try {
    const envVars = {
      SERVICE_ACCOUNT_JSON: Deno.env.get('SERVICE_ACCOUNT_JSON') ? 'SET (length: ' + Deno.env.get('SERVICE_ACCOUNT_JSON')!.length + ')' : 'NOT SET',
      PROJECT_ID: Deno.env.get('PROJECT_ID') || 'NOT SET',
      SUPABASE_URL: Deno.env.get('SUPABASE_URL') || 'NOT SET',
      SUPABASE_SERVICE_ROLE_KEY: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ? 'SET' : 'NOT SET',
    };
    
    return new Response(JSON.stringify({ ok: true, env: envVars }, null, 2), { 
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (e) {
    return new Response(JSON.stringify({ ok: false, error: String(e) }), { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
});
