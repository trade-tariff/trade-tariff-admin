import Chart from 'chart.js/auto';

const canvas = document.getElementById("quota-definitions-chart");
const chartDataset = canvas.dataset;
const measurementUnitCode = chartDataset.measurementunitcode
const importedAmounts = JSON.parse(chartDataset.importedamounts);
const newBalances = JSON.parse(chartDataset.newbalances);
const occurrenceTimestamps = JSON.parse(chartDataset.occurrencetimestamps);
const criticalThresholds = JSON.parse(chartDataset.criticalthresholds);
const initialVolumes = JSON.parse(chartDataset.initialvolumes);

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
      {
          label: "Critical threshold",
          borderColor: "#ff0000",
          backgroundColor: "rgba(29, 112, 184, 0.1)",
          fill: false,
          data: criticalThresholds,
          // Makes the plotted dots smaller
          radius: 2
      },
      {
        label: "Initial volume",
        borderColor: "#000000",
        backgroundColor: "rgba(29, 112, 184, 0.1)",
        fill: false,
        data: initialVolumes,
        // Makes the plotted dots smaller
        radius: 2
      }
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
