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

    const setName = experimentData.gold_query_set_name || 'No gold query set on this experiment';
    const setLabel = experimentData.gold_query_set_item_count != null
      ? `${setName} (${experimentData.gold_query_set_item_count} items)`
      : setName;

    // Every key the operator could possibly see, in first-seen order (baseline's own keys first,
    // then any key only an experiment or typed override introduces, e.g. simulator_model — which
    // has no baseline value at all; see BaselineProvider's own comment on why). A key resolved
    // purely from the baseline shows the word "default", not that baseline's own value — this run
    // sends nothing for it, so showing e.g. "false" would look like something the operator chose,
    // when really production's own setting could be different (or change) by the time this run
    // actually executes.
    const keys = [...new Set([...Object.keys(this.baselineValue), ...Object.keys(experimentOverrides), ...Object.keys(typedOverrides)])];
    const rows = keys.map((key) => {
      if (key in typedOverrides) return `${key}: ${typedOverrides[key]}`;
      if (key in experimentOverrides) return `${key}: ${experimentOverrides[key]}`;
      return `${key}: default`;
    });
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
