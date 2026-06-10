# Pin npm packages by running ./bin/importmap

pin "application"

pin_all_from "app/javascript/src", to: "src"

pin_all_from "app/javascript/controllers", under: "controllers"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
