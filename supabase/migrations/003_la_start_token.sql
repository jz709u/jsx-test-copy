alter table device_tokens
  add column if not exists la_start_token text;
