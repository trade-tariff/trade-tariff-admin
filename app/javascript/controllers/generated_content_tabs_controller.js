import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  loadSelectedTab(event) {
    const tab = event.target.closest('.govuk-tabs__tab');
    if (!tab || !this.element.contains(tab)) return;

    const panelId = tab.hash.slice(1);
    if (!panelId) return;

    window.setTimeout(() => {
      const panel = document.getElementById(panelId);
      if (!panel || !this.element.contains(panel)) return;

      const tableElement = this.tableElementForPanel(panel);
      if (!tableElement) return;

      const controller = this.application.getControllerForElementAndIdentifier(
        tableElement,
        'generated-content-table',
      );
      if (controller) controller.loadOnce();
    }, 0);
  }

  tableElementForPanel(panel) {
    if (panel.matches('[data-controller~="generated-content-table"]')) return panel;

    return panel.querySelector('[data-controller~="generated-content-table"]');
  }
}
