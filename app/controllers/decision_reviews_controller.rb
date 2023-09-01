# frozen_string_literal: true

class DecisionReviewsController < ApplicationController
  include GenericTaskPaginationConcern
  include UpdatePOAConcern

  before_action :verify_access, :react_routed, :set_application
  before_action :verify_veteran_record_access, only: [:show]

  delegate :incomplete_tasks,
           :incomplete_tasks_type_counts,
           :incomplete_tasks_issue_type_counts,
           :in_progress_tasks,
           :in_progress_tasks_type_counts,
           :in_progress_tasks_issue_type_counts,
           :completed_tasks,
           :completed_tasks_type_counts,
           :completed_tasks_issue_type_counts,
           :included_tabs,
           to: :business_line

  SORT_COLUMN_MAPPINGS = {
    "claimantColumn" => "claimant_name",
    "veteranParticipantIdColumn" => "veteran_participant_id",
    "veteranSsnColumn" => "veteran_ssn",
    "issueCountColumn" => "issue_count",
    "issueTypesColumn" => "issue_types_lower",
    "daysWaitingColumn" => "tasks.assigned_at",
    "completedDateColumn" => "tasks.closed_at"
  }.freeze

  def index
    if business_line
      respond_to do |format|
        format.html { render "index" }
        format.csv do
          jobs_as_csv = BusinessLineReporter.new(business_line).as_csv
          filename = Time.zone.now.strftime("#{business_line.url}-%Y%m%d.csv")
          send_data jobs_as_csv, filename: filename
        end
        format.json { queue_tasks }
      end
    else
      # TODO: make index show error message
      render json: { error: "#{business_line_slug} not found" }, status: :not_found
    end
  end

  def show
    if task
      render "show"
    else
      render json: { error: "Task #{task_id} not found" }, status: :not_found
    end
  end

  def update
    if task
      if task.complete_with_payload!(decision_issue_params, decision_date)
        business_line.tasks.reload
        render json: { task_filter_details: task_filter_details }, status: :ok
      else
        error = StandardError.new(task.error_code)
        Raven.capture_exception(error, extra: { error_uuid: error_uuid })
        render json: { error_uuid: error_uuid, error_code: task.error_code }, status: :bad_request
      end
    else
      render json: { error: "Task #{task_id} not found" }, status: :not_found
    end
  end

  def business_line_slug
    allowed_params[:business_line_slug] || allowed_params[:decision_review_business_line_slug]
  end

  def task_id
    allowed_params[:task_id]
  end

  def task
    @task ||= Task.includes([:appeal, :assigned_to]).find(task_id)
  end

  def business_line
    @business_line ||= BusinessLine.find_by(url: business_line_slug)
  end

  def task_filter_details
    task_filter_hash = {}
    included_tabs.each do |tab_name|
      case tab_name
      when :incomplete
        task_filter_hash[:incomplete] = incomplete_tasks_type_counts
        task_filter_hash[:incomplete_issue_types] = incomplete_tasks_issue_type_counts
      when :in_progress
        task_filter_hash[:in_progress] = in_progress_tasks_type_counts
        task_filter_hash[:in_progress_issue_types] = in_progress_tasks_issue_type_counts
      when :completed
        task_filter_hash[:completed] = completed_tasks_type_counts
        task_filter_hash[:completed_issue_types] = completed_tasks_issue_type_counts
      else
        fail NotImplementedError "Tab name type not implemented for this business line: #{business_line}"
      end
    end
    task_filter_hash
  end

  def business_line_config_options
    {
      tabs: included_tabs
    }
  end

  helper_method :task_filter_details, :business_line, :task, :business_line_config_options

  def power_of_attorney
    render json: power_of_attorney_data
  end

  def update_power_of_attorney
    appeal = task.appeal
    update_poa_information(appeal)
  rescue StandardError => error
    render_error(error)
  end

  private

  def decision_date
    return unless task.instance_of? DecisionReviewTask

    Date.parse(allowed_params.require("decision_date")).to_datetime
  end

  def decision_issue_params
    return unless task.instance_of? DecisionReviewTask

    allowed_params.require("decision_issues").map do |decision_issue_param|
      decision_issue_param.permit(:request_issue_id, :disposition, :description)
    end
  end

  def queue_tasks
    tab_name = allowed_params[Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM.to_sym]

    sort_by_column = SORT_COLUMN_MAPPINGS[allowed_params[Constants.QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM.to_sym]]

    tasks = case tab_name
            when "incomplete" then incomplete_tasks(pagination_query_params(sort_by_column))
            when "in_progress" then in_progress_tasks(pagination_query_params(sort_by_column))
            when "completed" then completed_tasks(pagination_query_params(sort_by_column))
            when nil
              return missing_tab_parameter_error
            else
              return unrecognized_tab_name_error
            end

    render json: pagination_json(tasks)
  end

  def missing_tab_parameter_error
    render json: { error: "'tab' parameter is required." }, status: :bad_request
  end

  def unrecognized_tab_name_error
    render json: { error: "Tab name provided could not be found" }, status: :not_found
  end

  def set_application
    RequestStore.store[:application] = "decision_reviews"
  end

  # TODO: authz rules for this space
  def verify_access
    return false unless business_line
    return true if current_user.admin?
    return true if current_user.can?("Admin Intake")
    return true if business_line.user_has_access?(current_user)

    Rails.logger.info("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end

  def verify_veteran_record_access
    if task.type == VeteranRecordRequest.name && !task.appeal.veteran&.accessible?
      render(Caseflow::Error::ActionForbiddenError.new(
        message: COPY::ACCESS_DENIED_TITLE
      ).serialize_response)
    end
  end

  def allowed_params
    params.permit(
      :decision_review_business_line_slug,
      :decision_review,
      :decision_date,
      :business_line_slug,
      :task_id,
      :tab,
      :sort_by,
      :order,
      :search_query,
      { filter: [] },
      :page,
      decision_issues: [:description, :disposition, :request_issue_id]
    )
  end

  def power_of_attorney_data
    {
      representative_type: task.appeal&.representative_type,
      representative_name: task.appeal&.representative_name,
      representative_address: task.appeal&.representative_address,
      representative_email_address: task.appeal&.representative_email_address,
      representative_tz: task.appeal&.representative_tz,
      poa_last_synced_at: task.appeal&.poa_last_synced_at
    }
  end
end
