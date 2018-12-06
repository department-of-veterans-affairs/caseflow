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

  namespace :idt do
    get 'auth', to: 'authentications#index'
    namespace :api do
      namespace :v1 do
        get 'token', to: 'tokens#generate_token'
        get 'appeals', to: 'appeals#list'
        get 'appeals/:appeal_id', to: 'appeals#details'
        post 'appeals/:appeal_id/outcode', to: 'appeals#outcode'
        get 'judges', to: 'judges#index'
        get 'user', to: 'users#index'
      end
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

  resources :appeals, param: :appeal_id, only: [:index, :show, :edit] do
    member do
      get :document_count
      get :new_documents
      get :veteran
      get :power_of_attorney
      resources :issues, only: [:create, :update, :destroy], param: :vacols_sequence_id
      resources :special_issues, only: [:create, :index]
      resources :advance_on_docket_motions, only: [:create]
      get 'tasks', to: "tasks#for_appeal"
      patch 'update'
    end
  end
  match '/appeals/:appeal_id/edit/:any' => 'appeals#edit', via: [:get]

  resources :beaam_appeals, only: [:index]

  resources :regional_offices, only: [:index]
  get '/regional_offices/:regional_office/open_hearing_dates', to: "regional_offices#open_hearing_dates"

  namespace :hearings do
    resources :dockets, only: [:index, :show], param: :docket_date
    resources :worksheets, only: [:update, :show], param: :hearing_id
    resources :appeals, only: [:update], param: :appeal_id
    resources :hearing_day, only: [:index, :show, :destroy, :update]
    resources :schedule_periods, only: [:index, :create]
    resources :schedule_periods, only: [:show, :update, :download], param: :schedule_period_id
    resources :hearing_day, only: [:update, :show], param: :hearing_key
  end
  get 'hearings/schedule', to: "hearings/hearing_day#index"
  get 'hearings/schedule/docket/:id', to: "hearings/hearing_day#index"
  get 'hearings/schedule/build', to: "hearing_schedule#build_schedule_index"
  get 'hearings/schedule/build/upload', to: "hearing_schedule#build_schedule_index"
  get 'hearings/schedule/build/upload/:schedule_period_id', to: "hearing_schedule#build_schedule_index"
  get 'hearings/schedule/assign', to: "hearing_schedule#index"
  get 'hearings/:hearing_id/worksheet', to: "hearings/worksheets#show", as: 'hearing_worksheet'
  get 'hearings/:hearing_id/worksheet/print', to: "hearings/worksheets#show_print"
  post 'hearings/hearing_day', to: "hearings/hearing_day#create"
  put 'hearings/:hearing_key/hearing_day', to: "hearings/hearing_day#update_other"
  get 'hearings/schedule/:schedule_period_id/download', to: "hearings/schedule_periods#download"
  get 'hearings/schedule/assign/hearing_days', to: "hearings/hearing_day#index_with_hearings"
  get 'hearings/schedule/assign/veterans', to: "hearings/hearing_day#appeals_ready_for_hearing_schedule"
  get 'hearings/queue/appeals/:vacols_id', to: 'queue#index'

  resources :hearings, only: [:update]

  patch "certifications" => "certifications#create"

  get 'help' => 'help#index'
  get 'dispatch/help' => 'help#dispatch'
  get 'certification/help' => 'help#certification'
  get 'reader/help' => 'help#reader'
  get 'hearings/help' => 'help#hearings'
  get 'intake/help' => 'help#intake'
  get 'queue/help' => 'help#queue'


  root 'home#index'

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

  resources :higher_level_reviews, param: :claim_id, only: [:edit] do
    patch 'update', on: :member
  end
  match '/higher_level_reviews/:claim_id/edit/:any' => 'higher_level_reviews#edit', via: [:get]

  resources :supplemental_claims, param: :claim_id, only: [:edit] do
    patch 'update', on: :member
  end
  match '/supplemental_claims/:claim_id/edit/:any' => 'supplemental_claims#edit', via: [:get]

  resources :users, only: [:index]

  get 'cases/:caseflow_veteran_id', to: 'appeals#show_case_list'

  scope path: '/queue' do
    get '/', to: 'queue#index'
    get '/beaam', to: 'queue#index'
    get '/appeals/:vacols_id', to: 'queue#index'
    get '/appeals/:vacols_id/*all', to: redirect('/queue/appeals/%{vacols_id}')
    get '/:user_id(*rest)', to: 'legacy_tasks#index'
  end

  get '/search', to: 'queue#index'

  resources :legacy_tasks, only: [:create, :update]
  resources :tasks, only: [:index, :create, :update]

  resources :distributions, only: [:new, :show]

  resources :organizations, only: [:show], param: :url do
    resources :tasks, only: [:index], controller: 'organizations/tasks'
    resources :users, only: [:index, :create, :destroy], controller: 'organizations/users'
  end

  post '/case_reviews/:task_id/complete', to: 'case_reviews#complete'

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
      post "/reseed", to: "users#reseed", as: "reseed"
    end
    post "/log_in_as_user", to: "users#log_in_as_user", as: "log_in_as_user"
    post "/toggle_feature", to: "users#toggle_feature", as: "toggle_feature"
  end

  # :nocov:
end
