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
 *   "flight_id": "JSX-1021",
 *   "status": "On Time",
 *   "phase": "cruising",
 *   "progress": 0.45,
 *   "minutesRemaining": 42,
 *   "altitudeFt": 37000,
 *   "speedMph": 480
 * }
 */

import { createClient } from 'jsr:@supabase/supabase-js@2'
import { importPKCS8, SignJWT } from 'npm:jose@5'

const APNS_HOST = Deno.env.get('APNS_ENV') === 'production'
  ? 'https://api.push.apple.com'
  : 'https://api.sandbox.push.apple.com'

Deno.serve(async (req: Request) => {
  try {
    const body = await req.json()
    const {
      flight_id,
      status = 'On Time',
      phase = 'cruising',
      progress = 0,
      minutesRemaining = 0,
      altitudeFt = 0,
      speedMph = 0,
    } = body

    if (!flight_id) {
      return new Response(JSON.stringify({ error: 'flight_id required' }), { status: 400 })
    }

    // Fetch the push token from Supabase
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )
    const { data, error } = await supabase
      .from('live_activities')
      .select('push_token')
      .eq('flight_id', flight_id)
      .order('created_at', { ascending: false })
      .limit(1)
      .single()

    if (error || !data) {
      return new Response(JSON.stringify({ error: 'No active Live Activity for this flight' }), { status: 404 })
    }

    // Build APNs JWT (valid for 60 min, Apple recommends refreshing every 20 min)
    const privateKeyPem = Deno.env.get('APNS_PRIVATE_KEY')!
    const privateKey = await importPKCS8(privateKeyPem, 'ES256')
    const jwt = await new SignJWT({})
      .setProtectedHeader({ alg: 'ES256', kid: Deno.env.get('APNS_KEY_ID')! })
      .setIssuedAt()
      .setIssuer(Deno.env.get('APNS_TEAM_ID')!)
      .sign(privateKey)

    // APNs Live Activity update payload
    const payload = {
      aps: {
        timestamp: Math.floor(Date.now() / 1000),
        event: 'update',
        'content-state': {
          status,
          phase,
          progress,
          minutesRemaining,
          altitudeFt,
          speedMph,
        },
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
