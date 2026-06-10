# Pin npm packages by running ./bin/importmap

pin "application"

pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin "govuk-frontend" # @6.2.0
pin "accessible-autocomplete" # @3.0.1

pin_all_from "app/javascript/src", under: "src", to: "src"
pin_all_from "app/javascript/controllers", under: "controllers"

pin "markdown-preview"
