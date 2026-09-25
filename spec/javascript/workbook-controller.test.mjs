import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { runInNewContext } from 'node:vm';

const source = readFileSync(new URL('../../app/javascript/controllers/workbook_controller.js', import.meta.url), 'utf8')
  .replace("import { Controller } from '@hotwired/stimulus';", '')
  .replace('export default class', 'globalThis.Workbook = class');

function setup(fetch = async () => response(true)) {
  const timers = new Map();
  const calls = [];
  let id = 0;
  const context = { Controller: class {}, AbortController,
    setTimeout: (callback, delay) => { timers.set(++id, { callback, delay }); return id; },
    clearTimeout: key => timers.delete(key),
    fetch: (...args) => { calls.push(args); return fetch(...args); },
  };
  runInNewContext(source, context);
  const controller = new context.Workbook();
  Object.assign(controller, { pendingValue: true, urlValue: '/search_export_workbooks/42.json',
    statusTarget: { innerHTML: 'original' }, messageTarget: { textContent: 'Preparing your workbook…' } });
  const fire = async delay => {
    const [key, timer] = [...timers].find(([, timer]) => timer.delay === delay);
    timers.delete(key);
    await timer.callback();
  };
  return { controller, timers, calls, fire };
}
const response = (pending, html = 'updated') => ({ ok: true, redirected: false, json: async () => ({ pending, html }) });

test('polls without navigation and leaves pending content unchanged', async () => {
  const { controller, fire, calls, timers } = setup();
  controller.connect();
  await fire(2000);
  assert.equal(calls.length, 1);
  assert.equal(calls[0][1].headers.Accept, 'application/json');
  assert.equal(calls[0][1].cache, 'no-store');
  assert.equal(controller.statusTarget.innerHTML, 'original');
  assert.equal(timers.size, 2);
  controller.disconnect();
});

for (const html of ['Download workbook', 'The workbook could not be built.']) {
  test(`renders terminal status and stops: ${html}`, async () => {
    const { controller, fire, timers } = setup(async () => response(false, html));
    controller.connect();
    await fire(2000);
    assert.equal(controller.statusTarget.innerHTML, html);
    assert.equal(timers.size, 0);
  });
}

for (const result of [
  { ok: false, status: 404 }, { ok: false, status: 503 },
  { ok: true, redirected: true },
  { ok: true, json: async () => ({}) },
  { ok: true, json: async () => { throw new Error('Not JSON'); } },
]) {
  test(`stops on unavailable or invalid status: ${JSON.stringify(result)}`, async () => {
    const { controller, fire, timers } = setup(async () => result);
    controller.connect();
    await fire(2000);
    assert.match(controller.messageTarget.textContent, /Could not check/);
    assert.equal(controller.statusTarget.innerHTML, 'original');
    assert.equal(timers.size, 0);
  });
}

test('network failure offers a manual check', async () => {
  const { controller, fire } = setup(async () => { throw new Error('Offline'); });
  controller.connect();
  await fire(2000);
  assert.match(controller.messageTarget.textContent, /Try checking again/);
});

test('deadline stops polling and aborts an outstanding request', async () => {
  const { controller, fire, timers } = setup();
  controller.connect();
  const signal = controller.requestController.signal;
  await fire(180000);
  assert.equal(signal.aborted, true);
  assert.equal(timers.size, 0);
  assert.match(controller.messageTarget.textContent, /taking longer/);
});

test('disconnect ignores a late response and clears timers', async () => {
  let resolve;
  const { controller, fire, timers } = setup(() => new Promise(done => { resolve = done; }));
  controller.connect();
  const pending = fire(2000);
  controller.disconnect();
  resolve(response(false, 'late'));
  await pending;
  assert.equal(controller.statusTarget.innerHTML, 'original');
  assert.equal(timers.size, 0);
});

test('does not poll a completed export', () => {
  const { controller, timers } = setup();
  controller.pendingValue = false;
  controller.connect();
  assert.equal(timers.size, 0);
});
