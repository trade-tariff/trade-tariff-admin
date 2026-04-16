import { Controller } from '@hotwired/stimulus';
import accessibleAutocomplete from 'accessible-autocomplete';


export default class extends Controller {
  static get targets() {
    return [
      "messageInput",
      "guidanceFields",
      "guidanceLevelInput",
      "guidanceLocationInput",
      "excludedInput",
      "filteringToggle",
      "filteringFields",
      "filteringHint",
      "autocompleteContainer",
      "selectedShortCodes",
    ];
  }

  static get values() {
    return {
      autocompleteUrl: String,
    };
  }

  connect() {
    this.initializeAutocomplete();
    this.toggleGuidance();
    this.toggleFiltering();
  }

  toggleGuidance() {
    const visible = this.messageInputTarget.value.trim().length > 0;
    this.guidanceFieldsTarget.style.display = visible ? "" : "none";
    this.guidanceLevelInputTarget.disabled = !visible;
    this.guidanceLocationInputTarget.disabled = !visible;

    if (!visible) {
      this.guidanceLevelInputTarget.value = "";
      this.guidanceLocationInputTarget.value = "";
    }
  }

  toggleExcluded() {
    this.toggleFiltering();
  }

  toggleFiltering() {
    const excluded = this.excludedInputTarget.checked;

    if (excluded) {
      this.filteringToggleTarget.checked = false;
    }

    this.filteringToggleTarget.disabled = excluded;
    this.filteringHintTarget.style.display = excluded ? '' : 'none';

    const visible = this.filteringToggleTarget.checked && !excluded;
    this.filteringFieldsTarget.style.display = visible ? '' : 'none';
    this.toggleSelectedShortCodeInputs(visible);
    this.toggleAutocompleteAvailability();
  }

  initializeAutocomplete() {
    if (!this.hasAutocompleteContainerTarget) {
      return;
    }

    accessibleAutocomplete({
      element: this.autocompleteContainerTarget,
      id: 'description-intercept-filter-prefixes-field-error',
      name: 'description_intercept_filter_prefixes',
      minLength: 2,
      confirmOnBlur: false,
      autoselect: false,
      showAllValues: false,
      placeholder: 'Search by short code or description',
      dropdownArrow: () => '<span class="autocomplete__arrow"></span>',
      source: this.fetchSuggestions.bind(this),
      templates: {
        inputValue: (result) => (result ? result.label : ''),
        suggestion: (result) => result ? result.label : '',
      },
      onConfirm: (result) => {
        if (result && result.goods_nomenclature_item_id) {
          this.addShortCode(result);
          window.requestAnimationFrame(() => this.clearAutocompleteInput());
        }
      },
    });

    this.autocompleteInput = this.autocompleteContainerTarget.querySelector('input.autocomplete__input');
    if (this.autocompleteInput) {
      const describedBy = ['description-intercept-filter-prefixes-hint'];
      if (this.hasFilterPrefixesError()) {
        describedBy.unshift('description-intercept-filter-prefixes-error');
        this.autocompleteInput.setAttribute('aria-invalid', 'true');
      }

      this.autocompleteInput.setAttribute('aria-describedby', describedBy.join(' '));
    }
    this.toggleAutocompleteAvailability();
  }

  hasFilterPrefixesError() {
    return document.getElementById('description-intercept-filter-prefixes-error') !== null;
  }

  fetchSuggestions(query, populateResults) {
    if (!this.autocompleteInput || this.autocompleteInput.disabled) {
      populateResults([]);
      return;
    }

    const trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      populateResults([]);
      return;
    }

    fetch(this.autocompleteUrlValue + '?q=' + encodeURIComponent(trimmedQuery), { headers: { Accept: 'application/json' } })
      .then((response) => response.json())
      .then((json) => populateResults(json))
      .catch(() => populateResults([]));
  }

  addShortCode(result) {
    const code = result.goods_nomenclature_item_id;
    if (this.selectedCodes().includes(code)) return;

    this.selectedShortCodesTarget.appendChild(this.buildSelectedShortCode(code, result.truncated_description));
  }

  removeShortCode(event) {
    event.preventDefault();
    event.currentTarget.closest("[data-short-code-item]").remove();
  }

  toggleAutocompleteAvailability() {
    if (!this.autocompleteInput) {
      return;
    }

    const enabled = this.filteringToggleTarget.checked && !this.excludedInputTarget.checked;
    this.autocompleteInput.disabled = !enabled;

    if (!enabled) {
      this.clearAutocompleteInput();
    }
  }

  clearAutocompleteInput() {
    if (!this.hasAutocompleteContainerTarget) {
      return;
    }

    this.autocompleteContainerTarget.querySelectorAll('input').forEach((input) => {
      input.value = '';
      input.dispatchEvent(new Event('input', { bubbles: true }));
    });

    if (this.autocompleteInput) {
      this.autocompleteInput.focus();
    }
  }

  selectedCodes() {
    return Array.from(this.selectedShortCodeInputs()).map((input) => input.value);
  }

  selectedShortCodeInputs() {
    return this.selectedShortCodesTarget.querySelectorAll('input[type="hidden"]');
  }

  toggleSelectedShortCodeInputs(enabled) {
    this.selectedShortCodeInputs().forEach((input) => {
      input.disabled = !enabled;
    });
  }

  buildSelectedShortCode(code, description = null) {
    const wrapper = document.createElement("div");
    wrapper.setAttribute("data-short-code-item", "true");
    wrapper.className = "description-intercept-short-code-pill";

    const content = document.createElement("div");
    content.className = "description-intercept-short-code-pill__content";

    const tag = document.createElement("strong");
    tag.className = "govuk-tag govuk-tag--grey";
    tag.textContent = code;

    content.appendChild(tag);

    if (description) {
      const descriptionNode = document.createElement("span");
      descriptionNode.className = "description-intercept-short-code-pill__description";
      descriptionNode.textContent = description;
      content.appendChild(descriptionNode);
    }

    const removeButton = document.createElement("button");
    removeButton.type = "button";
    removeButton.className = "description-intercept-short-code-pill__remove";
    removeButton.textContent = "Remove";
    removeButton.setAttribute("aria-label", "Remove " + code);
    removeButton.addEventListener("click", (event) => this.removeShortCode(event));

    const input = document.createElement("input");
    input.type = "hidden";
    input.name = "description_intercept[filter_prefixes][]";
    input.value = code;

    wrapper.appendChild(content);
    wrapper.appendChild(removeButton);
    wrapper.appendChild(input);

    return wrapper;
  }
}
