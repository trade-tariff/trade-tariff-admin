import autosize from "autosize/dist/autosize";
document.addEventListener("DOMContentLoaded", function() {
  var Previewer = {
    preview: function(content, output) {
      fetch("/govspeak", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.fetchCSRFToken(),
        },
        body: JSON.stringify({ govspeak: content.value }),
      })
        .then(function(response) {
          return response.json();
        })
        .then(function(data) {
          output.innerHTML = data.govspeak;
        })
        .catch(function(error) {
          console.error("Error:", error);
        });
    },
    fetchCSRFToken: function() {
      var csrfToken = document.querySelector('meta[name="csrf-token"]');
      return csrfToken ? csrfToken.getAttribute("content") : null;
    }
  };

  document.querySelectorAll("[data-preview]").forEach(function(element) {
    var source_field = document.querySelector(element.dataset.previewFor);
    var render_area = element;

    source_field.addEventListener("input", function() {
      Previewer.preview(source_field, render_area);
    });
  });

  document.querySelectorAll("textarea.govuk-textarea").forEach(function(element) {
    autosize(element);
  });

});
