Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  resources :sessions, only: [:new, :create]
  resources :certifications, path_names: { new: "new/:vacols_id" } do
    get 'pdf', on: :member
    get 'form9_pdf', on: :member
    post 'confirm', on: :member
  end

  # These routes are here so Certification v2 SPA can be launched if the
  # user reloads the page.
  get 'certifications(/:vacols_id)/check_documents' => 'certifications#new'
  get 'certifications(/:vacols_id)/confirm_case_details' => 'certifications#new'
  get 'certifications(/:vacols_id)/confirm_hearing' => 'certifications#new'
  get 'certifications(/:vacols_id)/sign_and_certify' => 'certifications#new'
  get 'certifications(/:vacols_id)/success' => 'certifications#new'

  resources :certification_cancellations, only: [:show, :create]

  scope path: "/dispatch" do
    # TODO(jd): Make this its own controller action that looks at the user's roles
    # and redirects accordingly
    get "/", to: redirect("/dispatch/establish-claim")
    get 'missing-decision', to: 'establish_claims#unprepared_tasks'
    patch 'employee-count/:count', to: 'establish_claims#update_employee_count'

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
  end

  namespace :reader do
    resources :appeal, only: [] do
      resources :documents, only: [:show, :index]
    end

    resources :documents, only: [] do
      resources :tags, only: [:create, :index, :destroy]
    end
  end

  patch "certifications" => "certifications#create"

  namespace :admin do
    post "establish-claim", to: "establish_claims#create"
    get "establish-claim", to: "establish_claims#show"
  end

  resources :functions, only: :index
  patch '/functions/change', to: 'functions#change'

  resources :offices, only: :index

  get "health-check", to: "health_checks#show"
  get "login" => "sessions#new"
  get "logout" => "sessions#destroy"

  get 'whats-new' => 'whats_new#show'

  get 'certification/stats(/:interval)', to: 'certification_stats#show', as: 'certification_stats'
  get 'dispatch/stats(/:interval)', to: 'dispatch_stats#show', as: 'dispatch_stats'
  get 'stats', to: 'stats#show'

  get "styleguide", to: "styleguide#show"

  get 'help' => 'help#show'

  # alias root to help; make sure to keep this below the canonical route so url_for works
  root 'help#show'

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
      get "setup-delete-test-data" => "setup#delete_test_data"
    end

    if ApplicationController.dependencies_faked?
      resources :users, only: [:index]
      post "/set-user/:id", to: "users#set_user", as: "set_user"
      post "/set-end-products", to: "users#set_end_products", as: 'set_end_products'
    end
  end
  # :nocov:
end
