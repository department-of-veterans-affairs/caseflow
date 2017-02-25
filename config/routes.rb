Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".


  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):

  resources :sessions, only: [:new, :create]
  resources :certifications, path_names: { new: "new/:vacols_id" } do
    get 'pdf', on: :member
    post 'confirm', on: :member
    get 'cancel', on: :member
  end

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
      post 'note-complete', on: :member
      post 'email-complete', on: :member
      get 'pdf', on: :member
      patch 'cancel', on: :member
    end
  end

  resources :document, only: [] do
    patch 'set-label', on: :member
  end

  scope path: "/decision" do
    get "/", to: redirect("/decision/review")

    resources :annotation,
              path: "/review/annotation",
              only: [:create, :destroy, :update],
              on: :member

    resources :review,
              path: "/review",
              only: [:index] do
      get 'pdf', on: :collection
      get 'show', on: :collection
    end
  end

  patch "certifications" => "certifications#create"

  namespace :admin do
    resource :establish_claim,
             only: [:show, :create]
  end

  resources :functions, only: :index
  patch '/functions/change', to: 'functions#change'

  resources :offices, only: :index

  get "health-check", to: "health_checks#show"
  get "login" => "sessions#new"
  get "logout" => "sessions#destroy"

  get 'whats-new' => 'whats_new#show'

  get 'stats(/:interval)', to: 'stats#show', as: 'stats'

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
      post "setup_certification" => "setup#certification"
      post "setup_claims_establishment" => "setup#claims_establishment"
    end

    if ApplicationController.dependencies_faked?
      resources :users, only: [:index]
      post "/set_user/:id", to: "setup#set_user", as: "set_user"
      post "/set-end-products", to: "setup#set_end_products", as: 'set_end_products'
    end
  end
  # :nocov:
end
