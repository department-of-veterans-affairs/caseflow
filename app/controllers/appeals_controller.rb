# frozen_string_literal: true

class AppealsController < ApplicationController
  before_action :react_routed
  before_action :set_application, only: [:document_count, :power_of_attorney]
  # Only whitelist endpoints VSOs should have access to.
  skip_before_action :deny_vso_access, only: [:index, :power_of_attorney, :show_case_list, :show, :veteran, :hearings]

  def index
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        veteran_file_number = request.headers["HTTP_VETERAN_ID"]

        result = CaseSearchResultsForVeteranFileNumber.new(
          file_number_or_ssn: veteran_file_number, user: current_user
        ).call

        render_search_results_as_json(result)
      end
    end
  end

  def show_case_list
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        result = CaseSearchResultsForCaseflowVeteranId.new(
          caseflow_veteran_ids: params[:veteran_ids]&.split(","), user: current_user
        ).call

        render_search_results_as_json(result)
      end
    end
  end

  def document_count
    render json: { document_count: EFolderService.document_count(appeal.veteran_file_number, current_user) }
  rescue Caseflow::Error::EfolderAccessForbidden => error
    render(error.serialize_response)
  rescue StandardError => error
    handle_non_critical_error("document_count", error)
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
    render json: {
      veteran: ::WorkQueue::VeteranSerializer.new(appeal).serializable_hash[:data][:attributes]
    }
  end

  def show
    no_cache
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        if BGSService.new.can_access?(appeal.veteran_file_number)
          id = params[:appeal_id]
          MetricsService.record("Get appeal information for ID #{id}",
                                service: :queue,
                                name: "AppealsController.show") do
            render json: { appeal: json_appeals(appeal)[:data] }
          end
        else
          render_access_error
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
      set_flash_success_message

      render json: {
        beforeIssues: request_issues_update.before_issues.map(&:ui_hash),
        afterIssues: request_issues_update.after_issues.map(&:ui_hash),
        withdrawnIssues: request_issues_update.withdrawn_issues.map(&:ui_hash)
      }
    else
      render json: { error_code: request_issues_update.error_code }, status: :unprocessable_entity
    end
  end

  private

  # :reek:DuplicateMethodCall { allow_calls: ['result.extra'] }
  # :reek:FeatureEnvy
  def render_search_results_as_json(result)
    if result.success?
      render json: result.extra[:search_results]
    else
      render json: result.to_h, status: result.extra[:status]
    end
  end

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

  def json_appeals(appeal)
    if appeal.is_a?(Appeal)
      WorkQueue::AppealSerializer.new(appeal, params: { user: current_user }).serializable_hash
    elsif appeal.is_a?(LegacyAppeal)
      WorkQueue::LegacyAppealSerializer.new(appeal, params: { user: current_user }).serializable_hash
    end
  end

  def review_removed_message
    claimant_name = appeal.veteran_full_name
    "You have successfully removed #{appeal.class.review_title} for #{claimant_name}
    (ID: #{appeal.veteran_file_number})."
  end

  def review_withdrawn_message
    "You have successfully withdrawn a review."
  end

  def withdrawn_issues
    withdrawn = request_issues_update.withdrawn_issues

    return if withdrawn.empty?

    "withdrawn #{withdrawn.count} #{'issue'.pluralize(withdrawn.count)}"
  end

  def added_issues
    new_issues = request_issues_update.after_issues - request_issues_update.before_issues
    return if new_issues.empty?

    "added #{new_issues.count} #{'issue'.pluralize(new_issues.count)}"
  end

  def removed_issues
    removed = request_issues_update.before_issues - request_issues_update.after_issues

    return if removed.empty?

    "removed #{removed.count} #{'issue'.pluralize(removed.count)}"
  end

  def review_edited_message
    "You have successfully " + [added_issues, removed_issues, withdrawn_issues].compact.to_sentence + "."
  end

  def set_flash_success_message
    flash[:edited] = if request_issues_update.after_issues.empty?
                       review_removed_message
                     elsif (request_issues_update.after_issues - request_issues_update.withdrawn_issues).empty?
                       review_withdrawn_message
                     else
                       review_edited_message
                     end
  end

  def render_access_error
    render(Caseflow::Error::ActionForbiddenError.new(
      message: access_error_message
    ).serialize_response)
  end

  def access_error_message
    appeal.veteran.multiple_phone_numbers? ? COPY::DUPLICATE_PHONE_NUMBER_TITLE : COPY::ACCESS_DENIED_TITLE
  end
end
