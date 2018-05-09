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
      resources :jobs, only: :create
    end
    namespace :v2 do
      resources :appeals, only: :index
    end
  end

  namespace :metrics do
    namespace :v1 do
      resources :histogram, only: :create
    end
  end

  namespace :dispatch do
    get "/", to: redirect("/dispatch/establish-claim")
    get 'missing-decision', to: 'establish_claims#unprepared_tasks'
    get 'admin', to: 'establish_claims#admin'
    get 'canceled', to: 'establish_claims#canceled_tasks'
    get 'work-assignments', to: 'establish_claims#work_assignments'
    patch 'employee-count/:count', to: 'establish_claims#update_employee_count'

    resources :user_quotas, path: "/user-quotas", only: :update
    resources :tasks, only: [:index]

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
    get 'appeal/veteran-id', to: "appeal#find_appeals_by_veteran_id",
      constraints: lambda{ |req| req.env["HTTP_VETERAN_ID"] =~ /[a-zA-Z0-9]{2,12}/ }
    resources :appeal, only: [:show, :index] do
      resources :documents, only: [:show, :index]
      resources :claims_folder_searches, only: :create
    end
  end

  resources :appeals, only: [:index, :show] do
    resources :issues, only: [:create, :update, :destroy], param: :vacols_sequence_id
  end

  namespace :hearings do
    resources :dockets, only: [:index, :show], param: :docket_date
    resources :worksheets, only: [:update, :show], param: :hearing_id
    resources :appeals, only: [:update], param: :appeal_id
  end
  get 'hearings/:hearing_id/worksheet', to: "hearings/worksheets#show", as: 'hearing_worksheet'
  get 'hearings/:hearing_id/worksheet/print', to: "hearings/worksheets#show_print"

  resources :hearings, only: [:update]

  patch "certifications" => "certifications#create"

  get 'help' => 'help#index'
  get 'dispatch/help' => 'help#dispatch'
  get 'certification/help' => 'help#certification'
  get 'reader/help' => 'help#reader'
  get 'hearings/help' => 'help#hearings'
  get 'intake/help' => 'help#intake'

  # alias root to help; make sure to keep this below the canonical route so url_for works
  root 'help#index'

  scope path: '/intake' do
    get "/", to: 'intakes#index'
    get "/manager", to: 'intake_manager#index'
    get "/manager/flagged_for_review", to: 'intake_manager#flagged_for_review'
  end

  resources :intakes, path: "/intake", only: [:index, :create, :destroy] do
    patch 'review', on: :member
    patch 'complete', on: :member
    patch 'error', on: :member
  end

  resources :users, only: [:index]

  scope path: '/queue' do
    get '/', to: 'queue#index'
    get '/appeals/:vacols_id', to: 'queue#index'
    get '/appeals/:vacols_id/*all', to: redirect('/queue/appeals/%{vacols_id}')
    get '/docs_for_dev', to: 'queue#dev_document_count'
    get '/:user_id', to: 'queue#tasks'
    get '/:user_id/review', to: 'queue#tasks'
    get '/:user_id/assign', to: 'queue#tasks'
    post '/appeals/:task_id/complete', to: 'queue#complete'
    post '/appeals', to: 'queue#create'
    patch '/appeals/:task_id', to: 'queue#update'

    # Our single page app requires us to keep the old routes around for a while since we are not guaranteed that
    # everybody who uses our app will have the latest version of the app. Remove these legacy routes after PR related
    # to caseflow issue #5309 is deployed.
    get '/tasks/:vacols_id', to: 'queue#index'
    get '/tasks/:vacols_id/*all', to: redirect('/queue/appeals/%{vacols_id}')
    post '/tasks/:task_id/complete', to: 'queue#complete'
    post '/tasks', to: 'queue#create'
    patch '/tasks/:task_id', to: 'queue#update'
  end

  get "health-check", to: "health_checks#show"
  get "dependencies-check", to: "dependencies_checks#show"
  get "login" => "sessions#new"
  get "logout" => "sessions#destroy"

  get 'whats-new' => 'whats_new#show'

  get 'certification/stats(/:interval)', to: 'certification_stats#show', as: 'certification_stats'
  get 'dispatch/stats(/:interval)', to: 'dispatch_stats#show', as: 'dispatch_stats'
  get 'intake/stats(/:interval)', to: 'intake_stats#show', as: 'intake_stats'
  get 'stats', to: 'stats#show'

  match '/intake/:any' => 'intakes#index', via: [:get]

  get "styleguide", to: "styleguide#show"


  mount PdfjsViewer::Rails::Engine => "/pdfjs", as: 'pdfjs'

  get "unauthorized" => "application#unauthorized"

  %w( 404 500 ).each do |code|
    get code, :to => "errors#show", :status_code => code
  end

  # :nocov:
  namespace :test do
    resources :users, only: [:index]
    if ApplicationController.dependencies_faked?
      post "/set_user/:id", to: "users#set_user", as: "set_user"
      post "/set_end_products", to: "users#set_end_products", as: 'set_end_products'
    end
    post "/log_in_as_user", to: "users#log_in_as_user", as: "log_in_as_user"
  end

  # :nocov:
end
