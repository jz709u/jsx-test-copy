import { createSign } from 'crypto'
import { readFileSync } from 'fs'
import http2 from 'http2'
const { connect } = http2

const KEY_ID    = '4LJ7W7NHMC'
const TEAM_ID   = '9SMXYTBRQ4'
const BUNDLE_ID = 'com.jsx.jsxAppCopy'
const P8_PATH   = '/Users/hyro010/Downloads/AuthKey_4LJ7W7NHMC.p8'

const START_TOKEN = process.env.START_TOKEN ?? 'PASTE_LA_START_TOKEN_HERE'

// Swift Codable decodes Date as seconds since Jan 1 2001, not Unix epoch.
const swiftEpochOffset = 978307200
function toSwiftDate(offsetMinutes) {
  return Math.floor(Date.now() / 1000) + offsetMinutes * 60 - swiftEpochOffset
}

const FLIGHTS = [
  {
    flightId:         'JSX-1021',
    origin:           'DAL',
    originCity:       'Dallas',
    destination:      'BUR',
    destinationCity:  'Los Angeles',
    confirmationCode: 'JSX4K8P',
    seat:             '12A',
    departureOffset:  90,   // departs in 90 min
    arrivalOffset:    210,  // arrives in 210 min
  },
  {
    flightId:         'JSX-2045',
    origin:           'BUR',
    originCity:       'Los Angeles',
    destination:      'DAL',
    destinationCity:  'Dallas',
    confirmationCode: 'JSX9Z3X',
    seat:             '4B',
    departureOffset:  120,
    arrivalOffset:    240,
  },
]

function base64url(buf) {
  return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}

function buildJwt() {
  const header  = base64url(Buffer.from(JSON.stringify({ alg: 'ES256', kid: KEY_ID })))
  const payload = base64url(Buffer.from(JSON.stringify({ iss: TEAM_ID, iat: Math.floor(Date.now() / 1000) })))
  const unsigned = `${header}.${payload}`
  const sign = createSign('SHA256')
  sign.update(unsigned)
  const pem = readFileSync(P8_PATH, 'utf8')
  const sig = base64url(sign.sign({ key: pem, dsaEncoding: 'ieee-p1363' }))
  return `${unsigned}.${sig}`
}

async function sendPush(jwt, flight) {
  const body = JSON.stringify({
    aps: {
      timestamp: Math.floor(Date.now() / 1000),
      event: 'start',
      'attributes-type': 'JSXFlightAttributes',
      attributes: {
        flightId:         flight.flightId,
        origin:           flight.origin,
        originCity:       flight.originCity,
        destination:      flight.destination,
        destinationCity:  flight.destinationCity,
        confirmationCode: flight.confirmationCode,
        seat:             flight.seat,
      },
      'content-state': {
        status:        'On Time',
        phase:         'pre_departure',
        progress:      0,
        departureTime: toSwiftDate(flight.departureOffset),
        arrivalTime:   toSwiftDate(flight.arrivalOffset),
        gate:          'B12',
        boardingTime:  '',
        altitudeFt:    0,
        speedMph:      0,
      },
      alert: {
        title: `${flight.origin} → ${flight.destination}`,
        body:  `${flight.flightId} added to Live Activities`,
      },
    },
  })

  return new Promise((resolve) => {
    const session = connect('https://api.sandbox.push.apple.com')
    const req = session.request({
      ':method':        'POST',
      ':path':          `/3/device/${START_TOKEN}`,
      'authorization':  `bearer ${jwt}`,
      'apns-push-type': 'liveactivity',
      'apns-topic':     `${BUNDLE_ID}.push-type.liveactivity`,
      'apns-priority':  '10',
      'content-type':   'application/json',
      'content-length': Buffer.byteLength(body),
    })

    let status
    req.on('response', (headers) => { status = headers[':status'] })
    req.on('data', d => process.stdout.write(d))
    req.on('end', () => {
      console.log(`\n[${flight.flightId}] APNs status: ${status}`)
      session.destroy()
      resolve(status)
    })
    req.write(body)
    req.end()
  })
}

const jwt = buildJwt()
console.log('Sending 2 live activity start pushes...\n')
for (const flight of FLIGHTS) {
  await sendPush(jwt, flight)
  await new Promise(r => setTimeout(r, 500)) // small gap between pushes
}
console.log('\nDone.')
