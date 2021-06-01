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
      resources :hearings, only: :show, param: :hearing_day
    end
    namespace :v3 do
      namespace :decision_reviews do
        namespace :higher_level_reviews do
          get "contestable_issues(/:benefit_type)", to: "contestable_issues#index"
        end
        resources :higher_level_reviews, only: [:create, :show]
        resources :supplemental_claims, only: [:create, :show]
        namespace :appeals do
          get 'contestable_issues', to: "contestable_issues#index"
        end
        resources :appeals, only: [:create, :show]
        resources :intake_statuses, only: :show
      end
    end
    namespace :docs do
      namespace :v3, defaults: { format: 'json' } do
        get 'decision_reviews', to: 'docs#decision_reviews'
      end
    end
    get "metadata", to: 'metadata#index'
  end

  namespace :idt do
    get 'auth', to: 'authentications#index'
    namespace :api do
      namespace :v1 do
        get 'token', to: 'tokens#generate_token'
        get 'appeals', to: 'appeals#list'
        get 'appeals/:appeal_id', to: 'appeals#details'
        post 'appeals/:appeal_id/outcode', to: 'appeals#outcode'
        post 'appeals/:appeal_id/upload_document', to: 'upload_vbms_document#create'
        get 'judges', to: 'judges#index'
        get 'user', to: 'users#index'
        get 'veterans', to: 'veterans#details'
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
      constraints: lambda{ |req| req.env["HTTP_CASE_SEARCH"] =~ /[a-zA-Z0-9]{2,12}/ }
    resources :appeal, only: [:show, :index] do
      resources :documents, only: [:show, :index]
      resources :claims_folder_searches, only: :create
    end
  end

  put '/claimants/:participant_id/poa', to: 'claimants#refresh_claimant_poa'

  resources :appeals, param: :appeal_id, only: [:index, :show, :edit] do
    member do
      get :document_count
      get :veteran
      get :power_of_attorney
      patch :update_power_of_attorney
      get 'hearings', to: "appeals#most_recent_hearing"
      resources :issues, only: [:create, :update, :destroy], param: :vacols_sequence_id
      resources :special_issues, only: [:create, :index]
      resources :advance_on_docket_motions, only: [:create]
      get 'tasks', to: "tasks#for_appeal"
      patch 'update'
      post 'work_mode', to: "work_modes#create"
      patch 'cavc_remand', to: "cavc_remands#update"
      post 'cavc_remand', to: "cavc_remands#create"
      post 'appellant_substitution', to: "appellant_substitutions#create"
      patch 'nod_date_update', to: "nod_date_updates#update"
    end
  end
  match '/appeals/:appeal_id/edit/:any' => 'appeals#edit', via: [:get]

  get '/task_tree/:appeal_type/:appeal_id' => 'task_tree#show'

  resources :regional_offices, only: [:index]
  get '/regional_offices/:regional_office/hearing_dates', to: "regional_offices#hearing_dates"

  namespace :hearings do
    resources :appeals, only: [:update], param: :appeal_id
    resources :hearing_day, only: [:index, :show, :destroy, :update]
    resources :schedule_hearing_tasks, only: [:index]
    resources :schedule_hearing_tasks_columns, only: [:index]
    resources :schedule_periods, only: [:index, :create]
    resources :schedule_periods, only: [:show, :update, :download], param: :schedule_period_id
    resources :hearing_day, only: [:update, :show], param: :hearing_key
    namespace :hearing_day do
      get '/:hearing_day_id/filled_hearing_slots', to: "filled_hearing_slots#index"
    end
  end
  get '/hearings/dockets', to: redirect("/hearings/schedule")
  get 'hearings/schedule', to: "hearings/hearing_day#index"
  get 'hearings/schedule/add_hearing_day', to: "hearings/hearing_day#index"
  get 'hearings/:hearing_id/details', to: "hearings_application#show_hearing_index"
  get 'hearings/:hearing_id/worksheet', to: "hearings_application#show_hearing_index"
  get 'hearings/:id/virtual_hearing_job_status', to: 'hearings#virtual_hearing_job_status'
  get 'hearings/schedule/docket/:id', to: "hearings/hearing_day#index"
  get 'hearings/schedule/docket/:id/print', to: "hearings/hearing_day_print#index"
  get 'hearings/schedule/build', to: "hearings_application#build_schedule_index"
  get 'hearings/schedule/build/upload', to: "hearings_application#build_schedule_index"
  get 'hearings/schedule/build/upload/:schedule_period_id', to: "hearings_application#build_schedule_index"
  get 'hearings/schedule/assign', to: "hearings_application#index"
  get 'hearings/worksheet/print', to: "hearings/worksheets_print#index"
  post 'hearings/hearing_day', to: "hearings/hearing_day#create"
  get 'hearings/schedule/:schedule_period_id/download', to: "hearings/schedule_periods#download"
  get 'hearings/schedule/assign/hearing_days', to: "hearings/hearing_day#index_with_hearings"
  get 'hearings/queue/appeals/:vacols_id', to: 'queue#index'
  get 'hearings/find_closest_hearing_locations', to: 'hearings#find_closest_hearing_locations'

  post 'hearings/hearing_view/:id', to: 'hearings/hearing_view#create'

  resources :hearings, only: [:update, :show]

  patch "certifications" => "certifications#create"

  get 'help' => 'help#index'
  get 'dispatch/help' => 'help#dispatch'
  get 'certification/help' => 'help#certification'
  get 'reader/help' => 'help#reader'
  get 'hearing_prep/help' => 'help#hearings'
  get 'intake/help' => 'help#intake'
  get 'queue/help' => 'help#queue'


  root 'home#index'

  scope path: '/intake' do
    get "/", to: 'intakes#index'
    get "/attorneys", to: 'intakes#attorneys'
    get "/manager", to: 'intake_manager#index'
    get "/manager/flagged_for_review", to: 'intake_manager#flagged_for_review'
    get "/manager/users/:user_css_id", to: 'intake_manager#user_stats'
  end

  resources :intakes, path: "/intake", only: [:index, :create, :destroy] do
    patch 'review', on: :member
    patch 'complete', on: :member
    patch 'error', on: :member
  end

  resources :higher_level_reviews, param: :claim_id, only: [:edit] do
    patch 'update', on: :member
    post 'edit_ep', on: :member
  end
  match '/higher_level_reviews/:claim_id/edit/:any' => 'higher_level_reviews#edit', via: [:get]

  resources :supplemental_claims, param: :claim_id, only: [:edit] do
    patch 'update', on: :member
    post 'edit_ep', on: :member
  end
  match '/supplemental_claims/:claim_id/edit/:any' => 'supplemental_claims#edit', via: [:get]

  resources :decision_reviews, param: :business_line_slug, only: [] do
    resources :tasks, controller: :decision_reviews, param: :task_id, only: [:show, :update] do
    end
  end
  match '/decision_reviews/:business_line_slug' => 'decision_reviews#index', via: [:get]

  resources :asyncable_jobs, param: :klass, only: [] do
    resources :jobs, controller: :asyncable_jobs, param: :id, only: [:index, :show, :update]
    post "jobs/:id/note", to: "asyncable_jobs#add_note"
  end
  match '/jobs' => 'asyncable_jobs#index', via: [:get]

  scope path: "/inbox" do
    get "/", to: "inbox#index"
    patch "/messages/:id", to: "inbox#update"
  end

  resources :users, only: [:index, :update] do
    resources :task_pages, only: [:index], controller: 'users/task_pages'
    get 'represented_organizations', on: :member
  end

  get 'user', to: 'users#search'
  get 'user_info/represented_organizations'

  get 'cases/:veteran_ids', to: 'appeals#show_case_list'

  scope path: '/queue' do
    get '/', to: 'queue#index'
    get '/appeals/:vacols_id', to: 'queue#index'
    get '/appeals/:vacols_id/tasks/:task_id/schedule_veteran', to: 'queue#index' # Allow direct navigation from the Hearings App
    get '/appeals/:vacols_id/*all', to: redirect('/queue/appeals/%{vacols_id}')
    get '/:user_id(*rest)', to: 'legacy_tasks#index'
  end

  resources :team_management, only: [:index, :update]
  get '/team_management(*rest)', to: 'team_management#index'
  post '/team_management/judge_team/:user_id', to: 'team_management#create_judge_team'
  post '/team_management/dvc_team/:user_id', to: 'team_management#create_dvc_team'
  post '/team_management/private_bar', to: 'team_management#create_private_bar'
  post '/team_management/national_vso', to: 'team_management#create_national_vso'
  post '/team_management/field_vso', to: 'team_management#create_field_vso'

  resources :user_management, only: [:index]

  get '/search', to: 'appeals#show_case_list'

  resources :legacy_tasks, only: [:create, :update]
  post '/legacy_tasks/assign_to_judge', to: 'legacy_tasks#assign_to_judge'
  resources :tasks, only: [:index, :create, :update] do
    member do
      post :reschedule
      post :request_hearing_disposition_change
      patch :change_type, to: 'tasks/change_type#update'
    end
    resources(:place_hold, only: [:create], controller: 'tasks/place_hold')
    resources(:end_hold, only: [:create], controller: 'tasks/end_hold')
    resources(:extension_request, only: [:create], controller: 'extension_request')
  end

  resources :judge_assign_tasks, only: [:create]

  resources :bulk_task_assignments, only: [:create]

  resources :distributions, only: [:new, :show]

  resources :organizations, only: [:show], param: :url do
    resources :tasks, only: [:index], controller: 'organizations/tasks'
    resources :task_pages, only: [:index], controller: 'organizations/task_pages'
    resources :users, only: [:index, :create, :update, :destroy], controller: 'organizations/users'
    # Maintain /organizations/members for backwards compatability for a few days.
    resources :members, only: [:index], controller: 'organizations/task_summary'
    resources :task_summary, only: [:index], controller: 'organizations/task_summary'
  end
  get '/organizations/:url/modal(*rest)', to: 'organizations#show'

  post '/case_reviews/:task_id/complete', to: 'case_reviews#complete'
  patch '/case_reviews/:id', to: 'case_reviews#update'

  get "health-check", to: "health_checks#show"
  get "dependencies-check", to: "dependencies_checks#show"
  get "login" => "sessions#new"
  get "logout" => "sessions#destroy"

  get 'whats-new' => 'whats_new#show'

  get 'dispatch/stats(/:interval)', to: 'dispatch_stats#show', as: 'dispatch_stats'
  get 'stats', to: 'stats#show'

  match '/intake/:any' => 'intakes#index', via: [:get]

  get "styleguide", to: "styleguide#show"

  get "tableau-login", to: "tableau_logins#login"

  mount PdfjsViewer::Rails::Engine => "/pdfjs", as: 'pdfjs'

  get "unauthorized" => "application#unauthorized"

  get "feedback" => "application#feedback"

  %w( 404 500 ).each do |code|
    get code, :to => "errors#show", :status_code => code
  end

  post "post_decision_motions/return", to: "post_decision_motions#return_to_lit_support"
  post "post_decision_motions/return_to_judge", to: "post_decision_motions#return_to_judge"
  post "post_decision_motions", to: "post_decision_motions#create"
  post "docket_switches", to: "docket_switches#create"
  post "docket_switches/address_ruling", to: "docket_switches#address_ruling"

  # :nocov:
  namespace :test do
    get "/error", to: "users#show_error"

    resources :hearings, only: [:index]

    resources :users, only: [:index, :show]
    if ApplicationController.dependencies_faked?
      post "/set_user/:id", to: "users#set_user", as: "set_user"
      post "/set_end_products", to: "users#set_end_products", as: 'set_end_products'
      post "/reseed", to: "users#reseed", as: "reseed"
      get "/data", to: "users#data"
    end
    post "/log_in_as_user", to: "users#log_in_as_user", as: "log_in_as_user"
    post "/toggle_feature", to: "users#toggle_feature", as: "toggle_feature"
  end
  # :nocov:

  get "/route_docs", to: "route_docs#index"
end
