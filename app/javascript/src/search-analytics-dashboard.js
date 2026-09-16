import { Chart, registerables } from 'chart.js';
Chart.register(...registerables);

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.search-analytics-chart').forEach((canvas) => {
    const payload = JSON.parse(canvas.dataset.chart || '{}');
    const requestedType = canvas.dataset.chartType || 'line';
    const currencyAxis = canvas.dataset.yAxisFormat === 'currency';
    const stacked = canvas.dataset.stacked === 'true';
    const currency = new Intl.NumberFormat('en-GB', {
      style: 'currency',
      currency: 'USD',
      currencyDisplay: 'narrowSymbol',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    });
    const formatCost = (value) => {
      const amount = Number(value);
      if (value === null || value === undefined || !Number.isFinite(amount)) {
        return 'Unavailable';
      }
      return amount > 0 && amount < 0.01 ? '<$0.01' : currency.format(amount);
    };

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
          intersect: requestedType === 'pie',
          mode: requestedType === 'pie' ? 'nearest' : 'index',
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
        scales: requestedType === 'pie' ? {} : {
          x: {
            stacked,
            title: { display: Boolean(canvas.dataset.xAxisTitle), text: canvas.dataset.xAxisTitle },
            grid: { display: canvas.dataset.hideXGrid !== 'true' },
            ticks: {
              autoSkip: true,
              maxRotation: 0,
              maxTicksLimit: 8,
            },
          },
          y: {
            beginAtZero: true,
            stacked,
            title: { display: Boolean(canvas.dataset.yAxisTitle), text: canvas.dataset.yAxisTitle },
            ticks: {
              ...(currencyAxis ? { precision: 2, callback: formatCost } : { precision: 0 }),
            },
          },
        },
        plugins: {
          legend: {
            display: canvas.dataset.hideLegend !== 'true',
            position: 'bottom',
          },
          tooltip: currencyAxis ? {
            callbacks: {
              label: (context) => `${context.dataset.label}: ${formatCost(context.parsed.y)}`,
            },
          } : {},
        },
      },
    });
  });
});
