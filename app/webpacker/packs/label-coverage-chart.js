import Chart from 'chart.js/auto';

const canvas = document.getElementById("label-coverage-chart");
const coverage = JSON.parse(canvas.dataset.coverage);

const chapters = coverage.map(d => d.chapter);
const counts = coverage.map(d => d.count);

const config = {
  type: "bar",
  data: {
    labels: chapters,
    datasets: [
      {
        label: "Labels",
        data: counts,
        backgroundColor: "#1d70b8",
        borderWidth: 0,
      },
    ],
  },
  options: {
    responsive: true,
    plugins: {
      legend: {
        display: false,
      },
      tooltip: {
        callbacks: {
          title: function(items) {
            return `Chapter ${items[0].label}`;
          },
          label: function(item) {
            return `${item.raw.toLocaleString()} labels`;
          },
        },
      },
    },
    scales: {
      x: {
        title: {
          display: true,
          text: "Chapter",
        },
        ticks: {
          maxRotation: 0,
          autoSkip: true,
          maxTicksLimit: 30,
        },
      },
      y: {
        title: {
          display: true,
          text: "Labels",
        },
        beginAtZero: true,
      },
    },
  },
};

new Chart(canvas, config);
