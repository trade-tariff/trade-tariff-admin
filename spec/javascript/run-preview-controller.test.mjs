import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { runInNewContext } from 'node:vm';

const source = readFileSync(new URL('../../app/javascript/controllers/run_preview_controller.js', import.meta.url), 'utf8')
  .replace("import { Controller } from '@hotwired/stimulus';", '')
  .replace('export default class', 'globalThis.RunPreview = class');

function fakeElement(tag) {
  return {
    tagName: tag, className: '', textContent: '', children: [],
    appendChild(child) { this.children.push(child); return child; },
  };
}

function fakePreviewTarget() {
  let html;
  return {
    get innerHTML() { return html; },
    set innerHTML(value) { html = value; },
    replaceChildren(...nodes) { this.children = nodes; },
  };
}

function setup({ experiments = {}, baseline = {}, experimentId = '7', overrideFields = [] } = {}) {
  const context = { Controller: class {}, document: { createElement: fakeElement } };
  runInNewContext(source, context);
  const controller = new context.RunPreview();
  Object.assign(controller, {
    baselineValue: baseline,
    experimentsValue: experiments,
    experimentSelectTarget: { value: experimentId },
    previewTarget: fakePreviewTarget(),
    overrideFieldTargets: overrideFields,
  });
  return controller;
}

function allText(node) {
  return [node.textContent, ...node.children.map(allText)].join('|');
}

test('never writes attacker-controlled text through innerHTML', () => {
  const payload = '<img src=x onerror=alert(1)>';
  const controller = setup({ experiments: { 7: { gold_query_set_name: payload, overrides: {} } } });

  controller.render();

  assert.equal(controller.previewTarget.innerHTML, undefined, 'innerHTML must never be assigned once overrides/set names are rendered');
});

test('renders the gold query set name as literal text, not parsed HTML', () => {
  const payload = '<img src=x onerror=alert(1)>';
  const controller = setup({ experiments: { 7: { gold_query_set_name: payload, overrides: {} } } });

  controller.render();

  const rendered = controller.previewTarget.children.map(allText).join('|');
  assert.match(rendered, new RegExp(payload.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
});

test('renders an override value containing markup as literal text', () => {
  const payload = '<script>alert(1)</script>';
  const controller = setup({
    baseline: { question_model: 'gpt-5.4' },
    experiments: { 7: { gold_query_set_name: 'Set A', overrides: { question_model: payload } } },
  });

  controller.render();

  const rendered = controller.previewTarget.children.map(allText).join('|');
  assert.match(rendered, new RegExp(payload.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
});

test('shows the prompt when no experiment is selected, with no stray list', () => {
  const controller = setup({ experimentId: '' });

  controller.render();

  const [heading, paragraph, ...rest] = controller.previewTarget.children;
  assert.equal(heading.textContent, 'Preview');
  assert.equal(paragraph.textContent, 'Choose an experiment to see what this run will use.');
  assert.equal(rest.length, 0);
});

test('shows item count alongside the set name when present', () => {
  const controller = setup({ experiments: { 7: { gold_query_set_name: 'Set A', gold_query_set_item_count: 5, overrides: {} } } });

  controller.render();

  const [, paragraph] = controller.previewTarget.children;
  assert.equal(paragraph.textContent, 'Set A (5 items)');
});

test('layers typed field values over the experiment and baseline overrides', () => {
  const controller = setup({
    baseline: { max_rounds: 7 },
    experiments: { 7: { gold_query_set_name: 'Set A', overrides: {} } },
    overrideFields: [{ dataset: { overrideKey: 'max_rounds' }, type: 'number', value: '3' }],
  });

  controller.render();

  const rendered = controller.previewTarget.children.map(allText).join('|');
  assert.match(rendered, /max_rounds: 3/);
});
