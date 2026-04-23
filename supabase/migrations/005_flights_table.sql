-- ─────────────────────────────────────────────────────────────
-- Replace flight_schedules with a concrete flights table.
-- Each schedule becomes daily rows spanning 60 days back to
-- 90 days forward. Re-run the INSERT block periodically to
-- extend the window as time advances.
-- ─────────────────────────────────────────────────────────────

-- 1. Concrete flights table
create table if not exists flights (
  id           text primary key,              -- 'JSX-1021-20260422'
  route_id     text not null,                 -- 'JSX-1021'
  origin_code  text not null references airports(code),
  dest_code    text not null references airports(code),
  departure_at timestamptz not null,
  arrival_at   timestamptz not null,
  aircraft     text not null default 'Embraer E135',
  total_seats  int  not null default 30,
  avail_seats  int  not null,
  price        numeric(10,2) not null,
  status       text not null default 'on_time'
);

alter table flights disable row level security;

-- 2. Populate from flight_schedules × generate_series
insert into flights (
  id, route_id, origin_code, dest_code,
  departure_at, arrival_at,
  aircraft, total_seats, avail_seats, price, status
)
select
  fs.id || '-' || to_char(d::date, 'YYYYMMDD'),
  fs.id,
  fs.origin_code,
  fs.dest_code,
  (d::date + make_time(fs.dep_hour, fs.dep_minute, 0.0))::timestamptz,
  (d::date + make_time(fs.dep_hour, fs.dep_minute, 0.0)
          + make_interval(mins := fs.dur_minutes))::timestamptz,
  fs.aircraft,
  fs.total_seats,
  fs.avail_seats,
  fs.price,
  fs.status
from flight_schedules fs
cross join generate_series(
  current_date - interval '60 days',
  current_date + interval '90 days',
  interval '1 day'
) as d
on conflict (id) do nothing;

-- 3. Migrate bookings.flight_id → flights.id
--    Match each booking to the flights row whose departure_at is
--    closest to the booking's stored departure_time.
alter table bookings add column if not exists new_flight_id text;

update bookings b
set new_flight_id = (
  select f.id
  from flights f
  where f.route_id = b.flight_id
  order by abs(extract(epoch from (f.departure_at - b.departure_time)))
  limit 1
);

-- For bookings outside the generate_series window, synthesise a flights row.
insert into flights (
  id, route_id, origin_code, dest_code,
  departure_at, arrival_at,
  aircraft, total_seats, avail_seats, price, status
)
select
  b.flight_id || '-' || to_char(b.departure_time at time zone 'UTC', 'YYYYMMDD'),
  b.flight_id,
  fs.origin_code,
  fs.dest_code,
  b.departure_time,
  b.arrival_time,
  fs.aircraft,
  fs.total_seats,
  fs.avail_seats,
  fs.price,
  fs.status
from bookings b
join flight_schedules fs on fs.id = b.flight_id
where b.new_flight_id is null
on conflict (id) do nothing;

-- Second pass for any that were just synthesised.
update bookings b
set new_flight_id =
  b.flight_id || '-' || to_char(b.departure_time at time zone 'UTC', 'YYYYMMDD')
where new_flight_id is null;

alter table bookings drop constraint if exists bookings_flight_id_fkey;
alter table bookings drop column flight_id;
alter table bookings rename column new_flight_id to flight_id;
alter table bookings alter column flight_id set not null;
alter table bookings
  add constraint bookings_flight_id_fkey
  foreign key (flight_id) references flights(id);

-- 4. Migrate live_activities.flight_id → flights.id
--    Pin each live activity to the next upcoming departure on that route.
alter table live_activities add column if not exists new_flight_id text;

update live_activities la
set new_flight_id = (
  select f.id
  from flights f
  where f.route_id = la.flight_id
  order by abs(extract(epoch from (f.departure_at - now())))
  limit 1
);

alter table live_activities drop constraint if exists live_activities_flight_id_fkey;
alter table live_activities drop column flight_id;
alter table live_activities rename column new_flight_id to flight_id;
alter table live_activities
  add constraint live_activities_flight_id_fkey
  foreign key (flight_id) references flights(id);

-- 5. Update decrement_seats RPC
create or replace function decrement_seats(flight_id text, count int)
returns void language sql as $$
  update flights set avail_seats = avail_seats - count where id = flight_id;
$$;

-- 6. Add reset helper (used by debug menu)
create or replace function reset_flight_seats()
returns void language sql as $$
  update flights set avail_seats = total_seats;
$$;

-- 7. Drop old table
drop table if exists flight_schedules cascade;
