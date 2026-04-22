# Live Activity Flow

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant Native as LiveActivityManager (actor)
    participant ActivityKit
    participant Supabase
    participant EdgeFn as Edge Function (cron)
    participant APNs

    %% ── Token registration ──────────────────────────────────────
    Note over Native,APNs: App launch / foreground
    ActivityKit-->>Native: pushToStartTokenUpdates (async stream)
    Native->>Supabase: upsertLAStartToken(hex)\n[device_tokens table]

    %% ── Push-to-start (server-initiated) ────────────────────────
    Note over EdgeFn,ActivityKit: Cron fires ~90 min before departure
    EdgeFn->>Supabase: SELECT device_tokens WHERE user_id=...
    EdgeFn->>APNs: POST /3/device/{la_start_token}\nevent=start, attributes-type=JSXFlightAttributes
    APNs->>ActivityKit: deliver start push
    ActivityKit->>Native: activityUpdates stream → adoptIfNeeded()
    Native->>Native: register(activity, flightId)\n→ observeTokens + monitorDismissal
    ActivityKit-->>Native: pushTokenUpdates (per-activity stream)
    Native->>Supabase: uploadUpdateToken(flightId, pushToken)\n[live_activities table]

    %% ── App-initiated start ──────────────────────────────────────
    Note over App,ActivityKit: User taps "Track Flight" in app
    App->>Native: channel: start(args)
    Native->>ActivityKit: Activity.request(attributes, content, pushType:.token)
    ActivityKit-->>Native: pushTokenUpdates stream
    Native->>Supabase: uploadUpdateToken(flightId, pushToken)

    %% ── Remote update ────────────────────────────────────────────
    Note over EdgeFn,ActivityKit: Cron fires, activity already exists
    EdgeFn->>Supabase: SELECT live_activities WHERE flight_id=...
    EdgeFn->>APNs: POST /3/device/{push_token}\nevent=update, content-state={...}
    APNs->>ActivityKit: deliver update push
    ActivityKit->>ActivityKit: widget re-renders

    %% ── App update ───────────────────────────────────────────────
    App->>Native: channel: update(args)
    Native->>ActivityKit: activity.update(ActivityContent)

    %% ── End / dismissal ──────────────────────────────────────────
    Note over Native,Supabase: User swipes away widget
    ActivityKit-->>Native: activityStateUpdates → .dismissed
    Native->>Native: cleanup(flightId)
    Native->>Supabase: deleteUpdateToken(flightId)\n[live_activities table]

    Note over App,Supabase: User taps "Stop" in app
    App->>Native: channel: end(flightId)
    Native->>ActivityKit: activity.end(dismissalPolicy:.immediate)
    Native->>Native: cleanup(flightId)
    App->>Supabase: DELETE live_activities WHERE flight_id=...
```

## Key concepts

- **Two token types** — `la_start_token` (one per device, `device_tokens` table) lets the server create an activity without the app in foreground. The per-activity `push_token` (one per flight, `live_activities` table) lets the server send updates.
- **Duplicate guard** — the edge function checks `live_activities` first: if a push token already exists it sends `event: update`, not `event: start`.
- **Multiple activities** — `LiveActivityManager` keys activities and push tokens by `flightId`, supporting concurrent Live Activities for different flights.
- **Dismissal cleanup** — `activityStateUpdates` detects `.dismissed` and deletes the DB row so the next cron run starts fresh.
