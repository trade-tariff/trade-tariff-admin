import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static get targets() {
    return ['table', 'pagination', 'loading'];
  }

  static get values() {
    return {
      url: String,
      showUrl: String,
      sort: { type: String, default: 'score' },
      direction: { type: String, default: 'asc' },
      type: { type: String, default: 'commodity' },
      status: { type: String, default: '' },
      scoreCategory: { type: String, default: '' },
      page: { type: Number, default: 1 },
      q: { type: String, default: '' },
    };
  }

  connect() {
    this.fetchData();
  }

  changeType(event) {
    this.typeValue = event.currentTarget.dataset.type;
    this.pageValue = 1;
    this.fetchData();
  }

  changeStatus(event) {
    this.statusValue = event.currentTarget.dataset.status;
    this.pageValue = 1;
    this.fetchData();
  }

  changeScoreCategory(event) {
    this.scoreCategoryValue = event.currentTarget.dataset.scoreCategory;
    this.pageValue = 1;
    this.fetchData();
  }

  changeSort(event) {
    event.preventDefault();
    var column = event.currentTarget.dataset.column;

    if (this.sortValue === column) {
      this.directionValue = this.directionValue === 'asc' ? 'desc' : 'asc';
    } else {
      this.sortValue = column;
      this.directionValue = 'asc';
    }
    this.pageValue = 1;
    this.fetchData();
  }

  changePage(event) {
    event.preventDefault();
    var page = parseInt(event.currentTarget.dataset.page, 10);
    if (page > 0) {
      this.pageValue = page;
      this.fetchData();
    }
  }

  fetchData() {
    this.loadingTarget.style.display = '';
    this.tableTarget.style.opacity = '0.5';

    var params = new URLSearchParams({
      sort: this.sortValue,
      direction: this.directionValue,
      type: this.typeValue,
      page: this.pageValue,
    });

    if (this.statusValue) {
      params.set('status', this.statusValue);
    }
    if (this.scoreCategoryValue) {
      params.set('score_category', this.scoreCategoryValue);
    }
    if (this.qValue) {
      params.set('q', this.qValue);
    }

    fetch(this.urlValue + '?' + params.toString(), {
      headers: { 'Accept': 'application/json' },
    })
      .then(function(response) { return response.json(); })
      .then(this.render.bind(this))
      .catch(this.renderError.bind(this));
  }

  render(json) {
    this.loadingTarget.style.display = 'none';
    this.tableTarget.style.opacity = '1';
    this.tableTarget.innerHTML = this.buildTable(json.data);
    this.paginationTarget.innerHTML = this.buildPagination(json.pagination);
  }

  renderError() {
    this.loadingTarget.style.display = 'none';
    this.tableTarget.style.opacity = '1';
    this.tableTarget.innerHTML =
      '<div class="govuk-inset-text"><p class="govuk-body">Failed to load self-texts.</p></div>';
    this.paginationTarget.innerHTML = '';
  }

  buildTable(data) {
    if (!data || data.length === 0) {
      return '<div class="govuk-inset-text"><p class="govuk-body">No self-texts found.</p></div>';
    }

    var self = this;
    var arrow = function(col) {
      if (self.sortValue !== col) return '';
      return self.directionValue === 'asc' ? ' &#9650;' : ' &#9660;';
    };

    var sortHeader = function(col, label) {
      return '<a href="#" class="govuk-link" data-action="click->self-text-table#changeSort" data-column="' +
        col + '">' + label + arrow(col) + '</a>';
    };

    var html = '<table class="govuk-table">' +
      '<thead class="govuk-table__head"><tr class="govuk-table__row">' +
      '<th class="govuk-table__header" scope="col">' + sortHeader('goods_nomenclature_item_id', 'Commodity code') + '</th>' +
      '<th class="govuk-table__header" scope="col">' + sortHeader('score', 'Score') + '</th>' +
      '<th class="govuk-table__header" scope="col">Status</th>' +
      '<th class="govuk-table__header" scope="col">Self-text</th>' +
      '</tr></thead><tbody class="govuk-table__body">';

    data.forEach(function(st) {
      var showUrl = self.showUrlValue.replace('__ID__', st.goods_nomenclature_sid);
      var sc = self.scoreMeta(st.score);

      html += '<tr class="govuk-table__row" data-score="' + (st.score !== null && st.score !== undefined ? st.score : '') + '" data-score-category="' + sc.category + '">' +
        '<td class="govuk-table__cell"><a href="' + showUrl + '" class="govuk-link">' + self.escapeHtml(st.goods_nomenclature_item_id) + '</a></td>' +
        '<td class="govuk-table__cell">' + sc.tag + '</td>' +
        '<td class="govuk-table__cell">' + self.statusTags(st) + '</td>' +
        '<td class="govuk-table__cell">' + self.escapeHtml(st.self_text || '') + '</td>' +
        '</tr>';
    });

    html += '</tbody></table>';
    return html;
  }

  scoreMeta(score) {
    if (score === null || score === undefined) {
      return { tag: '<strong class="govuk-tag govuk-tag--grey">No score</strong>', category: '' };
    }

    var label, colour;
    if (score >= 0.85) { label = 'Amazing'; colour = 'blue'; }
    else if (score >= 0.5) { label = 'Good'; colour = 'green'; }
    else if (score >= 0.3) { label = 'Okay'; colour = 'yellow'; }
    else { label = 'Bad'; colour = 'red'; }

    return {
      tag: '<strong class="govuk-tag govuk-tag--' + colour + '">' + label + '</strong>',
      category: label.toLowerCase(),
    };
  }

  statusTags(st) {
    var tags = [];

    if (st.needs_review) {
      tags.push('<strong class="govuk-tag govuk-tag--orange">Needs review</strong>');
    }
    if (st.stale) {
      tags.push('<strong class="govuk-tag govuk-tag--pink">Stale</strong>');
    }
    if (st.manually_edited) {
      tags.push('<strong class="govuk-tag govuk-tag--purple">Edited</strong>');
    }

    return tags.length > 0 ? tags.join(' ') : '<strong class="govuk-tag govuk-tag--turquoise">Active</strong>';
  }

  buildPagination(pagination) {
    if (!pagination || pagination.total_pages <= 1) return '';

    var page = pagination.page;
    var total = pagination.total_pages;
    var html = '<nav class="govuk-pagination" role="navigation" aria-label="Pagination">';

    if (page > 1) {
      html += '<div class="govuk-pagination__prev">' +
        '<a class="govuk-link govuk-pagination__link" href="#" data-action="click->self-text-table#changePage" data-page="' + (page - 1) + '" rel="prev">' +
        '<svg class="govuk-pagination__icon govuk-pagination__icon--prev" xmlns="http://www.w3.org/2000/svg" height="13" width="15" aria-hidden="true" focusable="false" viewBox="0 0 15 13">' +
        '<path d="m6.5938-0.0078125-6.7266 6.7266 6.7441 6.4062 1.377-1.449-4.1856-3.9768h12.896v-2h-12.984l4.2931-4.293-1.414-1.414z"></path></svg>' +
        '<span class="govuk-pagination__link-title">Previous</span></a></div>';
    }

    html += '<ul class="govuk-pagination__list">';
    var pages = this.paginationRange(page, total);
    for (var i = 0; i < pages.length; i++) {
      var p = pages[i];
      if (p === '...') {
        html += '<li class="govuk-pagination__item govuk-pagination__item--ellipses">&ctdot;</li>';
      } else if (p === page) {
        html += '<li class="govuk-pagination__item govuk-pagination__item--current">' +
          '<a class="govuk-link govuk-pagination__link" href="#" aria-label="Page ' + p + '" aria-current="page">' + p + '</a></li>';
      } else {
        html += '<li class="govuk-pagination__item">' +
          '<a class="govuk-link govuk-pagination__link" href="#" data-action="click->self-text-table#changePage" data-page="' + p + '" aria-label="Page ' + p + '">' + p + '</a></li>';
      }
    }
    html += '</ul>';

    if (page < total) {
      html += '<div class="govuk-pagination__next">' +
        '<a class="govuk-link govuk-pagination__link" href="#" data-action="click->self-text-table#changePage" data-page="' + (page + 1) + '" rel="next">' +
        '<span class="govuk-pagination__link-title">Next</span>' +
        '<svg class="govuk-pagination__icon govuk-pagination__icon--next" xmlns="http://www.w3.org/2000/svg" height="13" width="15" aria-hidden="true" focusable="false" viewBox="0 0 15 13">' +
        '<path d="m8.107-0.0078125-1.4136 1.414 4.2926 4.293h-12.986v2h12.896l-4.1855 3.9766 1.377 1.4492 6.7441-6.4062-6.7246-6.7266z"></path></svg></a></div>';
    }

    html += '</nav>';
    return html;
  }

  paginationRange(current, total) {
    if (total <= 7) {
      var result = [];
      for (var i = 1; i <= total; i++) result.push(i);
      return result;
    }

    var pages = [1];
    if (current > 3) pages.push('...');

    var start = Math.max(2, current - 1);
    var end = Math.min(total - 1, current + 1);
    for (var j = start; j <= end; j++) pages.push(j);

    if (current < total - 2) pages.push('...');
    pages.push(total);
    return pages;
  }

  escapeHtml(text) {
    var div = document.createElement('div');
    div.appendChild(document.createTextNode(text));
    return div.innerHTML;
  }
}
