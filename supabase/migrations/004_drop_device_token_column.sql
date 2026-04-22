-- APNs device token no longer needed — push-to-start uses la_start_token directly
alter table device_tokens drop column if exists token;
alter table device_tokens alter column la_start_token set not null;
