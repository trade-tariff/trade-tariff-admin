# Pin npm packages by running ./bin/importmap

pin "application"

pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin "govuk-frontend" # @6.2.0
pin "accessible-autocomplete" # @3.0.1
pin "chart.js" # @4.5.1 jsdelivr +esm
pin "@kurkle/color", to: "@kurkle--color.js" # @0.4.0

pin_all_from "app/javascript/src", to: "src"
pin_all_from "app/javascript/controllers", under: "controllers"
