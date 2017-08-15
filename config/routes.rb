Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  resources :sessions, only: [:new, :update]
  resources :certifications, path_names: { new: "new/:vacols_id" } do
    get 'pdf', on: :member
    get 'form9_pdf', on: :member
    post 'confirm', on: :member
    put 'update_v2', on: :member
    post 'certify_v2', on: :member
  end

  # These routes are here so Certification v2 SPA can be launched if the
  # user reloads the page.
  get 'certifications(/:vacols_id)/check_documents' => 'certifications#new'
  get 'certifications(/:vacols_id)/confirm_case_details' => 'certifications#new'
  get 'certifications(/:vacols_id)/confirm_hearing' => 'certifications#new'
  get 'certifications(/:vacols_id)/sign_and_certify' => 'certifications#new'
  get 'certifications(/:vacols_id)/success' => 'certifications#new'

  resources :certification_cancellations, only: [:show, :create]

  namespace :api do
    namespace :v1 do
      resources :appeals, only: :index
    end
  end

  scope path: "/dispatch" do
    get "/", to: redirect("/dispatch/establish-claim")
    get 'missing-decision', to: 'establish_claims#unprepared_tasks'
    get 'canceled', to: 'establish_claims#canceled_tasks'
    get 'work-assignments', to: 'establish_claims#work_assignments'
    patch 'employee-count/:count', to: 'establish_claims#update_employee_count'

    resources :user_quotas, path: "/user-quotas", only: :update

    resources :establish_claims,
              path: "/establish-claim",
              task_type: :EstablishClaim,
              only: [:index, :show] do

      patch 'assign', on: :collection
      post 'perform', on: :member
      post 'assign-existing-end-product', on: :member
      post 'review-complete', on: :member
      post 'email-complete', on: :member
      post 'no-email-complete', on: :member
      get 'pdf', on: :member
      patch 'cancel', on: :member
      put 'update-appeal', on: :member
    end
  end

  resources :document, only: [:update] do
    get :pdf, on: :member
    patch 'mark-as-read', on: :member
    resources :annotation, only: [:create, :destroy, :update]
    resources :tag, only: [:create, :destroy]
  end

  namespace :reader do
    resources :appeal, only: [:show, :index] do
      resources :documents, only: [:show, :index]
      resources :claims_folder_searches, only: :create
    end
  end

  namespace :hearings do
    resources :dockets, only: [:index, :show]
    resources :worksheets, only: [:update, :show]
  end

  resources :hearings, only: [:update]

  patch "certifications" => "certifications#create"

  namespace :admin do
    post "establish-claim", to: "establish_claims#create"
    get "establish-claim", to: "establish_claims#show"
  end

  resources :functions, only: :index
  patch '/functions/change', to: 'functions#change'

  resources :offices, only: :index

  get "health-check", to: "health_checks#show"
  get "dependencies-check", to: "dependencies_checks#show"
  get "login" => "sessions#new"
  get "logout" => "sessions#destroy"

  get 'whats-new' => 'whats_new#show'

  get 'certification/stats(/:interval)', to: 'certification_stats#show', as: 'certification_stats'
  get 'certification_v2/stats(/:interval)', to: 'certification_v2_stats#show', as: 'certification_v2_stats'
  get 'dispatch/stats(/:interval)', to: 'dispatch_stats#show', as: 'dispatch_stats'
  get 'stats', to: 'stats#show'

  get "styleguide", to: "styleguide#show"

  get 'help' => 'help#index'
  get 'dispatch/help' => 'help#dispatch'
  get 'certification/help' => 'help#certification'
  get 'reader/help' => 'help#reader'
  get 'hearings/help' => 'help#hearings'


  # alias root to help; make sure to keep this below the canonical route so url_for works
  root 'help#index'

  mount PdfjsViewer::Rails::Engine => "/pdfjs", as: 'pdfjs'

  get "unauthorized" => "application#unauthorized"

  %w( 404 500 ).each do |code|
    get code, :to => "errors#show", :status_code => code
  end

  # :nocov:
  namespace :test do
    # Only allow data_setup routes if TEST_USER is set
    if ENV["TEST_USER_ID"]
      resources :setup, only: [:index]
      post "setup-uncertify-appeal" => "setup#uncertify_appeal"
      post "setup-appeal-location-date-reset" => "setup#appeal_location_date_reset"
      post "setup-toggle-features" => "setup#toggle_features"
      get "setup-delete-test-data" => "setup#delete_test_data"
    end

    if ApplicationController.dependencies_faked?
      resources :users, only: [:index]
      post "/set_user/:id", to: "users#set_user", as: "set_user"
      post "/set_end_products", to: "users#set_end_products", as: 'set_end_products'
    end
  end

  require "sidekiq/web"
  require "sidekiq/cron/web"
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    # Protect against timing attacks:
        # - See https://codahale.com/a-lesson-in-timing-attacks/
        # - See https://thisdata.com/blog/timing-attacks-against-string-comparison/
        # - Use & (do not use &&) so that it doesn't short circuit.
        # - Use digests to stop length information leaking (see also ActiveSupport::SecurityUtils.variable_size_secure_compare)
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USERNAME"])) &
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"]))
  end
  mount Sidekiq::Web, at: "/sidekiq"

  # :nocov:
end
