/**
 * Supabase Edge Function: update-live-activity
 *
 * Sends an APNs push to a Live Activity push token, updating the lock screen
 * and Dynamic Island without waking the app.
 *
 * Required secrets (set via `supabase secrets set KEY=value`):
 *   APNS_PRIVATE_KEY   – full contents of the .p8 file (including headers)
 *   APNS_KEY_ID        – 10-char key ID from Apple Developer portal
 *   APNS_TEAM_ID       – 10-char team ID from Apple Developer portal
 *   APNS_BUNDLE_ID     – com.jsx.jsxAppCopy
 *   APNS_ENV           – "sandbox" | "production"
 *
 * Call with POST body:
 * {
 *   "flight_id": "JSX-1021-20260422",
 *   "status": "On Time"
 * }
 */

import { createClient } from 'jsr:@supabase/supabase-js@2'
import { importPKCS8, SignJWT } from 'npm:jose@5'

const APNS_HOST = Deno.env.get('APNS_ENV') === 'production'
  ? 'https://api.push.apple.com'
  : 'https://api.sandbox.push.apple.com'

// Swift's Codable decodes Date as seconds since Jan 1 2001, not Unix epoch.
const swiftEpochOffset = 978307200
function toSwiftDate(iso: string): number {
  return Math.floor(new Date(iso).getTime() / 1000) - swiftEpochOffset
}

function fmtTime(iso: string): string {
  const d = new Date(iso)
  const h = d.getUTCHours()
  const m = d.getUTCMinutes().toString().padStart(2, '0')
  const period = h >= 12 ? 'PM' : 'AM'
  const hour = h % 12 || 12
  return `${hour}:${m} ${period}`
}

Deno.serve(async (req: Request) => {
  try {
    const body = await req.json()
    const { flight_id, status = 'On Time' } = body

    if (!flight_id) {
      return new Response(JSON.stringify({ error: 'flight_id required' }), { status: 400 })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Fetch push token + flight times in one query
    const { data, error } = await supabase
      .from('live_activities')
      .select(`
        push_token,
        flight:flights!live_activities_flight_id_fkey (
          departure_at,
          arrival_at
        )
      `)
      .eq('flight_id', flight_id)
      .order('created_at', { ascending: false })
      .limit(1)
      .single()

    if (error || !data) {
      return new Response(JSON.stringify({ error: 'No active Live Activity for this flight' }), { status: 404 })
    }

    const flight = data.flight as any

    const contentState = {
      status,
      phase:         'pre_departure',
      progress:      0,
      departureTime: flight?.departure_at ? toSwiftDate(flight.departure_at) : 0,
      arrivalTime:   flight?.arrival_at   ? toSwiftDate(flight.arrival_at)   : 0,
      gate:          '',
      boardingTime:  flight?.departure_at ? fmtTime(flight.departure_at)     : '',
      altitudeFt:    0,
      speedMph:      0,
    }

    // Build APNs JWT
    const privateKey = await importPKCS8(Deno.env.get('APNS_PRIVATE_KEY')!, 'ES256')
    const jwt = await new SignJWT({})
      .setProtectedHeader({ alg: 'ES256', kid: Deno.env.get('APNS_KEY_ID')! })
      .setIssuedAt()
      .setIssuer(Deno.env.get('APNS_TEAM_ID')!)
      .sign(privateKey)

    const payload = {
      aps: {
        timestamp: Math.floor(Date.now() / 1000),
        event: 'update',
        'content-state': contentState,
      },
    }

    const bundleId = Deno.env.get('APNS_BUNDLE_ID')!
    const apnsResponse = await fetch(
      `${APNS_HOST}/3/device/${data.push_token}`,
      {
        method: 'POST',
        headers: {
          authorization: `bearer ${jwt}`,
          'apns-push-type': 'liveactivity',
          'apns-topic': `${bundleId}.push-type.liveactivity`,
          'apns-priority': '10',
          'content-type': 'application/json',
        },
        body: JSON.stringify(payload),
      },
    )

    if (!apnsResponse.ok) {
      const errBody = await apnsResponse.text()
      return new Response(
        JSON.stringify({ error: 'APNs error', detail: errBody, status: apnsResponse.status }),
        { status: 502 },
      )
    }

    return new Response(JSON.stringify({ ok: true }), { status: 200 })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 })
  }
})
