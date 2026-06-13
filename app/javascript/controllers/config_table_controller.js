import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static get targets() {
    return ['row', 'pagination', 'count'];
  }

  static get values() {
    return {
      page: { type: Number, default: 1 },
      perPage: { type: Number, default: 15 },
      configType: { type: String, default: '' },
      query: { type: String, default: '' },
    };
  }

  connect() {
    this.filter();
  }

  changeType(event) {
    this.configTypeValue = event.currentTarget.dataset.configType;
    this.pageValue = 1;
    this.filter();
  }

  search(event) {
    this.queryValue = event.currentTarget.value.toLowerCase().trim();
    this.pageValue = 1;
    this.filter();
  }

  changePage(event) {
    event.preventDefault();
    var page = parseInt(event.currentTarget.dataset.page, 10);
    if (page > 0) {
      this.pageValue = page;
      this.filter();
    }
  }

  filter() {
    var configType = this.configTypeValue;
    var query = this.queryValue;
    var visible = [];

    this.rowTargets.forEach(function(row) {
      var typeMatch = !configType || row.dataset.configType === configType;
      var searchMatch = !query || row.dataset.searchable.indexOf(query) !== -1;

      if (typeMatch && searchMatch) {
        visible.push(row);
      }

      row.style.display = 'none';
    });

    this.paginate(visible);
  }

  paginate(visibleRows) {
    var total = visibleRows.length;
    var perPage = this.perPageValue;
    var totalPages = Math.max(1, Math.ceil(total / perPage));
    var page = Math.min(this.pageValue, totalPages);
    var start = (page - 1) * perPage;
    var end = start + perPage;

    for (var i = start; i < end && i < visibleRows.length; i++) {
      visibleRows[i].style.display = '';
    }

    this.countTarget.textContent = 'Showing ' + Math.min(perPage, total - start) + ' of ' + total + ' configurations';
    this.paginationTarget.innerHTML = this.buildPagination(page, totalPages);
  }

  buildPagination(page, totalPages) {
    if (totalPages <= 1) return '';

    var html = '<nav class="govuk-pagination" role="navigation" aria-label="Pagination">';

    if (page > 1) {
      html += '<div class="govuk-pagination__prev">' +
        '<a class="govuk-link govuk-pagination__link" href="#" data-action="click->config-table#changePage" data-page="' + (page - 1) + '" rel="prev">' +
        '<svg class="govuk-pagination__icon govuk-pagination__icon--prev" xmlns="http://www.w3.org/2000/svg" height="13" width="15" aria-hidden="true" focusable="false" viewBox="0 0 15 13">' +
        '<path d="m6.5938-0.0078125-6.7266 6.7266 6.7441 6.4062 1.377-1.449-4.1856-3.9768h12.896v-2h-12.984l4.2931-4.293-1.414-1.414z"></path></svg>' +
        '<span class="govuk-pagination__link-title">Previous</span></a></div>';
    }

    html += '<ul class="govuk-pagination__list">';
    var pages = this.paginationRange(page, totalPages);
    for (var i = 0; i < pages.length; i++) {
      var p = pages[i];
      if (p === '...') {
        html += '<li class="govuk-pagination__item govuk-pagination__item--ellipses">&ctdot;</li>';
      } else if (p === page) {
        html += '<li class="govuk-pagination__item govuk-pagination__item--current">' +
          '<a class="govuk-link govuk-pagination__link" href="#" aria-label="Page ' + p + '" aria-current="page">' + p + '</a></li>';
      } else {
        html += '<li class="govuk-pagination__item">' +
          '<a class="govuk-link govuk-pagination__link" href="#" data-action="click->config-table#changePage" data-page="' + p + '" aria-label="Page ' + p + '">' + p + '</a></li>';
      }
    }
    html += '</ul>';

    if (page < totalPages) {
      html += '<div class="govuk-pagination__next">' +
        '<a class="govuk-link govuk-pagination__link" href="#" data-action="click->config-table#changePage" data-page="' + (page + 1) + '" rel="next">' +
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
}
