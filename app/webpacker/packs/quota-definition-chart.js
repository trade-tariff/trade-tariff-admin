import Chart from 'chart.js/auto';

const canvas = document.getElementById("quota-definitions-chart");
const chartDataset = canvas.dataset;
const measurementUnitCode = chartDataset.measurementunitcode
const importedAmounts = JSON.parse(chartDataset.importedamounts);
const newBalances = JSON.parse(chartDataset.newbalances);
const occurrenceTimestamps = JSON.parse(chartDataset.occurrencetimestamps);

const config = {
  type: "line",
  data: {
    labels: occurrenceTimestamps,
    datasets: [
      {
        label: `Imported amount (${measurementUnitCode})`,
        fill: true,
        backgroundColor: "rgba(204, 204, 204, 0.5)",
        borderColor: "#ccc",
        data: importedAmounts,
      },
      {
        label: `Quota balance (${measurementUnitCode})`,
        borderColor: "#1d70b8",
        backgroundColor: "rgba(29, 112, 184, 0.1)",
        fill: true,
        data: newBalances,
      },
    ],
  },
  options: {
    legend: {
      display: true,
    },
    title: {
      display: true,
      text: "Quota balance updates",
    },
    scales: {
      yAxes: [
        {
          display: true,
          ticks: {
            beginAtZero: true,
          },
        },
      ],
    },
  },
};

new Chart(canvas, config);

