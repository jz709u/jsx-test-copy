/**
 * Supabase Edge Function: trigger-live-activity
 *
 * Finds bookings departing within the next 2 hours.
 * - If no Live Activity exists for the flight: sends push-to-start (iOS 17.2+)
 * - If one already exists: sends an update push to avoid duplicate widgets
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

async function sendPush(token: string, payload: object, jwt: string, isUpdate: boolean) {
  const res = await fetch(`${APNS_HOST}/3/device/${token}`, {
    method: 'POST',
    headers: {
      authorization: `bearer ${jwt}`,
      'apns-push-type': 'liveactivity',
      'apns-topic': `${BUNDLE_ID}.push-type.liveactivity`,
      'apns-priority': isUpdate ? '5' : '10',
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
      .gte('departure_time', new Date(Date.now() + 10 * 60 * 1000).toISOString())
      .lte('departure_time', new Date(Date.now() + 180 * 60 * 1000).toISOString())
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

      const minutesRemaining = Math.round(
        (new Date(booking.departure_time).getTime() - Date.now()) / 60000,
      )

      const contentState = {
        status:           fs.status === 'delayed' ? 'Delayed' : fs.status === 'boarding' ? 'Boarding' : 'On Time',
        phase:            'boarding',
        progress:         0,
        minutesRemaining: minutesRemaining,
        altitudeFt:       0,
        speedMph:         0,
      }

      // Check if a Live Activity already exists for this flight
      const { data: la } = await supabase
        .from('live_activities')
        .select('push_token')
        .eq('flight_id', fs.id)
        .single()

      if (la?.push_token) {
        // Activity already running — send update to avoid duplicate widget
        const payload = {
          aps: {
            timestamp: Math.floor(Date.now() / 1000),
            event: 'update',
            'content-state': contentState,
          },
        }
        const result = await sendPush(la.push_token, payload, jwt, true)
        results.push({ flight: fs.id, action: 'update', apns_status: result.status, apns_body: result.body })
        continue
      }

      // No active Live Activity — start one
      const { data: dt } = await supabase
        .from('device_tokens')
        .select('la_start_token')
        .eq('user_id', booking.user_id)
        .single()

      if (!dt?.la_start_token) {
        results.push({ flight: fs.id, error: 'no la_start_token — device not on iOS 17.2+' })
        continue
      }

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
          'content-state': contentState,
          alert: {
            title: `${origin.code} → ${dest.code}`,
            body:  `${fs.id} added to Live Activities`,
          },
        },
      }

      const result = await sendPush(dt.la_start_token, payload, jwt, false)
      results.push({ flight: fs.id, action: 'start', apns_status: result.status, apns_body: result.body })
    }

    return new Response(JSON.stringify({ ok: true, triggered: results.length, results }), {
      status: 200,
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 })
  }
})
