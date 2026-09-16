import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { runInNewContext } from 'node:vm';

// Exercise the real chart initializer with only its DOM and Chart.js boundary stubbed.
const source = readFileSync(new URL('../../app/javascript/src/search-analytics-dashboard.js', import.meta.url), 'utf8')
  .replace("import { Chart, registerables } from 'chart.js';", '');

function renderChart(values, currency = true, chartType = 'bar', attributes = {}) {
  const charts = [];
  const canvas = {
    dataset: {
      chart: JSON.stringify({
        labels: values.map((_, index) => String(index)),
        datasets: [{ label: 'Estimated AI cost', data: values }],
      }),
      chartType,
      yAxisFormat: currency ? 'currency' : undefined,
      ...attributes,
    },
  };
  class Chart {
    static register() {}
    constructor(_canvas, config) { charts.push(config); }
  }
  runInNewContext(source, {
    Chart,
    registerables: [],
    document: {
      addEventListener: (_event, listener) => listener(),
      querySelectorAll: () => [canvas],
    },
  });
  return charts[0];
}

for (const [value, expected] of [
  [0, '$0.00'],
  [1, '$1.00'],
  [0.313641, '$0.31'],
  [1234.565, '$1,234.57'],
  [0.01, '$0.01'],
  [0.000025, '<$0.01'],
  [null, 'Unavailable'],
  [NaN, 'Unavailable'],
]) {
  test(`formats chart costs ${value} as ${expected}`, () => {
    const chart = renderChart([0.313641]);
    assert.equal(chart.options.scales.y.ticks.callback(value), expected);
    assert.equal(chart.options.plugins.tooltip.callbacks.label({ dataset: { label: 'Estimated AI cost' }, parsed: { y: value } }), `Estimated AI cost: ${expected}`);
  });
}

test('retains subcent data while using cent-resolution axis ticks', () => {
  const chart = renderChart([0.000025]);
  assert.equal(chart.data.datasets[0].data[0], 0.000025);
  assert.equal(chart.options.scales.y.ticks.precision, 2);
  assert.equal(chart.options.scales.y.stacked, false);
});

test('leaves count charts on integer axes', () => {
  const chart = renderChart([12], false);
  assert.equal(chart.options.scales.y.ticks.precision, 0);
  assert.equal(chart.options.scales.y.ticks.callback, undefined);
});

test('renders action pies without Cartesian axes and targets the hovered segment', () => {
  const chart = renderChart([5, 2], false, 'pie');
  assert.equal(chart.type, 'pie');
  assert.deepEqual(Object.keys(chart.options.scales), []);
  assert.deepEqual(Array.from(chart.data.datasets[0].data), [5, 2]);
  assert.equal(chart.options.interaction.mode, 'nearest');
  assert.equal(chart.options.interaction.intersect, true);
  assert.equal(chart.options.plugins.legend.position, 'bottom');
});

test('labels question-distribution axes without a redundant legend or vertical grid', () => {
  const chart = renderChart([6, 5, 3], false, 'bar', {
    xAxisTitle: 'Reported questions', yAxisTitle: 'Journeys', hideLegend: 'true', hideXGrid: 'true',
  });
  assert.equal(chart.options.scales.x.title.text, 'Reported questions');
  assert.equal(chart.options.scales.x.title.display, true);
  assert.equal(chart.options.scales.y.title.text, 'Journeys');
  assert.equal(chart.options.scales.y.ticks.precision, 0);
  assert.equal(chart.options.scales.x.grid.display, false);
  assert.equal(chart.options.plugins.legend.display, false);
});

test('keeps a single-category pie and skips an empty action pie', () => {
  assert.equal(renderChart([5], false, 'pie').type, 'pie');
  assert.equal(renderChart([0, 0], false, 'pie'), undefined);
});

test('does not create a chart for an entirely zero-cost dataset', () => {
  assert.equal(renderChart([0, 0]), undefined);
});
