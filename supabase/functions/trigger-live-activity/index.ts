/**
 * Supabase Edge Function: trigger-live-activity
 *
 * Finds bookings departing within the next 2 hours and sends a silent APNs
 * push to the user's device, which wakes the app in the background and
 * starts a Live Activity automatically.
 *
 * Call with POST (no body required) — intended to be triggered by a cron job
 * every 15 minutes, or manually for testing.
 *
 * Silent push payload includes all data needed to call Activity.request()
 * without the app needing to fetch anything from the network.
 */

import { createClient } from 'jsr:@supabase/supabase-js@2'
import { importPKCS8, SignJWT } from 'npm:jose@5'

const APNS_HOST = Deno.env.get('APNS_ENV') === 'production'
  ? 'https://api.push.apple.com'
  : 'https://api.sandbox.push.apple.com'


async function buildJwt() {
  const key = await importPKCS8(Deno.env.get('APNS_PRIVATE_KEY')!, 'ES256')
  return new SignJWT({})
    .setProtectedHeader({ alg: 'ES256', kid: Deno.env.get('APNS_KEY_ID')! })
    .setIssuedAt()
    .setIssuer(Deno.env.get('APNS_TEAM_ID')!)
    .sign(key)
}

async function sendSilentPush(deviceToken: string, payload: object, jwt: string) {
  const bundleId = Deno.env.get('APNS_BUNDLE_ID')!
  const res = await fetch(`${APNS_HOST}/3/device/${deviceToken}`, {
    method: 'POST',
    headers: {
      authorization: `bearer ${jwt}`,
      'apns-push-type': 'background',
      'apns-topic': bundleId,
      'apns-priority': '5', // 5 = normal priority for background pushes
      'content-type': 'application/json',
    },
    body: JSON.stringify(payload),
  })
  return { status: res.status, body: await res.text() }
}

Deno.serve(async () => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Find bookings departing in 1.5–2.5 hours
    const { data: bookings, error } = await supabase
      .from('bookings')
      .select(`
        confirmation_code,
        departure_time,
        arrival_time,
        user_id,
        flight_schedules!flight_id (
          id,
          status,
          airports!origin_code ( code, city ),
          dest:airports!dest_code ( code, city )
        )
      `)
      .gte('departure_time', new Date(Date.now() + 90 * 60 * 1000).toISOString())
      .lte('departure_time', new Date(Date.now() + 150 * 60 * 1000).toISOString())
      .eq('status', 'confirmed')

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), { status: 500 })
    }

    if (!bookings || bookings.length === 0) {
      return new Response(JSON.stringify({ ok: true, triggered: 0 }), { status: 200 })
    }

    const jwt = await buildJwt()
    const results = []

    for (const booking of bookings) {
      const fs = booking.flight_schedules as any
      const origin = fs.airports
      const dest = fs.dest

      // Get device token for this user
      const { data: dt } = await supabase
        .from('device_tokens')
        .select('token')
        .eq('user_id', booking.user_id)
        .single()

      if (!dt) {
        results.push({ flight: fs.id, error: 'no device token' })
        continue
      }

      const minutesRemaining = Math.round(
        (new Date(booking.departure_time).getTime() - Date.now()) / 60000,
      )

      const payload = {
        aps: { 'content-available': 1 },
        jsx_action: 'start_live_activity',
        flight_id: fs.id,
        origin: origin.code,
        origin_city: origin.city,
        destination: dest.code,
        destination_city: dest.city,
        departure_time: booking.departure_time,
        arrival_time: booking.arrival_time,
        confirmation_code: booking.confirmation_code,
        status: fs.status === 'on_time' ? 'On Time' : fs.status === 'delayed' ? 'Delayed' : 'Boarding',
        phase: 'boarding',
        progress: 0,
        minutes_remaining: minutesRemaining,
        altitude_ft: 0,
        speed_mph: 0,
      }

      const result = await sendSilentPush(dt.token, payload, jwt)
      results.push({ flight: fs.id, apns_status: result.status, apns_body: result.body })
    }

    return new Response(JSON.stringify({ ok: true, triggered: results.length, results }), {
      status: 200,
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 })
  }
})
