import { createSign } from 'crypto'
import { readFileSync } from 'fs'
import http2 from 'http2'
const { connect } = http2

const KEY_ID = '4LJ7W7NHMC'
const TEAM_ID = '9SMXYTBRQ4'
const BUNDLE_ID = 'com.jsx.jsxAppCopy'
const DEVICE_TOKEN = 'f5c3db35277f99f826159ad1e6f3021147a753f842f013cc0b6b43428393422a'
const P8_PATH = '/Users/hyro010/Downloads/AuthKey_4LJ7W7NHMC.p8'

function base64url(buf) {
  return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}

function buildJwt() {
  const header = base64url(Buffer.from(JSON.stringify({ alg: 'ES256', kid: KEY_ID })))
  const payload = base64url(Buffer.from(JSON.stringify({ iss: TEAM_ID, iat: Math.floor(Date.now() / 1000) })))
  const unsigned = `${header}.${payload}`
  const sign = createSign('SHA256')
  sign.update(unsigned)
  const pem = readFileSync(P8_PATH, 'utf8')
  const sig = base64url(sign.sign({ key: pem, dsaEncoding: 'ieee-p1363' }))
  return `${unsigned}.${sig}`
}

const jwt = buildJwt()
const body = JSON.stringify({
  aps: { 'content-available': 1 },
  jsx_action: 'start_live_activity',
  flight_id: 'JSX-1021',
  origin: 'DAL',
  origin_city: 'Dallas',
  destination: 'BUR',
  destination_city: 'Los Angeles',
  departure_time: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(),
  arrival_time: new Date(Date.now() + 4 * 60 * 60 * 1000).toISOString(),
  confirmation_code: 'JSX4K8P',
  status: 'On Time',
  phase: 'boarding',
  progress: 0,
  minutes_remaining: 120,
  altitude_ft: 0,
  speed_mph: 0,
})

const session = connect('https://api.sandbox.push.apple.com')
const client = session.request({
  ':method': 'POST',
  ':path': `/3/device/${DEVICE_TOKEN}`,
  'authorization': `bearer ${jwt}`,
  'apns-push-type': 'background',
  'apns-topic': BUNDLE_ID,
  'apns-priority': '5',
  'content-type': 'application/json',
  'content-length': Buffer.byteLength(body),
})

client.on('response', (headers) => {
  console.log('Status:', headers[':status'])
  client.on('data', d => console.log('Body:', d.toString()))
  client.on('end', () => session.destroy())
})

client.write(body)
client.end()
