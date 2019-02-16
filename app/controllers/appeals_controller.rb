class AppealsController < ApplicationController
  include Errors

  before_action :react_routed
  before_action :set_application, only: [:document_count, :new_documents]
  # Only whitelist endpoints VSOs should have access to.
  skip_before_action :deny_vso_access, only: [:index, :power_of_attorney, :show_case_list, :show, :veteran]

  def index
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        veteran_file_number = request.headers["HTTP_VETERAN_ID"]
        file_number_not_found_error && return unless veteran_file_number

        render json: {
          appeals: get_appeals_for_file_number(veteran_file_number),
          claim_reviews: ClaimReview.find_all_by_file_number(veteran_file_number).map(&:search_table_ui_hash)
        }
      end
    end
  end

  def show_case_list
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        caseflow_veteran_id = params[:caseflow_veteran_id]
        veteran_file_number = Veteran.find(caseflow_veteran_id).file_number

        render json: {
          appeals: get_appeals_for_file_number(veteran_file_number),
          claim_reviews: ClaimReview.find_all_by_file_number(veteran_file_number).map(&:search_table_ui_hash)
        }
      end
    end
  end

  def document_count
    if params[:cached]
      render json: { document_count: appeal.number_of_documents_from_caseflow }
      return
    end
    render json: { document_count: appeal.number_of_documents }
  rescue StandardError => e
    handle_non_critical_error("document_count", e)
  end

  def new_documents
    render json: { new_documents: appeal.new_documents_for_user(
      user: current_user,
      cached: params[:cached],
      placed_on_hold_at: params[:placed_on_hold_date]
    ) }
  rescue StandardError => e
    handle_non_critical_error("new_documents", e)
  end

  def power_of_attorney
    render json: {
      representative_type: appeal.representative_type,
      representative_name: appeal.representative_name,
      representative_address: appeal.representative_address
    }
  end

  def hearings
    log_hearings_request

    most_recently_held_hearing = appeal.hearings
      .select { |hearing| hearing.disposition.to_s == Constants.HEARING_DISPOSITION_TYPES.held }
      .max_by(&:scheduled_for)

    render json:
      if most_recently_held_hearing
        {
          held_by: most_recently_held_hearing.judge.present? ? most_recently_held_hearing.judge.full_name : "",
          viewed_by_judge: !most_recently_held_hearing.hearing_views.empty?,
          date: most_recently_held_hearing.scheduled_for,
          type: most_recently_held_hearing.readable_request_type,
          external_id: most_recently_held_hearing.external_id,
          disposition: most_recently_held_hearing.disposition
        }
      else
        {}
      end
  end

  # For legacy appeals, veteran address and birth/death dates are
  # the only data that is being pulled from BGS, the rest are from VACOLS for now
  def veteran
    render json: { veteran:
      ActiveModelSerializers::SerializableResource.new(
        appeal,
        serializer: ::WorkQueue::VeteranSerializer
      ).as_json[:data][:attributes] }
  end

  def show
    no_cache
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        id = params[:appeal_id]
        MetricsService.record("Get appeal information for ID #{id}",
                              service: :queue,
                              name: "AppealsController.show") do
          render json: { appeal: json_appeals([appeal])[:data][0] }
        end
      end
    end
  end

  helper_method :appeal, :url_appeal_uuid

  def appeal
    @appeal ||= Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def url_appeal_uuid
    params[:appeal_id]
  end

  def update
    if request_issues_update.perform!
      render json: {
        issuesBefore: request_issues_update.before_issues.map(&:ui_hash),
        issuesAfter: request_issues_update.after_issues.map(&:ui_hash)
      }
    else
      render json: { error_code: request_issues_update.error_code }, status: :unprocessable_entity
    end
  end

  private

  def log_hearings_request
    # Log requests to this endpoint to try to investigate cause addressed by this rollback:
    # https://github.com/department-of-veterans-affairs/caseflow/pull/9271
    DataDogService.increment_counter(
      metric_group: "request_counter",
      metric_name: "hearings_for_appeal",
      app_name: RequestStore[:application]
    )
  end

  def request_issues_update
    @request_issues_update ||= RequestIssuesUpdate.new(
      user: current_user,
      review: appeal,
      request_issues_data: params[:request_issues]
    )
  end

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def get_appeals_for_file_number(file_number)
    return get_vso_appeals_for_file_number(file_number) if current_user.vso_employee?

    MetricsService.record("VACOLS: Get appeal information for file_number #{file_number}",
                          service: :queue,
                          name: "AppealsController.index") do

      appeals = Appeal.where(veteran_file_number: file_number).to_a
      # rubocop:disable Lint/HandleExceptions
      begin
        appeals.concat(LegacyAppeal.fetch_appeals_by_file_number(file_number))
      rescue ActiveRecord::RecordNotFound
      end
      # rubocop:enable Lint/HandleExceptions

      json_appeals(appeals)[:data]
    end
  end

  def get_vso_appeals_for_file_number(file_number)
    return file_access_prohibited_error if !BGSService.new.can_access?(file_number)

    MetricsService.record("VACOLS: Get vso appeals information for file_number #{file_number}",
                          service: :queue,
                          name: "AppealsController.get_vso_appeals_for_file_number") do
      vso_participant_ids = current_user.vsos_user_represents.map { |poa| poa[:participant_id] }

      veteran = Veteran.find_by(file_number: file_number)

      appeals = if veteran
                  veteran.accessible_appeals_for_poa(vso_participant_ids)
                else
                  []
                end

      json_appeals(appeals)[:data]
    end
  end

  def file_access_prohibited_error
    render json: {
      "errors": [
        "title": "Access to Veteran file prohibited",
        "detail": "User is prohibited from accessing files associated with provided Veteran ID"
      ]
    }, status: :forbidden
  end

  def file_number_not_found_error
    render json: {
      "errors": [
        "title": "Must include Veteran ID",
        "detail": "Veteran ID should be included as HTTP_VETERAN_ID element of request headers"
      ]
    }, status: :bad_request
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      user: current_user
    ).as_json
  end
end
