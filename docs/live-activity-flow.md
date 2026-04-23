# Live Activity Flow

---

## 1 · Token Registration

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant Native as LiveActivityManager
    participant ActivityKit
    participant Supabase

    Note over Native,ActivityKit: App launch / foreground
    ActivityKit-->>Native: pushToStartTokenUpdates (async stream)
    Native->>Supabase: upsertLAStartToken(hex)\n[device_tokens table]
```

**Key concepts**
- `la_start_token` — one per device, stored in `device_tokens`
- Allows the server to start a Live Activity without the app in the foreground (iOS 17.2+)

---

## 2 · Live Activity Start

```mermaid
flowchart TD
    A([Debug button\nor scheduled cron]) --> B[trigger-live-activity\nedge function]
    B --> C{Bookings departing\nin 10 min – 3 hrs?}
    C -- No --> D([Done — triggered: 0])
    C -- Yes --> E{live_activities row\nexists for flight?}
    E -- Yes --> F[Send APNs\nevent: update]
    E -- No --> G{la_start_token\nin device_tokens?}
    G -- No --> H([Skip — device not\non iOS 17.2+])
    G -- Yes --> I[Send APNs\nevent: start]
    I --> J[iOS starts Live Activity]
    J --> K[ActivityKit emits\npushTokenUpdates stream]
    K --> L[Native registers activity\nand uploads push_token]
    L --> M[(live_activities table\nflight_id → push_token)]
```

**Key concepts**
- Duplicate guard — if `live_activities` row already exists, send `update` instead of `start`
- On `event: start`, iOS returns a per-activity `push_token` which is saved to `live_activities`

---

## 3 · Status Change → Push Update

```mermaid
flowchart TD
    A([Admin / debug menu\nupdates flights.status]) --> B[(Postgres UPDATE)]
    B --> C[flight_status_change\ntrigger fires]
    C --> D[net.http_post\nfire-and-forget via pg_net]
    D --> E[update-live-activity\nedge function]
    E --> F[(Query live_activities\njoined with flights)]
    F --> G{Row found?}
    G -- No --> H([404 — no active\nLive Activity])
    G -- Yes --> I[Build full content-state\nstatus · departureTime · arrivalTime\ngate · boardingTime · phase · progress]
    I --> J[Sign APNs JWT]
    J --> K[POST to APNs\nevent: update]
```

**Key concepts**
- Trigger uses `begin/exception when others/null; end` so an HTTP failure never rolls back the `UPDATE`
- `update-live-activity` fetches `departure_at`/`arrival_at` from the `flights` join so the content-state is complete

---

## 4 · On-Device Rendering

```mermaid
flowchart TD
    A([APNs delivers push]) --> B{event type?}
    B -- start --> C[ActivityKit starts\nnew Live Activity]
    B -- update --> D[Decode content-state\nvia Codable]
    C --> D
    D --> E[Re-render Lock Screen widget]
    D --> F[Re-render Dynamic Island]
```

---

## 5 · End / Dismissal

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant Native as LiveActivityManager
    participant ActivityKit
    participant Supabase

    Note over Native,Supabase: User swipes away widget
    ActivityKit-->>Native: activityStateUpdates → .dismissed
    Native->>Native: cleanup(flightId)
    Native->>Supabase: DELETE live_activities WHERE flight_id=...

    Note over App,Supabase: User taps "Stop" in app
    App->>Native: channel: end(flightId)
    Native->>ActivityKit: activity.end(dismissalPolicy:.immediate)
    Native->>Supabase: DELETE live_activities WHERE flight_id=...
```

---

## Token types at a glance

| Token | Scope | Table | Purpose |
|---|---|---|---|
| `la_start_token` | Per device | `device_tokens` | Server pushes to start a new activity |
| `push_token` | Per activity | `live_activities` | Server sends updates to a running activity |
