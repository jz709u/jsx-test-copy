-- Device push tokens for sending silent pushes to wake the app
-- One row per user (upsert on user_id)
create table if not exists device_tokens (
  user_id    uuid primary key references users(id),
  token      text not null,
  timezone   text not null default 'America/New_York',
  updated_at timestamptz not null default now()
);

alter table device_tokens disable row level security;
