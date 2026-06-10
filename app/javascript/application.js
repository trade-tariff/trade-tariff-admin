import { accessibleAutocomplete } from 'accessible-autocomplete';
import { initAll } from 'govuk-frontend';

initAll();

window.GOVUK = {};
window.GOVUK.accessibleAutocomplete = accessibleAutocomplete;

import "markdown-preview";
import "controllers";
