import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static get targets() {
    return ['content', 'preview'];
  }

  static get values() {
    return { url: String };
  }

  update() {
    const csrfMeta = document.querySelector('meta[name="csrf-token"]');
    const csrfToken = csrfMeta ? csrfMeta.getAttribute('content') : null;
    fetch(this.urlValue, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
      },
      body: JSON.stringify({ content: this.contentTarget.value }),
    })
      .then((response) => response.json())
      .then((data) => { this.previewTarget.innerHTML = data.html || ''; }) // server-sanitised HTML
      .catch((error) => console.error('Preview error:', error));
  }
}
