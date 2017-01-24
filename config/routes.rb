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

    # ONLY FOR UAT TESTING
    if ENV["TEST_USER_ID"]
      post 'uncertify', on: :member
    end

  end

  resources :certification_cancellations, only: [:show, :create]

  scope path: "/dispatch" do
    # TODO(jd): Make this its own controller action that looks at the user's roles
    # and redirects accordingly
    get "/", to: redirect("/dispatch/establish-claim")

    resources :establish_claims,
              path: "/establish-claim",
              task_type: :EstablishClaim,
              only: [:index, :show] do

      patch 'assign', on: :collection
      post 'perform', on: :member
      post 'assign-existing-end-product', on: :member
      get 'pdf', on: :member
    end
  end

  scope path: "/decision" do
    get "/", to: redirect("/decision/review")

    resources :review,
              path: "/review",
              only: [:index] do
      get 'pdf', on: :collection
    end
  end

  resources :tasks, only: [] do
    patch 'cancel', on: :member
  end

  patch "certifications" => "certifications#create"

  # :nocov:
  if ApplicationController.dependencies_faked?
    scope "/dev" do
      get '/users', to: "dev_users#index"
      post '/set-user/:id', to: "dev#set_user", as: 'set_user'
      get '/set-end-products', to: "dev#set_end_products", as: 'set_end_products'
    end
  end
  # :nocov:

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

  get 'help' => 'help#show'

  # alias root to help; make sure to keep this below the canonical route so url_for works
  root 'help#show'

  mount PdfjsViewer::Rails::Engine => "/pdfjs", as: 'pdfjs'

  get "unauthorized" => "application#unauthorized"

  %w( 404 500 ).each do |code|
    get code, :to => "errors#show", :status_code => code
  end


  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
