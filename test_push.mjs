import { createSign } from 'crypto'
import { readFileSync } from 'fs'
import http2 from 'http2'
const { connect } = http2

const KEY_ID    = '4LJ7W7NHMC'
const TEAM_ID   = '9SMXYTBRQ4'
const BUNDLE_ID = 'com.jsx.jsxAppCopy'
const P8_PATH   = '/Users/hyro010/Downloads/AuthKey_4LJ7W7NHMC.p8'

// Paste the push-to-start token from Xcode console: [LA] push-to-start token: ...
const START_TOKEN = process.env.START_TOKEN ?? 'PASTE_LA_START_TOKEN_HERE'

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

const jwt  = buildJwt()
const now  = Date.now()

const body = JSON.stringify({
  aps: {
    timestamp: Math.floor(now / 1000),
    event: 'start',
    'attributes-type': 'JSXFlightAttributes',
    attributes: {
      flightId:         'JSX-1021',
      origin:           'DAL',
      originCity:       'Dallas',
      destination:      'BUR',
      destinationCity:  'Los Angeles',
      departureTime:    '7:30 AM',
      arrivalTime:      '9:45 AM',
      confirmationCode: 'JSX4K8P',
    },
    'content-state': {
      status:           'On Time',
      phase:            'boarding',
      progress:         0,
      minutesRemaining: 120,
      altitudeFt:       0,
      speedMph:         0,
    },
    alert: {
      title: 'DAL → BUR',
      body:  'JSX-1021 added to Live Activities',
    },
  },
})

const session = connect('https://api.sandbox.push.apple.com')
const client  = session.request({
  ':method':        'POST',
  ':path':          `/3/device/${START_TOKEN}`,
  'authorization':  `bearer ${jwt}`,
  'apns-push-type': 'liveactivity',
  'apns-topic':     `${BUNDLE_ID}.push-type.liveactivity`,
  'apns-priority':  '10',
  'content-type':   'application/json',
  'content-length': Buffer.byteLength(body),
})

client.on('response', (headers) => {
  console.log('Status:', headers[':status'])
  client.on('data', d => console.log('Body:', d.toString()))
  client.on('end', () => session.destroy())
})

client.write(body)
client.end()
