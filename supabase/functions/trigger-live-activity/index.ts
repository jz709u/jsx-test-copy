/**
 * Supabase Edge Function: trigger-live-activity
 *
 * Finds bookings departing within the next 2 hours and sends an APNs
 * push-to-start Live Activity push directly to ActivityKit (iOS 17.2+).
 * iOS starts the Live Activity without the app needing to be in the foreground.
 */

import { createClient } from 'jsr:@supabase/supabase-js@2'
import { importPKCS8, SignJWT } from 'npm:jose@5'

const APNS_HOST = Deno.env.get('APNS_ENV') === 'production'
  ? 'https://api.push.apple.com'
  : 'https://api.sandbox.push.apple.com'

const BUNDLE_ID = Deno.env.get('APNS_BUNDLE_ID')!

async function buildJwt() {
  const key = await importPKCS8(Deno.env.get('APNS_PRIVATE_KEY')!, 'ES256')
  return new SignJWT({})
    .setProtectedHeader({ alg: 'ES256', kid: Deno.env.get('APNS_KEY_ID')! })
    .setIssuedAt()
    .setIssuer(Deno.env.get('APNS_TEAM_ID')!)
    .sign(key)
}

async function sendStartPush(startToken: string, payload: object, jwt: string) {
  const res = await fetch(`${APNS_HOST}/3/device/${startToken}`, {
    method: 'POST',
    headers: {
      authorization: `bearer ${jwt}`,
      'apns-push-type': 'liveactivity',
      'apns-topic': `${BUNDLE_ID}.push-type.liveactivity`,
      'apns-priority': '10',
      'content-type': 'application/json',
    },
    body: JSON.stringify(payload),
  })
  return { status: res.status, body: await res.text() }
}

function fmtTime(iso: string): string {
  const d = new Date(iso)
  const h = d.getUTCHours()
  const m = d.getUTCMinutes().toString().padStart(2, '0')
  const period = h >= 12 ? 'PM' : 'AM'
  const hour = h % 12 || 12
  return `${hour}:${m} ${period}`
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

      // Fetch push-to-start token for this user
      const { data: dt } = await supabase
        .from('device_tokens')
        .select('la_start_token')
        .eq('user_id', booking.user_id)
        .single()

      if (!dt?.la_start_token) {
        results.push({ flight: fs.id, error: 'no la_start_token — device not on iOS 17.2+' })
        continue
      }

      const minutesRemaining = Math.round(
        (new Date(booking.departure_time).getTime() - Date.now()) / 60000,
      )

      const payload = {
        aps: {
          timestamp: Math.floor(Date.now() / 1000),
          event: 'start',
          'attributes-type': 'JSXFlightAttributes',
          attributes: {
            flightId:         fs.id,
            origin:           origin.code,
            originCity:       origin.city,
            destination:      dest.code,
            destinationCity:  dest.city,
            departureTime:    fmtTime(booking.departure_time),
            arrivalTime:      fmtTime(booking.arrival_time),
            confirmationCode: booking.confirmation_code,
          },
          'content-state': {
            status:           fs.status === 'delayed' ? 'Delayed' : fs.status === 'boarding' ? 'Boarding' : 'On Time',
            phase:            'boarding',
            progress:         0,
            minutesRemaining: minutesRemaining,
            altitudeFt:       0,
            speedMph:         0,
          },
          alert: {
            title: `${origin.code} → ${dest.code}`,
            body:  `${fs.id} added to Live Activities`,
          },
        },
      }

      const result = await sendStartPush(dt.la_start_token, payload, jwt)
      results.push({ flight: fs.id, apns_status: result.status, apns_body: result.body })
    }

    return new Response(JSON.stringify({ ok: true, triggered: results.length, results }), {
      status: 200,
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 })
  }
})
