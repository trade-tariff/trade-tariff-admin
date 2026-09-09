import accessibleAutocomplete from 'accessible-autocomplete';
import "controllers";
import { initAll } from 'govuk-frontend';
import "@hotwired/turbo-rails"

initAll();

window.GOVUK = {};
window.GOVUK.accessibleAutocomplete = accessibleAutocomplete;

import "markdown-preview";
import "quota-definition-chart";
import "search-analytics-dashboard";
