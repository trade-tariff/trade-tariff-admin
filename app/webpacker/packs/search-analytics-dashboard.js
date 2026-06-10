import Chart from 'chart.js/auto';

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.search-analytics-chart').forEach((canvas) => {
    const payload = JSON.parse(canvas.dataset.chart || '{}');
    const requestedType = canvas.dataset.chartType || 'line';

    if (!payload.labels || !payload.datasets) {
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
            ticks: {
              autoSkip: true,
              maxRotation: 0,
              maxTicksLimit: 8,
            },
          },
          y: {
            beginAtZero: true,
            ticks: {
              precision: 0,
            },
          },
        },
        plugins: {
          legend: {
            position: 'bottom',
          },
        },
      },
    });
  });
});
