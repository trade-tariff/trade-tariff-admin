// Shape copied from workbook_controller.js (search_export_workbooks) — same polling cadence, same
// {pending, html} JSON contract, same "taking longer than expected" fallback.
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['status'];
  static values = { url: String, pending: Boolean };

  connect() {
    if (!this.pendingValue) return;

    this.requestController = new AbortController();
    this.deadline = setTimeout(() => this.pause('This is taking longer than expected. Check the run status again.'), 180000);
    this.schedule();
  }

  disconnect() {
    this.stop();
  }

  schedule() {
    this.timer = setTimeout(() => this.poll(), 2000);
  }

  async poll() {
    const controller = this.requestController;
    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: 'application/json' },
        credentials: 'same-origin',
        cache: 'no-store',
        signal: controller.signal,
      });
      if (!response.ok || response.redirected) throw new Error('Status unavailable');
      const result = await response.json();
      if (this.requestController !== controller) return;
      if (typeof result.pending !== 'boolean' || typeof result.html !== 'string') throw new Error('Invalid status');

      if (result.pending) {
        this.statusTarget.innerHTML = result.html;
        this.schedule();
      } else {
        this.stop();
        this.statusTarget.innerHTML = result.html;
      }
    } catch (error) {
      if (this.requestController === controller) {
        this.pause('Could not check the run status. Try checking again.');
      }
    }
  }

  pause(message) {
    this.stop();
    const messageEl = this.statusTarget.querySelector('[data-run-tracking-target="message"]');
    if (messageEl) messageEl.textContent = message;
  }

  stop() {
    clearTimeout(this.timer);
    clearTimeout(this.deadline);
    this.requestController?.abort();
    this.requestController = null;
  }
}
