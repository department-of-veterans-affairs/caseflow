class AppealsController < ApplicationController
  include Errors

  before_action :react_routed
  before_action :set_application, only: [:document_count, :new_documents]

  ROLES = Constants::USER_ROLE_TYPES.keys.freeze

  def index
    get_appeals_for_file_number(request.headers["HTTP_VETERAN_ID"]) && return
  end

  def show_case_list
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        return get_appeals_for_file_number(Veteran.find(params[:caseflow_veteran_id]).file_number)
      end
    end
  end

  def document_count
    render json: { document_count: appeal.number_of_documents }
  rescue StandardError => e
    return handle_non_critical_error("document_count", e)
  end

  def new_documents
    render json: { new_documents: appeal.new_documents_for_user(current_user) }
  rescue StandardError => e
    return handle_non_critical_error("new_documents", e)
  end

  def tasks
    no_cache

    role = params[:role].downcase
    return invalid_role_error unless ROLES.include?(role)

    if %w[attorney judge].include?(role) && appeal.class == LegacyAppeal
      return json_tasks_by_legacy_appeal_id_and_role(params[:appeal_id], role)
    end

    json_tasks_by_appeal_id(appeal.id)
  end

  def show
    no_cache

    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        id = params[:id]
        MetricsService.record("Get appeal information for ID #{id}",
                              service: :queue,
                              name: "AppealsController.show") do
          appeal = Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(id)
          render json: { appeal: json_appeals([appeal])[:data][0] }
        end
      end
    end
  end

  private

  def set_application
    RequestStore.store[:application] = "queue"
  end

  # https://stackoverflow.com/a/748646
  def no_cache
    # :nocov:
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    # :nocov:
  end

  def get_appeals_for_file_number(file_number)
    return file_number_not_found_error unless file_number

    MetricsService.record("VACOLS: Get appeal information for file_number #{file_number}",
                          service: :queue,
                          name: "AppealsController.index") do

      appeals = []
      if FeatureToggle.enabled?(:queue_beaam_appeals, user: current_user)
        appeals.concat(Appeal.where(veteran_file_number: file_number).to_a)
      end
      # rubocop:disable Lint/HandleExceptions
      begin
        appeals.concat(LegacyAppeal.fetch_appeals_by_file_number(file_number))
      rescue ActiveRecord::RecordNotFound
      end
      # rubocop:enable Lint/HandleExceptions

      render json: {
        appeals: json_appeals(appeals)[:data]
      }
    end
  end

  def appeal
    @appeal ||= Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def file_number_not_found_error
    render json: {
      "errors": [
        "title": "Must include Veteran ID",
        "detail": "Veteran ID should be included as HTTP_VETERAN_ID element of request headers"
      ]
    }, status: 400
  end

  def queue_class
    TasksController::QUEUES[params[:role].downcase.try(:to_sym)]
  end

  def json_tasks_by_appeal_id(appeal_db_id)
    tasks = queue_class.new.tasks_by_appeal_id(appeal_db_id)

    render json: {
      tasks: json_tasks(tasks)[:data]
    }
  end

  def json_tasks_by_legacy_appeal_id_and_role(appeal_id, role)
    tasks, = LegacyWorkQueue.tasks_with_appeals_by_appeal_id(appeal_id, role)

    render json: {
      tasks: json_legacy_tasks(tasks)[:data]
    }
  end

  def handle_non_critical_error(endpoint, err)
    if !err.class.method_defined? :serialize_response
      code = (err.class == ActiveRecord::RecordNotFound) ? 404 : 500
      err = Caseflow::Error::SerializableError.new(code: code, message: err.to_s)
    end

    DataDogService.increment_counter(
      metric_group: "errors",
      metric_name: "non_critical",
      app_name: RequestStore[:application],
      attrs: {
        endpoint: endpoint
      }
    )

    render err.serialize_response
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals
    ).as_json
  end

  def json_legacy_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      tasks,
      each_serializer: ::WorkQueue::LegacyTaskSerializer
    ).as_json
  end

  def json_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      tasks,
      each_serializer: ::WorkQueue::TaskSerializer
    ).as_json
  end
end
