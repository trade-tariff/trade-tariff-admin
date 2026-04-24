// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
require.context('govuk-frontend/dist/govuk/assets');

import './application.scss';
import Rails from 'rails-ujs';
import { initAll } from 'govuk-frontend';

import { Application } from '@hotwired/stimulus';
import GeneratedContentTableController from '../controllers/generated_content_table_controller';
import ScoredTagListController from '../controllers/scored_tag_list_controller';
import ConfigTableController from '../controllers/config_table_controller';
import ConfigFormController from '../controllers/config_form_controller';
import DescriptionInterceptTableController from '../controllers/description_intercept_table_controller';
import DescriptionInterceptFormController from '../controllers/description_intercept_form_controller';

import '../javascripts/markdown-preview';

Rails.start();
initAll();

const application = Application.start();
application.register('generated-content-table', GeneratedContentTableController);
application.register('scored-tag-list', ScoredTagListController);
application.register('config-table', ConfigTableController);
application.register('config-form', ConfigFormController);
application.register('description-intercept-table', DescriptionInterceptTableController);
application.register('description-intercept-form', DescriptionInterceptFormController);
