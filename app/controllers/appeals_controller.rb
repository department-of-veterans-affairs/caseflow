# frozen_string_literal: true

class AppealsController < ApplicationController
  before_action :react_routed
  before_action :set_application, only: [:document_count, :power_of_attorney, :update_power_of_attorney]
  # Only whitelist endpoints VSOs should have access to.
  skip_before_action :deny_vso_access, only: [
    :index,
    :power_of_attorney,
    :show_case_list,
    :fetch_notification_list,
    :show,
    :veteran,
    :most_recent_hearing
  ]

  def index
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        case_search = request.headers["HTTP_CASE_SEARCH"]

        result = if docket_number?(case_search)
                   CaseSearchResultsForDocketNumber.new(
                     docket_number: case_search, user: current_user
                   ).call
                 else
                   CaseSearchResultsForVeteranFileNumber.new(
                     file_number_or_ssn: case_search, user: current_user
                   ).call
                 end

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

  def fetch_notification_list
    appeals_id = params[:appeals_id]
    respond_to do |format|
      format.json do
        results = find_notifications_by_appeals_id(appeals_id)
        render json: results
      end
      format.pdf do
        request.headers["HTTP_PDF"]
        appeal = get_appeal_object(appeals_id)
        date = Time.zone.now.strftime("%Y-%m-%d %H.%M")
        begin
          if !appeal.nil?
            pdf = PdfExportService.create_and_save_pdf("notification_report_pdf_template", appeal)
            send_data pdf, filename: "Notification Report " + appeals_id + " " + date + ".pdf", type: "application/pdf", disposition: :attachment
          else
            raise ActionController::RoutingError.new('Appeal Not Found')
          end
        rescue StandardError => error
          uuid = SecureRandom.uuid
          Rails.logger.error(error.to_s + "Error ID: " + uuid)
          Raven.capture_exception(error, extra: { error_uuid: uuid })
          render json: { "errors": ["message": uuid] }, status: :internal_server_error
        end
      end
      format.csv do
        raise ActionController::ParameterMissing.new('Bad Format')
      end
      format.html do
        raise ActionController::ParameterMissing.new('Bad Format')
      end
    end
  end

  def document_count
    doc_count = EFolderService.document_count(appeal.veteran_file_number, current_user)
    status = (doc_count == ::ExternalApi::EfolderService::DOCUMENT_COUNT_DEFERRED) ? 202 : 200
    render json: { document_count: doc_count }, status: status
  rescue Caseflow::Error::EfolderAccessForbidden => error
    render(error.serialize_response)
  rescue StandardError => error
    handle_non_critical_error("document_count", error)
  end

  def power_of_attorney
    render json: power_of_attorney_data
  end

  def update_power_of_attorney
    clear_poa_not_found_cache
    if cooldown_period_remaining > 0
      render json: {
        alert_type: "info",
        message: "Information is current at this time. Please try again in #{cooldown_period_remaining} minutes",
        power_of_attorney: power_of_attorney_data
      }
    else
      message, result, status = update_or_delete_power_of_attorney!
      render json: {
        alert_type: result,
        message: message,
        power_of_attorney: (status == "updated") ? power_of_attorney_data : {}
      }
    end
  rescue StandardError => error
    render_error(error)
  end

  def most_recent_hearing
    most_recently_held_hearing = HearingsForAppeal.new(url_appeal_uuid)
      .held_hearings
      .max_by(&:scheduled_for)

    render json:
      if most_recently_held_hearing
        AppealHearingSerializer.new(most_recently_held_hearing,
                                    params: { user: current_user }).serializable_hash[:data][:attributes]
      else
        {}
      end
  end

  # For legacy appeals, veteran address and birth/death dates are
  # the only data that is being pulled from BGS, the rest are from VACOLS for now
  def veteran
    render json: {
      veteran: ::WorkQueue::VeteranSerializer.new(
        appeal,
        params: { relationships: params["relationships"] }
      ).serializable_hash[:data][:attributes]
    }
  end

  def show
    no_cache
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        if appeal.accessible?
          id = params[:appeal_id]
          MetricsService.record("Get appeal information for ID #{id}",
                                service: :queue,
                                name: "AppealsController.show") do
            appeal.appeal_views.find_or_create_by(user: current_user).update!(last_viewed_at: Time.zone.now)

            render json: { appeal: json_appeals(appeal)[:data] }
          end
        else
          render_access_error
        end
      end
    end
  end

  def edit
    # only AMA appeals may call /edit
    # this was removed for MST/PACT initiative to edit MST/PACT for legacy issues
    # return not_found if appeal.is_a?(LegacyAppeal)
  end

  helper_method :appeal, :url_appeal_uuid

  def appeal
    @appeal ||= Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def url_appeal_uuid
    params[:appeal_id]
  end

  def update
    if request_issues_update.perform!
      set_flash_success_message
      create_subtasks!

      render json: {
        beforeIssues: request_issues_update.before_issues.map(&:serialize),
        afterIssues: request_issues_update.after_issues.map(&:serialize),
        withdrawnIssues: request_issues_update.withdrawn_issues.map(&:serialize)
      }
    else
      render json: { error_code: request_issues_update.error_code }, status: :unprocessable_entity
    end
  end

  private

  def create_subtasks!
    # binding.pry
    # if cc appeal, create SendInitialNotificationLetterTask
    if appeal.contested_claim? && FeatureToggle.enabled?(:cc_appeal_workflow)
      # check if an existing letter task is open
      existing_letter_task_open = appeal.tasks.any? do |task|
        task.class == SendInitialNotificationLetterTask && task.status == "assigned"
      end
      # create SendInitialNotificationLetterTask unless one is open
      send_initial_notification_letter unless existing_letter_task_open
    end
    # params[:request_issues].each do |issue|
    #   original = request_issues_update.before_issues.find { |bi| bi.id == issue[:request_issue_id].to_i }
    #   if (request_issues_update.mst_edited_request_issue_ids + request_issues_update.pact_edited_request_issue_ids).include?(issue[:request_issue_id].to_i)
    #     create_issues_update_task(
    #       issue[:nonrating_issue_category],
    #       original.mst_status,
    #       original.pact_status,
    #       issue[:mst_status],
    #       issue[:pact_status],
    #       issue[:mst_status_update_reason_notes],
    #       issue[:pact_status_update_reason_notes]
    #       )
    #   end
    # end
  end

  # :reek:DuplicateMethodCall { allow_calls: ['result.extra'] }
  # :reek:FeatureEnvy
  def render_search_results_as_json(result)
    if result.success?
      render json: result.extra[:search_results]
    else
      render json: result.to_h, status: result.extra[:status]
    end
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
    else
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
    appeal.veteran&.multiple_phone_numbers? ? COPY::DUPLICATE_PHONE_NUMBER_TITLE : COPY::ACCESS_DENIED_TITLE
  end

  def docket_number?(search)
    !search.nil? && search.match?(/\d{6}-{1}\d+$/)
  end

  def update_or_delete_power_of_attorney!
    appeal.power_of_attorney&.try(:clear_bgs_power_of_attorney!) # clear memoization on legacy appeals
    poa = appeal.bgs_power_of_attorney

    if poa.blank?
      ["Successfully refreshed. No power of attorney information was found at this time.", "success", "blank"]
    elsif poa.bgs_record == :not_found
      poa.destroy!
      ["Successfully refreshed. No power of attorney information was found at this time.", "success", "deleted"]
    else
      poa.save_with_updated_bgs_record!
      ["POA Updated Successfully", "success", "updated"]
    end
  end

  def send_initial_notification_letter
    # depending on the docket type, create cooresponding task as parent task
    case appeal.docket_type
    when "evidence_submission"
      parent_task = @appeal.tasks.find_by(type: "EvidenceSubmissionWindowTask")
    when "hearing"
      parent_task = @appeal.tasks.find_by(type: "ScheduleHearingTask")
    when "direct_review"
      parent_task = @appeal.tasks.find_by(type: "DistributionTask")
    end
    @send_initial_notification_letter ||= @appeal.tasks.open.find_by(type: :SendInitialNotificationLetterTask) ||
                                          SendInitialNotificationLetterTask.create!(
                                            appeal: @appeal,
                                            parent: parent_task,
                                            assigned_to: Organization.find_by_url("clerk-of-the-board"),
                                            assigned_by: RequestStore[:current_user]
                                          ) unless parent_task.nil?
  end

  def create_issues_update_task(issue_category, original_mst, original_pact, edit_mst, edit_pact, mst_edit_reason, pact_edit_reason)
    task = IssuesUpdateTask.create!(
      appeal: appeal,
      parent: RootTask.find_or_create_by!(appeal: appeal),
      assigned_to: Organization.find_by_url("clerk-of-the-board"),
      assigned_by: RequestStore[:current_user]
    )
    task.format_instructions(issue_category, original_mst, original_pact, edit_mst, edit_pact, mst_edit_reason, pact_edit_reason)
    task.completed!
  end

  def power_of_attorney_data
    {
      representative_type: appeal.representative_type,
      representative_name: appeal.representative_name,
      representative_address: appeal.representative_address,
      representative_email_address: appeal.representative_email_address,
      representative_tz: appeal.representative_tz,
      poa_last_synced_at: appeal.poa_last_synced_at
    }
  end

  def clear_poa_not_found_cache
    Rails.cache.delete("bgs-participant-poa-not-found-#{appeal&.veteran&.file_number}")
    Rails.cache.delete("bgs-participant-poa-not-found-#{appeal&.claimant_participant_id}")
  end

  def cooldown_period_remaining
    next_update_allowed_at = appeal.poa_last_synced_at + 10.minutes if appeal.poa_last_synced_at.present?
    if next_update_allowed_at && next_update_allowed_at > Time.zone.now
      return ((next_update_allowed_at - Time.zone.now) / 60).ceil
    end

    0
  end

  def render_error(error)
    Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}")
    Raven.capture_exception(error, extra: { appeal_type: appeal.type, appeal_id: appeal.id })
    render json: {
      alert_type: "error",
      message: "Something went wrong"
    }, status: :unprocessable_entity
  end

  # Purpose: Fetches all notifications for an appeal
  #
  # Params: appeals_id (vacols_id OR uuid)
  #
  # Response: Returns an array of all retrieved notifications
  def find_notifications_by_appeals_id(appeals_id)
    # Retrieve notifications based on appeals_id, excluding statuses of 'No participant_id' & 'No claimant'
    @all_notifications = Notification.where(appeals_id: appeals_id)
    @allowed_notifications = @all_notifications.where(email_notification_status: nil)
      .or(@all_notifications.where.not(email_notification_status: ["No Participant Id Found", "No Claimant Found", "No External Id"]))
      .merge(@all_notifications.where(sms_notification_status: nil)
      .or(@all_notifications.where.not(sms_notification_status: ["No Participant Id Found", "No Claimant Found", "No External Id"])))
    # If no notifications were found, return an empty array, else return serialized notifications
    if @allowed_notifications == []
      []
    else
      WorkQueue::NotificationSerializer.new(@allowed_notifications).serializable_hash[:data]
    end
  end

  # Notification report pdf template only accepts the Appeal or Legacy Appeal object
  # Finds appeal object using appeals id passed through url params
  def get_appeal_object(appeals_id)
    type = Notification.find_by(appeals_id: appeals_id)&.appeals_type
    if type == "LegacyAppeal"
      LegacyAppeal.find_by(vacols_id: appeals_id)
    elsif type == "Appeal"
      Appeal.find_by(uuid: appeals_id)
    elsif !type.nil?
      nil
    end
  end
end

