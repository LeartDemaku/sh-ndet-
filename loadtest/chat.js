// loadtest/chat.js  ->  k6 run -e BASE_URL=http://localhost:8000 -e TOKEN=... chat.js
//
// SHENIM: RATE_LIMIT_PER_MIN=20 (per perdorues). Nje test me shume VU dhe NJE token
// do te marre 429 pas 20 kerkesave ne minute. Per testin e plote:
//   - perdor nje token per secilin VU (regjistro N perdorues), ose
//   - rrit perkohsisht RATE_LIMIT_PER_MIN ne .env dhe rinis API-n.
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 50 },   // ngrohje
    { duration: '5m', target: 50 },   // ngarkesë e qëndrueshme
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<12000'],   // përfshin gjithë streaming-un
  },
};

export default function () {
  const res = http.post(
    `${__ENV.BASE_URL}/v1/chat/stream`,
    JSON.stringify({ message: 'Kam dhimbje koke prej dy ditësh.' }),
    { headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${__ENV.TOKEN}` } },
  );
  check(res, { 'status 200': (r) => r.status === 200 });
  sleep(Math.random() * 5 + 2);
}
