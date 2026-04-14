import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static get targets() {
    return ['hiddenField', 'nestedSelect', 'nestedSubOptionsContainer'];
  }

  connect() {
    if (this.hasNestedSelectTarget && this.hasNestedSubOptionsContainerTarget) {
      this.rebuildNestedSubOptions();
    }
  }

  updateOption(event) {
    var data = this.parseHiddenValue();
    data.selected = event.currentTarget.value;
    this.writeHiddenValue(data);
  }

  updateMultiOption(event) {
    var data = this.parseHiddenValue();
    var selected = Array.isArray(data.selected) ? data.selected.slice() : [];
    var value = event.currentTarget.value;

    if (event.currentTarget.checked) {
      if (selected.indexOf(value) === -1) {
        selected.push(value);
      }
    } else {
      selected = selected.filter(function(item) { return item !== value; });
    }

    data.selected = selected;
    this.writeHiddenValue(data);
  }

  updateNestedOption() {
    this.rebuildNestedSubOptions();
  }

  syncNestedSubValues() {
    this.writeHiddenValue(this.currentNestedValue());
  }

  rebuildNestedSubOptions() {
    var container = this.nestedSubOptionsContainerTarget;
    var selectedOption = this.nestedSelectTarget.options[this.nestedSelectTarget.selectedIndex];

    container.innerHTML = '';

    if (!selectedOption || !selectedOption.value) {
      this.writeHiddenValue(this.currentNestedValue());
      return;
    }

    var currentData = this.parseHiddenValue();
    var currentSubValues = this.normalizeSubValues(currentData.sub_values);
    var subOptions = this.parseJson(selectedOption.dataset.subOptions);

    Object.keys(subOptions).forEach(function(key) {
      var levels = subOptions[key];
      if (!Array.isArray(levels) || levels.length === 0) return;

      var group = document.createElement('div');
      group.className = 'govuk-form-group';

      var label = document.createElement('label');
      label.className = 'govuk-label';
      label.setAttribute('for', 'nested-sub-' + key);
      label.textContent = key.replace(/_/g, ' ').replace(/\b\w/g, function(char) { return char.toUpperCase(); });
      group.appendChild(label);

      var select = document.createElement('select');
      select.className = 'govuk-select';
      select.id = 'nested-sub-' + key;
      select.setAttribute('data-sub-key', key);
      select.setAttribute('data-action', 'change->config-form#syncNestedSubValues');

      var noneOption = document.createElement('option');
      noneOption.value = '';
      noneOption.textContent = 'None';
      select.appendChild(noneOption);

      levels.forEach(function(level) {
        if (level === 'none') return;

        var option = document.createElement('option');
        option.value = level;
        option.textContent = level.charAt(0).toUpperCase() + level.slice(1);
        select.appendChild(option);
      });

      select.value = currentSubValues[key] || '';
      group.appendChild(select);
      container.appendChild(group);
    });

    this.writeHiddenValue(this.currentNestedValue());
  }

  currentNestedValue() {
    var data = this.parseHiddenValue();
    data.selected = this.nestedSelectTarget.value;
    data.sub_values = this.collectNestedSubValues();
    return data;
  }

  collectNestedSubValues() {
    var subValues = {};

    this.nestedSubOptionsContainerTarget.querySelectorAll('select[data-sub-key]').forEach(function(select) {
      subValues[select.dataset.subKey] = select.value || null;
    });

    return subValues;
  }

  normalizeSubValues(subValues) {
    return subValues && typeof subValues === 'object' ? subValues : {};
  }

  parseHiddenValue() {
    return this.parseJson(this.hiddenFieldTarget.value);
  }

  writeHiddenValue(data) {
    this.hiddenFieldTarget.value = JSON.stringify(data);
  }

  parseJson(value) {
    try {
      return JSON.parse(value || '{}');
    } catch (_error) {
      return {};
    }
  }
}
