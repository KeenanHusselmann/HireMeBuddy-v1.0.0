-- Create device_tokens and notification_queue tables
-- Run this in Supabase SQL editor or psql connected to your project's DB

create table if not exists device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  device_id text,
  token text not null,
  platform text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_device_tokens_user_id on device_tokens(user_id);

-- Simple notification queue for worker/edge function
create table if not exists notification_queue (
  id bigserial primary key,
  recipient_id uuid not null,
  message_payload jsonb,
  processed boolean default false,
  created_at timestamptz default now(),
  processed_at timestamptz
);

-- Example trigger function: push a row into notification_queue when a new message is inserted
-- Adjust `messages` table/columns to match your schema before enabling

/*
create function enqueue_message_notification() returns trigger as $$
begin
  -- Only enqueue if recipient is not active (example, adapt as needed)
  insert into notification_queue (recipient_id, message_payload)
  values (NEW.recipient_id, row_to_json(NEW)::jsonb);
  return NEW;
end;
$$ language plpgsql;

create trigger trg_messages_enqueue
after insert on messages
for each row
execute function enqueue_message_notification();
*/

-- Note: the trigger above is commented out. Uncomment and adapt to your schema if you want DB-triggered queueing.
