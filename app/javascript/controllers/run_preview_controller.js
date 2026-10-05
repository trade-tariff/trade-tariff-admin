import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['experimentSelect', 'overrideField', 'preview'];
  static values = { baseline: Object, experiments: Object };

  connect() {
    this.render();
  }

  render() {
    const experimentId = this.experimentSelectTarget.value;
    if (!experimentId) {
      this.renderPreview('Choose an experiment to see what this run will use.', []);
      return;
    }

    const experimentData = this.experimentsValue[experimentId] || {};
    const experimentOverrides = experimentData.overrides || {};
    const typedOverrides = this.currentTypedOverrides();
    const effective = { ...this.baselineValue, ...experimentOverrides, ...typedOverrides };

    const setName = experimentData.gold_query_set_name || 'No gold query set on this experiment';
    const setLabel = experimentData.gold_query_set_item_count != null
      ? `${setName} (${experimentData.gold_query_set_item_count} items)`
      : setName;

    const rows = Object.entries(effective).map(([key, value]) => `${key}: ${value}`);
    this.renderPreview(setLabel, rows);
  }

  // Built from DOM nodes via textContent, never an HTML string — setLabel (a gold query set's
  // name) and each row (an experiment's own saved overrides) are operator-entered free text,
  // persisted and shown to every other technical operator who opens this form. Interpolating
  // either into innerHTML would let one operator's saved text run as script in another's browser.
  renderPreview(setLabel, rows) {
    const heading = document.createElement('h2');
    heading.className = 'govuk-heading-s';
    heading.textContent = 'Preview';

    const summary = document.createElement('p');
    summary.className = 'govuk-body';
    summary.textContent = setLabel;

    const children = [heading, summary];
    if (rows.length) {
      const list = document.createElement('ul');
      list.className = 'govuk-list';
      rows.forEach((row) => {
        const item = document.createElement('li');
        item.textContent = row;
        list.appendChild(item);
      });
      children.push(list);
    }

    this.previewTarget.replaceChildren(...children);
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
