-- Redefine the trigger function with exception handling so a pg_net
-- failure never rolls back the flight status UPDATE.

create or replace function on_flight_status_change()
returns trigger language plpgsql security definer as $$
declare
  display_status text;
begin
  if NEW.status = OLD.status then
    return NEW;
  end if;

  display_status := case NEW.status
    when 'delayed'   then 'Delayed'
    when 'boarding'  then 'Boarding'
    when 'departed'  then 'Departed'
    when 'landed'    then 'Landed'
    when 'cancelled' then 'Cancelled'
    else 'On Time'
  end;

  begin
    perform net.http_post(
      url     := 'https://cuqnanupwutqdbhntykp.supabase.co/functions/v1/update-live-activity',
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN1cW5hbnVwd3V0cWRiaG50eWtwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3MTE4ODUsImV4cCI6MjA5MjI4Nzg4NX0.JVNGZVzxB2wj_yvZygQ8nKaKE9ft_Is1i0sy815i_Dk'
      ),
      body    := jsonb_build_object(
        'flight_id', NEW.id,
        'status',    display_status
      )
    );
  exception when others then
    -- Push failed — let the status update commit anyway.
    null;
  end;

  return NEW;
end;
$$;
