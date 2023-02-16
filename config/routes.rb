require 'sidekiq/web'
require 'sidekiq-scheduler/web'
require 'gds_editor_constraint'
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
    resource :import, only: %i[show create]
    resource :export, only: [:create]

    resources :sections, only: %i[index] do
      scope module: 'sections' do
        resources :chapters, only: [:index]
      end
    end

    resources :chapters, only: %i[index show] do
      scope module: 'chapters' do
        resources :headings, only: [:index]
        resources :search_references do
          post :export, on: :collection
        end
      end
    end

    resources :headings do
      scope module: 'headings' do
        resources :commodities, only: [:index]
        resources :search_references do
          post :export, on: :collection
        end
      end
    end

    resources :commodities do
      scope module: 'commodities' do
        resources :search_references do
          post :export, on: :collection
        end
      end
    end
  end

  resources :tariff_updates, only: %i[index show]
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
  get  '/' => 'pages#index', as: :index
  mount Sidekiq::Web => '/sidekiq', constraints: GdsEditorConstraint.new
  root to: 'pages#index'
end
