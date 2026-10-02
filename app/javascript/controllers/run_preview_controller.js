import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['experimentSelect', 'goldQuerySetSelect', 'overrideField', 'preview'];
  static values = { baseline: Object, experiments: Object };

  connect() {
    this.render();
  }

  render() {
    const experimentId = this.experimentSelectTarget.value;
    if (!experimentId) {
      this.previewTarget.innerHTML = '<h2 class="govuk-heading-s">Preview</h2><p class="govuk-body">Choose an experiment to see what this run will use.</p>';
      return;
    }

    const experimentOverrides = this.experimentsValue[experimentId] || {};
    const typedOverrides = this.currentTypedOverrides();
    const effective = { ...this.baselineValue, ...experimentOverrides, ...typedOverrides };

    const setOption = this.goldQuerySetSelectTarget.selectedOptions[0];
    const setLabel = setOption && setOption.value ? setOption.textContent : 'No gold query set chosen yet';

    const rows = Object.entries(effective).map(([key, value]) => `<li>${key}: ${value}</li>`).join('');
    this.previewTarget.innerHTML = `<h2 class="govuk-heading-s">Preview</h2><p class="govuk-body">${setLabel}</p><ul class="govuk-list">${rows}</ul>`;
  }

  currentTypedOverrides() {
    const overrides = {};
    this.overrideFieldTargets.forEach((field) => {
      const key = field.dataset.overrideKey;
      if (field.type === 'radio') {
        if (field.checked && field.value !== '') overrides[key] = field.value;
      } else if (field.value !== '') {
        overrides[key] = field.value;
      }
    });
    return overrides;
  }
}
