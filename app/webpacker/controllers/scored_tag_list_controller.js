import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static get targets() {
    return ['tags', 'input', 'hidden'];
  }

  static get values() {
    return {
      terms: { type: Array, default: [] },
      scores: { type: Array, default: [] },
      scored: { type: Boolean, default: false },
    };
  }

  connect() {
    this.render();
  }

  add(event) {
    if (event.type === 'keydown' && event.key !== 'Enter') return;
    event.preventDefault();

    var value = this.inputTarget.value.trim();
    if (value === '') return;

    this.termsValue = this.termsValue.concat([value]);
    this.scoresValue = this.scoresValue.concat([null]);
    this.inputTarget.value = '';
    this.render();
  }

  remove(event) {
    var index = parseInt(event.currentTarget.dataset.index, 10);
    var terms = this.termsValue.slice();
    var scores = this.scoresValue.slice();
    terms.splice(index, 1);
    scores.splice(index, 1);
    this.termsValue = terms;
    this.scoresValue = scores;
    this.render();
  }

  render() {
    var self = this;
    var html = '';

    this.termsValue.forEach(function(term, i) {
      var score = self.scoresValue[i];
      var colour = self.tagColour(score);
      var scoreHtml = '';

      if (self.scoredValue) {
        var display = (score !== null && score !== undefined) ? score.toFixed(2) : '?';
        scoreHtml = ' <strong class="govuk-tag govuk-tag--' + colour + ' scored-tag-pill__score">' + display + '</strong>';
      }

      html += '<span class="scored-tag-pill">' +
        self.escapeHtml(term) + scoreHtml +
        ' <button type="button" class="scored-tag-pill__remove" data-action="click->scored-tag-list#remove" data-index="' + i + '" ' +
        'aria-label="Remove ' + self.escapeHtml(term) + '">&times;</button>' +
        '</span>';
    });

    this.tagsTarget.innerHTML = html;
    this.hiddenTarget.value = this.termsValue.join('\n');
  }

  tagColour(score) {
    if (score === null || score === undefined) return 'grey';
    if (score >= 0.85) return 'blue';
    if (score >= 0.5) return 'green';
    if (score >= 0.3) return 'yellow';
    return 'red';
  }

  escapeHtml(text) {
    var div = document.createElement('div');
    div.appendChild(document.createTextNode(text));
    return div.innerHTML;
  }
}
