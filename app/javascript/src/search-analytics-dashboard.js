import { Chart, registerables } from 'chart.js';
Chart.register(...registerables);

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.search-analytics-chart').forEach((canvas) => {
    const payload = JSON.parse(canvas.dataset.chart || '{}');
    const requestedType = canvas.dataset.chartType || 'line';
    const currencyAxis = canvas.dataset.yAxisFormat === 'currency';
    const stacked = canvas.dataset.stacked === 'true';
    const currency = new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      maximumFractionDigits: 6,
    });

    if (!payload.labels || !payload.datasets) {
      return;
    }

    payload.datasets = payload.datasets.filter((dataset) => (
      dataset.data || []
    ).some((value) => Number(value) !== 0));

    if (payload.datasets.length === 0) {
      return;
    }

    new Chart(canvas, {
      type: requestedType === 'line' && payload.labels.length < 2 ? 'bar' : requestedType,
      data: payload,
      options: {
        animation: false,
        interaction: {
          intersect: false,
          mode: 'index',
        },
        responsive: true,
        maintainAspectRatio: false,
        elements: {
          line: {
            tension: 0,
          },
          point: {
            hoverRadius: 5,
            radius: 3,
          },
        },
        scales: {
          x: {
            stacked,
            ticks: {
              autoSkip: true,
              maxRotation: 0,
              maxTicksLimit: 8,
            },
          },
          y: {
            beginAtZero: true,
            stacked,
            ticks: {
              ...(currencyAxis ? { callback: (value) => currency.format(value) } : { precision: 0 }),
            },
          },
        },
        plugins: {
          legend: {
            position: 'bottom',
          },
          tooltip: currencyAxis ? {
            callbacks: {
              label: (context) => `${context.dataset.label}: ${currency.format(context.parsed.y)}`,
            },
          } : {},
        },
      },
    });
  });
});
