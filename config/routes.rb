require "routing_filter/service_path_prefix_handler"

Rails.application.routes.draw do
  filter :service_path_prefix_handler
  default_url_options(host: TradeTariffAdmin.host)

  namespace :notes, module: :notes do
    resources :sections, only: %i[index show] do
      scope module: "sections" do
        resource :section_note
        resources :chapters, only: [:index]
      end
    end

    resources :chapters, only: %i[index show] do
      scope module: "chapters" do
        resource :chapter_note
        resources :headings, only: [:index]
      end
    end
  end

  namespace :references, path: "search_references" do
    get :search, to: "entity_searches#index"

    resources :sections, only: %i[index] do
      scope module: "sections" do
        resources :chapters, only: [:index]
      end
    end

    resources :chapters, only: %i[index show] do
      scope module: "chapters" do
        resources :headings, only: [:index]
        resources :search_references
      end
    end

    resources :headings do
      scope module: "headings" do
        resources :commodities, only: [:index]
        resources :search_references
      end
    end

    resources :commodities do
      scope module: "commodities" do
        resources :search_references
      end
    end
  end

  resources :goods_nomenclature_labels, only: %i[index] do
    collection do
      get :search
    end
  end

  get "goods_nomenclature_labels/:goods_nomenclature_id",
      to: "goods_nomenclature_labels#show",
      as: :goods_nomenclature_label,
      constraints: { goods_nomenclature_id: /\d{10}/ }

  patch "goods_nomenclature_labels/:goods_nomenclature_id",
        to: "goods_nomenclature_labels#update",
        constraints: { goods_nomenclature_id: /\d{10}/ }

  resources :goods_nomenclature_self_texts, only: %i[index] do
    collection do
      get :search
    end
  end

  get "goods_nomenclature_self_texts/:goods_nomenclature_id",
      to: "goods_nomenclature_self_texts#show",
      as: :goods_nomenclature_self_text,
      constraints: { goods_nomenclature_id: /\d{10}/ }

  patch "goods_nomenclature_self_texts/:goods_nomenclature_id",
        to: "goods_nomenclature_self_texts#update",
        constraints: { goods_nomenclature_id: /\d{10}/ }

  post "goods_nomenclature_self_texts/:goods_nomenclature_id/score",
       to: "goods_nomenclature_self_texts#score",
       as: :score_goods_nomenclature_self_text,
       constraints: { goods_nomenclature_id: /\d{10}/ }

  post "goods_nomenclature_self_texts/:goods_nomenclature_id/regenerate",
       to: "goods_nomenclature_self_texts#regenerate",
       as: :regenerate_goods_nomenclature_self_text,
       constraints: { goods_nomenclature_id: /\d{10}/ }

  post "goods_nomenclature_self_texts/:goods_nomenclature_id/approve",
       to: "goods_nomenclature_self_texts#approve",
       as: :approve_goods_nomenclature_self_text,
       constraints: { goods_nomenclature_id: /\d{10}/ }

  post "goods_nomenclature_self_texts/:goods_nomenclature_id/reject",
       to: "goods_nomenclature_self_texts#reject",
       as: :reject_goods_nomenclature_self_text,
       constraints: { goods_nomenclature_id: /\d{10}/ }

  resources :classification_configurations, param: :name, only: %i[index show edit update]

  namespace :green_lanes, path: "green_lanes" do
    resources :category_assessments, only: %i[index new create edit update destroy] do
      member do
        post "add_exemption"
        delete "remove_exemption"
        post "add_measure"
      end
    end
    resources :exempting_overrides, only: %i[index]
    resources :exempting_certificate_overrides, only: %i[new create destroy]
    resources :exempting_additional_code_overrides, only: %i[new create destroy]
    resources :exemptions, only: %i[index new create edit update destroy]
    resources :measures, only: %i[index destroy]
    resources :update_notifications, only: %i[index edit update]
    resources :measure_type_mappings, only: %i[index new create destroy]
  end

  resources :tariff_updates, only: %i[index show] do
    collection do
      post "/download", to: "tariff_updates#download"
      post "/apply_and_clear_cache", to: "tariff_updates#apply_and_clear_cache"
      post "/resend_cds_update_notification", to: "tariff_updates#resend_cds_update_notification"
    end
  end
  resources :rollbacks, only: %i[index new create]
  resources :news_items, except: %i[show]
  resources :news_collections, only: %i[index edit update create new]
  resources :live_issues, only: %i[index create new update edit destroy]
  resources :users, only: %i[index edit update]

  resources :quotas, only: %i[new show] do
    collection do
      get "/search", as: :perform_search, via: %i[get post], to: "quotas#search"
    end
  end

  get "/auth/redirect", to: "sessions#handle_redirect"
  get "/auth/invalid", to: "sessions#invalid"
  get "/auth/logout", to: "sessions#destroy", as: :logout
  get "/auth/login", to: "sessions#login", as: :identity_login

  post "govspeak" => "govspeak#govspeak", as: :govspeak
  get  "healthcheck" => "healthcheck#check", as: :healthcheck
  get "healthcheckz" => "rails/health#show", as: :rails_health_check
  get "/dashboard", to: "pages#index", as: :dashboard
  root to: "homepage#index"

  post "/csp-violation-report", to: "csp_reports#create"

  match "/400", to: "errors#bad_request", via: :all
  match "/404", to: "errors#not_found", via: :all
  match "/405", to: "errors#method_not_allowed", via: :all
  match "/406", to: "errors#not_acceptable", via: :all
  match "/422", to: "errors#unprocessable_content", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
  match "/501", to: "errors#not_implemented", via: :all

  if TradeTariffAdmin.basic_session_authentication?
    resources :basic_sessions, only: %i[new create]
  end
end
