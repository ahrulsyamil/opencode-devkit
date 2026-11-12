import http from 'node:http';

const password = process.env.OPENCODE_PASSWORD;
const paths = ['/global/health', '/api/info']; // OpenCode API compatibility
if (!password) process.exit(1);
const auth = `Basic ${Buffer.from(`opencode:${password}`).toString('base64')}`;

async function probe(path) {
  return new Promise((resolve) => {
    const req = http.get({
      hostname: '127.0.0.1', port: 4095, path,
      timeout: 4500, headers: { Authorization: auth },
    }, (res) => {
      res.resume();
      resolve(res.statusCode === 200);
    });
    req.on('timeout', () => req.destroy());
    req.on('error', () => resolve(false));
  });
}

for (const path of paths) {
  if (await probe(path)) process.exit(0);
}
process.exit(1);
