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
    @@results_per_page = 15
    @params = params.permit(
      :appeals_id, :event_type, :status, :notification_type, :recipient_info, :page
    )
    results = get_notifications_from_params(@params)
    render json: results
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
    return not_found if appeal.is_a?(LegacyAppeal)
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

  # Purpose: Queries Notification with query params and returns all Notification objects that match,
  # total number of pages, and current page number
  #
  # Params: appeal_id (vacols_id OR uuid), event_type, notification_type. email_notification_status,
  # sms_notification_status, recipient_phone_number, recipient_email
  #
  # Response: Returns an array of all retrieved Notification objects, the total number of pages needed to display those
  # objects, and the current page number
  def get_notifications_from_params(params)
    # Retrieve notifications based on query parameters and current page
    @notifications = Notification.where(appeals_id: params[:appeals_id])
    @queried_notifications = @notifications.where(params.to_h.except(:appeals_id, :recipient_info, :status, :page))

    if params[:recipient_info].present?
      recipient_email = @queried_notifications.where(recipient_email: params[:recipient_info])
      recipient_phone_number = @queried_notifications.where(recipient_phone_number: params[:recipient_info])
    end

    if params[:status].present?
      email_notification_status = @queried_notifications.where(email_notification_status: params[:status])
      sms_notification_status = @queried_notifications.where(sms_notification_status: params[:status])
    end

    if recipient_email != [] && params[:recipient_info].present?
      @queried_notifications = @queried_notifications.where(recipient_email: params[:recipient_info])
    end

    if recipient_phone_number != [] && params[:recipient_info].present?
      @queried_notifications = @queried_notifications.where(recipient_phone_number: params[:recipient_info])
    end

    if email_notification_status != [] && params[:status].present?
      @email_status = @queried_notifications.where(email_notification_status: params[:status])
    end

    if sms_notification_status != [] && params[:status].present?
      @sms_status = @queried_notifications.where(sms_notification_status: params[:status])
    end

    if sms_notification_status != [] && email_notification_status != [] && params[:status].present?
      @queried_notifications = @email_status.merge(@sms_status).uniq
    end

    # Throw 'Record Not Found' if no notifications could be retrieved
    if @queried_notifications == []
      fail ActiveRecord::RecordNotFound, params[:appeals_id]
    end

    # Get all selectable options that notifications can be filtered by
    event_types = @notifications.map(&:event_type).uniq.compact
    notification_types = @notifications.map(&:notification_type).uniq.compact
    recipient_info = (@notifications.map(&:recipient_phone_number) +
     @notifications.map(&:recipient_email)).uniq.select! { |element| element&.size.to_i > 0 }
    statuses = (@notifications.map(&:email_notification_status) +
     @notifications.map(&:sms_notification_status)).uniq.select! { |element| element&.size.to_i > 0 }

    # Calculate the total number of pages needed to display all notifications
    if @queried_notifications.count < 1
      pages_count = 1
    else
      pages_count = (@queried_notifications.count/@@results_per_page.to_f).ceil
    end

    # Default to 1st page if query parameter asks for results on a page number that exceeds pages_count
    if params[:page].to_i < (pages_count + 1)
      current_page = params[:page].try(:to_i) || 1
    else
      current_page = 1
    end

    # Add all retrieved notifications for the current page to an array
    current_page_notifications = []
    index = (@@results_per_page * current_page) - @@results_per_page
    max_index = current_page == pages_count ? index + (@queried_notifications.count - index) : index + @@results_per_page
    while index < max_index
      current_page_notifications.push(@queried_notifications[index])
      index += 1
    end

    # Return a serialized response of all notifications, total number of pages needed to display those notifications,
    # and current page number
    response = {
      notifications: WorkQueue::NotificationSerializer.new(current_page_notifications),
      selectable_event_types: event_types,
      selectable_notification_types: notification_types,
      selectable_recipient_info: recipient_info ? recipient_info : [],
      selectable_statuses: statuses ? statuses : [],
      current_page: current_page,
      total_pages: pages_count
    }
  end
end
