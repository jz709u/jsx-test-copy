-- ─────────────────────────────────────────────────────────────
-- JSX App – Supabase schema + seed
-- Run this in the Supabase SQL editor
-- ─────────────────────────────────────────────────────────────

-- Airports
create table if not exists airports (
  code text primary key,
  city text not null,
  name text not null
);

-- Flight schedules (date-independent; date applied client-side)
create table if not exists flight_schedules (
  id           text primary key,
  origin_code  text not null references airports(code),
  dest_code    text not null references airports(code),
  dep_hour     int  not null,
  dep_minute   int  not null,
  dur_minutes  int  not null,
  aircraft     text not null default 'Embraer E135',
  total_seats  int  not null default 30,
  avail_seats  int  not null,
  price        numeric(10,2) not null,
  status       text not null default 'on_time'
);

-- Users
create table if not exists users (
  id                    uuid primary key default gen_random_uuid(),
  first_name            text not null,
  last_name             text not null,
  email                 text unique not null,
  phone                 text not null default '',
  loyalty_points        int  not null default 0,
  credit_balance        numeric(10,2) not null default 0,
  member_since          text not null,
  known_traveler_number text,
  preferred_seat        text not null default 'Window'
);

-- Bookings (actual timestamps stored here)
create table if not exists bookings (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid references users(id),
  confirmation_code text unique not null,
  flight_id         text not null references flight_schedules(id),
  departure_time    timestamptz not null,
  arrival_time      timestamptz not null,
  total_paid        numeric(10,2) not null,
  booked_at         timestamptz not null default now(),
  status            text not null default 'confirmed',
  seat_number       int
);

-- Passengers
create table if not exists passengers (
  id         uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id) on delete cascade,
  first_name text not null,
  last_name  text not null
);

-- Live Activity push tokens (one row per active Live Activity)
create table if not exists live_activities (
  id          uuid primary key default gen_random_uuid(),
  flight_id   text not null references flight_schedules(id),
  push_token  text not null,
  created_at  timestamptz not null default now()
);

-- RPC: decrement available seats when a booking is created
create or replace function decrement_seats(flight_id text, count int)
returns void language sql as $$
  update flight_schedules set avail_seats = avail_seats - count where id = flight_id;
$$;

-- Disable RLS for development (re-enable + add policies before production)
alter table airports         disable row level security;
alter table flight_schedules disable row level security;
alter table users            disable row level security;
alter table bookings         disable row level security;
alter table passengers       disable row level security;
alter table live_activities  disable row level security;

-- ─── Seed ───────────────────────────────────────────────────

insert into airports values
  ('DAL', 'Dallas',     'Dallas Love Field'),
  ('BUR', 'Los Angeles','Burbank Bob Hope'),
  ('LAS', 'Las Vegas',  'Harry Reid Intl'),
  ('OAK', 'Oakland',    'Oakland Metro Intl'),
  ('PHX', 'Phoenix',    'Phoenix Deer Valley'),
  ('SJC', 'San Jose',   'Norman Y. Mineta'),
  ('BNA', 'Nashville',  'Nashville Intl'),
  ('AUS', 'Austin',     'Austin-Bergstrom Intl')
on conflict do nothing;

insert into flight_schedules
  (id, origin_code, dest_code, dep_hour, dep_minute, dur_minutes, avail_seats, price, status)
values
  ('JSX-1021','DAL','BUR', 7,30,135,12,299,'on_time'),
  ('JSX-1022','DAL','BUR',11, 0,135, 4,329,'on_time'),
  ('JSX-1023','DAL','BUR',15,45,135,18,279,'on_time'),
  ('JSX-2010','BUR','DAL', 8, 0,135, 9,299,'on_time'),
  ('JSX-3050','DAL','LAS', 9,15,105,22,199,'on_time'),
  ('JSX-4010','DAL','OAK', 6,45,165, 3,349,'boarding'),
  ('JSX-5020','BUR','LAS',14,30, 75,16,179,'on_time'),
  ('JSX-6030','AUS','DAL',10,20, 55, 8,149,'delayed')
on conflict do nothing;

insert into users (id, first_name, last_name, email, phone, loyalty_points, credit_balance, member_since, preferred_seat)
values (
  'a0000000-0000-0000-0000-000000000001',
  'Alex','Rivera','alex.rivera@jsx.com','+1 214 555 0100',
  12450, 250.00, 'Jan 2022', 'Window'
) on conflict do nothing;

-- Upcoming bookings (relative to NOW())
insert into bookings (user_id, confirmation_code, flight_id, departure_time, arrival_time, total_paid, status, seat_number)
values
  ('a0000000-0000-0000-0000-000000000001','JSX4K8P','JSX-1021',
   now() + interval '3 days 2 hours',
   now() + interval '3 days 4 hours 15 minutes',
   299,'confirmed',7),
  ('a0000000-0000-0000-0000-000000000001','JSX9M2R','JSX-3050',
   now() + interval '14 days 3 hours 15 minutes',
   now() + interval '14 days 5 hours',
   199,'confirmed', null)
on conflict do nothing;

-- Past bookings
insert into bookings (user_id, confirmation_code, flight_id, departure_time, arrival_time, total_paid, booked_at, status, seat_number)
values
  ('a0000000-0000-0000-0000-000000000001','JSXLT7Q','JSX-2010',
   now() - interval '7 days 2 hours',
   now() - interval '6 days 23 hours 45 minutes',
   299, now() - interval '20 days','completed',12),
  ('a0000000-0000-0000-0000-000000000001','JSX8WXN','JSX-4010',
   now() - interval '30 days 1 hour',
   now() - interval '29 days 22 hours 15 minutes',
   349, now() - interval '45 days','completed', 4)
on conflict do nothing;

-- Passengers
insert into passengers (booking_id, first_name, last_name)
select b.id,'Alex','Rivera' from bookings b where b.confirmation_code in ('JSX4K8P','JSXLT7Q','JSX8WXN')
on conflict do nothing;

insert into passengers (booking_id, first_name, last_name)
select b.id, p.first_name, p.last_name
from bookings b
cross join (values ('Alex','Rivera'),('Jordan','Rivera')) as p(first_name, last_name)
where b.confirmation_code = 'JSX9M2R'
on conflict do nothing;
