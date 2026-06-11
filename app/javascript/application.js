import accessibleAutocomplete from 'accessible-autocomplete';
import "controllers";
import { initAll } from 'govuk-frontend';

initAll();

window.GOVUK = {};
window.GOVUK.accessibleAutocomplete = accessibleAutocomplete;

import "src/markdown-preview";
import "src/quota-definition-chart";
