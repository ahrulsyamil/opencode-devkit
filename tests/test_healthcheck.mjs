// Run: node tests/test_healthcheck.mjs. Real runtime CI uses docker health status.
import { createServer } from 'node:http';
import assert from 'node:assert/strict';

const password = 'a-test-only-secret';
const server = createServer((req, res) => {
  assert.equal(req.headers.authorization,
    `Basic ${Buffer.from(`opencode:${password}`).toString('base64')}`);
  res.writeHead(req.url === '/global/health' ? 200 : 404);
  res.end('{}');
});
await new Promise((resolve) => server.listen(4095, '127.0.0.1', resolve));
// spawnSync blocks the event loop, so use async child handling instead.
const { spawn } = await import('node:child_process');
const child = spawn(process.execPath, ['scripts/healthcheck.mjs'], {
  env: { ...process.env, OPENCODE_PASSWORD: password }, stdio: 'inherit'
});
const code = await new Promise((resolve) => child.on('close', resolve));
server.close();
assert.equal(code, 0);
console.log('Healthcheck HTTP + auth probe passed.');
