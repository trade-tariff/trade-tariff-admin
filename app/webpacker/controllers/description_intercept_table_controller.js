import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static get targets() {
    return ['table', 'pagination', 'loading', 'searchInput'];
  }

  static get values() {
    return {
      url: String,
      showUrl: String,
      page: { type: Number, default: 1 },
      q: { type: String, default: '' },
      filtering: { type: Boolean, default: false },
      escalates: { type: Boolean, default: false },
      guidance: { type: Boolean, default: false },
      excluded: { type: Boolean, default: false },
    };
  }

  connect() {
    this.fetchData();
  }

  search() {
    this.qValue = this.searchInputTarget.value.trim();
    this.pageValue = 1;
    this.fetchData();
  }

  debouncedSearch() {
    clearTimeout(this.searchTimeout);
    this.searchTimeout = setTimeout(() => this.search(), 250);
  }

  toggleFiltering(event) {
    this.filteringValue = event.currentTarget.checked;
    this.pageValue = 1;
    this.fetchData();
  }

  toggleEscalates(event) {
    this.escalatesValue = event.currentTarget.checked;
    this.pageValue = 1;
    this.fetchData();
  }

  toggleGuidance(event) {
    this.guidanceValue = event.currentTarget.checked;
    this.pageValue = 1;
    this.fetchData();
  }

  toggleExcluded(event) {
    this.excludedValue = event.currentTarget.checked;
    this.pageValue = 1;
    this.fetchData();
  }

  changePage(event) {
    event.preventDefault();
    const page = parseInt(event.currentTarget.dataset.page, 10);

    if (page > 0) {
      this.pageValue = page;
      this.fetchData();
    }
  }

  buildPagination(pagination) {
    if (!pagination || pagination.total_pages <= 1) return '';

    const page = pagination.page;
    const total = pagination.total_pages;
    let html = '<nav class="govuk-pagination" role="navigation" aria-label="Pagination">';

    if (page > 1) {
      html += '<div class="govuk-pagination__prev">' +
        '<a class="govuk-link govuk-pagination__link" href="#" data-action="click->description-intercept-table#changePage" data-page="' + (page - 1) + '" rel="prev">' +
        '<svg class="govuk-pagination__icon govuk-pagination__icon--prev" xmlns="http://www.w3.org/2000/svg" height="13" width="15" aria-hidden="true" focusable="false" viewBox="0 0 15 13">' +
        '<path d="m6.5938-0.0078125-6.7266 6.7266 6.7441 6.4062 1.377-1.449-4.1856-3.9768h12.896v-2h-12.984l4.2931-4.293-1.414-1.414z"></path></svg>' +
        '<span class="govuk-pagination__link-title">Previous</span></a></div>';
    }

    html += '<ul class="govuk-pagination__list">';
    this.paginationRange(page, total).forEach((currentPage) => {
      if (currentPage === '...') {
        html += '<li class="govuk-pagination__item govuk-pagination__item--ellipses">&ctdot;</li>';
      } else if (currentPage === page) {
        html += '<li class="govuk-pagination__item govuk-pagination__item--current">' +
          '<a class="govuk-link govuk-pagination__link" href="#" aria-label="Page ' + currentPage + '" aria-current="page">' + currentPage + '</a></li>';
      } else {
        html += '<li class="govuk-pagination__item">' +
          '<a class="govuk-link govuk-pagination__link" href="#" data-action="click->description-intercept-table#changePage" data-page="' + currentPage + '" aria-label="Page ' + currentPage + '">' + currentPage + '</a></li>';
      }
    });
    html += '</ul>';

    if (page < total) {
      html += '<div class="govuk-pagination__next">' +
        '<a class="govuk-link govuk-pagination__link" href="#" data-action="click->description-intercept-table#changePage" data-page="' + (page + 1) + '" rel="next">' +
        '<span class="govuk-pagination__link-title">Next</span>' +
        '<svg class="govuk-pagination__icon govuk-pagination__icon--next" xmlns="http://www.w3.org/2000/svg" height="13" width="15" aria-hidden="true" focusable="false" viewBox="0 0 15 13">' +
        '<path d="m8.107-0.0078125-1.4136 1.414 4.2926 4.293h-12.986v2h12.896l-4.1855 3.9766 1.377 1.4492 6.7441-6.4062-6.7246-6.7266z"></path></svg></a></div>';
    }

    html += '</nav>';
    return html;
  }

  paginationRange(current, total) {
    if (total <= 7) {
      return Array.from({ length: total }, (_, index) => index + 1);
    }

    const pages = [1];

    if (current > 3) pages.push('...');

    const start = Math.max(2, current - 1);
    const end = Math.min(total - 1, current + 1);

    for (let page = start; page <= end; page += 1) {
      pages.push(page);
    }

    if (current < total - 2) pages.push('...');

    pages.push(total);
    return pages;
  }

  render(json) {
    this.loadingTarget.style.display = 'none';
    this.tableTarget.innerHTML = this.buildTable(json.data || []);
    this.paginationTarget.innerHTML = this.buildPagination(json.pagination);
  }

  fetchData() {
    this.loadingTarget.style.display = '';
    const params = new URLSearchParams();
    params.set('page', this.pageValue);
    if (this.qValue) params.set('q', this.qValue);
    if (this.filteringValue) params.set('filtering', 'true');
    if (this.escalatesValue) params.set('escalates', 'true');
    if (this.guidanceValue) params.set('guidance', 'true');
    if (this.excludedValue) params.set('excluded', 'true');

    fetch(this.urlValue + '?' + params.toString(), { headers: { Accept: 'application/json' } })
      .then((response) => response.json())
      .then((json) => this.render(json))
      .catch(() => this.renderError());
  }

  renderError() {
    this.loadingTarget.style.display = 'none';
    this.tableTarget.innerHTML = '<div class="govuk-inset-text"><p class="govuk-body">Failed to load description intercepts.</p></div>';
    this.paginationTarget.innerHTML = '';
  }

  buildTable(data) {
    if (!data.length) {
      return '<div class="govuk-inset-text"><p class="govuk-body">No description intercepts found.</p></div>';
    }

    let html = '<table class="govuk-table description-intercept-table"><thead class="govuk-table__head"><tr class="govuk-table__row">' +
      '<th class="govuk-table__header description-intercept-table__term" scope="col">Term</th>' +
      '<th class="govuk-table__header" scope="col">Behaviour</th>' +
      '<th class="govuk-table__header" scope="col">Guidance</th>' +
      '<th class="govuk-table__header" scope="col">Escalation</th>' +
      '<th class="govuk-table__header" scope="col">Created</th>' +
      '</tr></thead><tbody class="govuk-table__body">';

    data.forEach((intercept) => {
      const showUrl = this.showUrlValue.replace('__ID__', intercept.id ? intercept.id : '');
      html += '<tr class="govuk-table__row">' +
        '<td class="govuk-table__cell description-intercept-table__term"><a class="govuk-link" href="' + this.escapeAttribute(showUrl) + '">' + this.escapeHtml(intercept.term) + '</a></td>' +
        '<td class="govuk-table__cell">' + this.renderBehaviour(intercept) + '</td>' +
        '<td class="govuk-table__cell">' + this.renderGuidance(intercept) + '</td>' +
        '<td class="govuk-table__cell">' + this.renderEscalation(intercept) + '</td>' +
        '<td class="govuk-table__cell">' + this.escapeHtml(intercept.created_at || '-') + '</td>' +
        '</tr>';
    });

    html += '</tbody></table>';
    return html;
  }

  renderBehaviour(intercept) {
    if (intercept.excluded) {
      return '<strong class="govuk-tag govuk-tag--red">Excluded</strong>';
    }

    if (intercept.filtering) {
      return '<strong class="govuk-tag govuk-tag--turquoise">Filtered</strong>';
    }

    return '<strong class="govuk-tag govuk-tag--grey">None</strong>';
  }

  renderGuidance(intercept) {
    if (!intercept.guidance_present) {
      return '<strong class="govuk-tag govuk-tag--grey">None</strong>';
    }

    return '<span>' + this.escapeHtml(intercept.guidance || '') + '</span>';
  }

  renderEscalation(intercept) {
    if (intercept.escalates) {
      return '<strong class="govuk-tag govuk-tag--blue">Enabled</strong>';
    }

    return '<strong class="govuk-tag govuk-tag--grey">Not enabled</strong>';
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.appendChild(document.createTextNode(text || ''));
    return div.innerHTML;
  }

  escapeAttribute(text) {
    return this.escapeHtml(text).replace(/"/g, '&quot;');
  }
}
