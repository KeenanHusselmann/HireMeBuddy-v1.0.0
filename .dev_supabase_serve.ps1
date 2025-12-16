$env:SERVICE_ACCOUNT_JSON = Get-Content -Raw 'C:\Users\keena\Projects\HireMeBuddy-v1.0.0\hiremebuddy-850a8-2d033e0c5ff3.json'
$env:SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqcGFvbGtxbHVtcHl1eHhtbXZyIiwicm9zZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjkxNjc4MSwiZXhwIjoyMDY4NDkyNzgxfQ.iuZzBILhJ05jwYQgdamdhEMECWcOt3_vUSIei3Fgyj0'
$env:PROJECT_ID = 'hiremebuddy-850a8'
$env:SUPABASE_URL = 'https://vjpaolkqlumpyuxxmmvr.supabase.co'

# Start local functions server (requires Docker)
C:\tools\supabase.exe functions serve --workdir supabase/functions
