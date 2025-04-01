require 'routing_filter/service_path_prefix_handler'

Rails.application.routes.draw do
  filter :service_path_prefix_handler
  default_url_options(host: TradeTariffAdmin.host)

  namespace :notes, module: :notes do
    resources :sections, only: %i[index show] do
      scope module: 'sections' do
        resource :section_note
        resources :chapters, only: [:index]
      end
    end

    resources :chapters, only: %i[index show] do
      scope module: 'chapters' do
        resource :chapter_note
        resources :headings, only: [:index]
      end
    end
  end

  namespace :references, path: 'search_references' do
    resources :sections, only: %i[index] do
      scope module: 'sections' do
        resources :chapters, only: [:index]
      end
    end

    resources :chapters, only: %i[index show] do
      scope module: 'chapters' do
        resources :headings, only: [:index]
        resources :search_references
      end
    end

    resources :headings do
      scope module: 'headings' do
        resources :commodities, only: [:index]
        resources :search_references
      end
    end

    resources :commodities do
      scope module: 'commodities' do
        resources :search_references
      end
    end
  end

  namespace :green_lanes, path: 'green_lanes' do
    resources :category_assessments, only: %i[index new create edit update destroy] do
      member do
        post 'add_exemption'
        delete 'remove_exemption'
        post 'add_measure'
      end
    end
    resources :exempting_overrides, only: %i[index]
    resources :exempting_certificate_overrides, only: %i[new create destroy]
    resources :exempting_additional_code_overrides, only: %i[new create destroy]
    resources :exemptions, only: %i[index new create edit update destroy]
    resources :measures, only: %i[index destroy]
    resources :update_notifications, only: %i[index edit update]
  end

  resources :tariff_updates, only: %i[index show] do
    collection do
      post '/download', to: 'tariff_updates#download'
      post '/apply_and_clear_cache', to: 'tariff_updates#apply_and_clear_cache'
    end
  end
  resources :rollbacks, only: %i[index new create]
  resources :footnotes, only: %i[index edit update]
  resources :measure_types, only: %i[index edit update]
  resources :news_items, except: %i[show]
  resources :news_collections, only: %i[index edit update create new]
  resources :reports, only: %i[index show]
  resources :balance_events, only: %i[show]

  resources :quotas, only: %i[new show] do
    collection do
      get '/search', as: :perform_search, via: %i[get post], to: 'quotas#search'
    end
  end

  post 'govspeak' => 'govspeak#govspeak', as: :govspeak
  get  'healthcheck' => 'healthcheck#check', as: :healthcheck
  get 'healthcheckz' => 'rails/health#show', as: :rails_health_check
  get  '/' => 'pages#index', as: :index
  root to: 'pages#index'

  match '/400', to: 'errors#bad_request', via: :all
  match '/404', to: 'errors#not_found', via: :all
  match '/405', to: 'errors#method_not_allowed', via: :all
  match '/406', to: 'errors#not_acceptable', via: :all
  match '/422', to: 'errors#unprocessable_entity', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
  match '/501', to: 'errors#not_implemented', via: :all
end
