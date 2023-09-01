# frozen_string_literal: true

class AppealsController < ApplicationController
  include UpdatePOAConcern
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
    update_poa_information(appeal)
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
    return not_found if appeal.is_a?(LegacyAppeal) &&
                        !FeatureToggle.enabled?(:legacy_mst_pact_identification, user: RequestStore[:current_user])
  end

  helper_method :appeal, :url_appeal_uuid

  def appeal
    @appeal ||= Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def url_appeal_uuid
    params[:appeal_id]
  end

  def update
    if appeal.is_a?(LegacyAppeal) &&
       FeatureToggle.enabled?(:legacy_mst_pact_identification, user: RequestStore[:current_user])
      legacy_mst_pact_updates
    elsif request_issues_update.perform!
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
    # if cc appeal, create SendInitialNotificationLetterTask
    if appeal.contested_claim? && FeatureToggle.enabled?(:cc_appeal_workflow)
      # check if an existing letter task is open
      existing_letter_task_open = appeal.tasks.any? do |task|
        task.class == SendInitialNotificationLetterTask && task.status == "assigned"
      end
      # create SendInitialNotificationLetterTask unless one is open
      send_initial_notification_letter unless existing_letter_task_open
    end
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
    COPY::CLAIM_REVIEW_WITHDRAWN_MESSAGE
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

  # check if changes in params
  def mst_pact_changes?
    request_issues_update.mst_edited_issues.any? || request_issues_update.pact_edited_issues.any?
  end

  # format MST/PACT edit success banner message
  def mst_and_pact_edited_issues
    # list of edit counts
    mst_added = 0
    mst_removed = 0
    pact_added = 0
    pact_removed = 0
    # get edited issues from params and reject new issues without id
    if !appeal.is_a?(LegacyAppeal)
      existing_issues = params[:request_issues].reject { |i| i[:request_issue_id].nil? }

      # get added issues
      new_issues = request_issues_update.after_issues - request_issues_update.before_issues
      # get removed issues
      removed_issues = request_issues_update.before_issues - request_issues_update.after_issues

      # calculate edits
      existing_issues.each do |issue_edit|
        # find the original issue and compare MST/PACT changes
        before_issue = request_issues_update.before_issues.find { |i| i.id == issue_edit[:request_issue_id].to_i }

        # increment edit counts if they meet the criteria for added/removed
        mst_added += 1 if issue_edit[:mst_status] != before_issue.mst_status && issue_edit[:mst_status]
        mst_removed += 1 if issue_edit[:mst_status] != before_issue.mst_status && !issue_edit[:mst_status]
        pact_added += 1 if issue_edit[:pact_status] != before_issue.pact_status && issue_edit[:pact_status]
        pact_removed += 1 if issue_edit[:pact_status] != before_issue.pact_status && !issue_edit[:pact_status]
      end
    else
      existing_issues = legacy_issue_params[:request_issues]
      existing_issues.each do |issue_edit|
        mst_added += 1 if legacy_issues_with_updated_mst_pact_status[:mst_edited].include?(issue_edit) && issue_edit[:mst_status]
        mst_removed += 1 if legacy_issues_with_updated_mst_pact_status[:mst_edited].include?(issue_edit) && !issue_edit[:mst_status]
        pact_added += 1 if legacy_issues_with_updated_mst_pact_status[:pact_edited].include?(issue_edit) && issue_edit[:pact_status]
        pact_removed += 1 if legacy_issues_with_updated_mst_pact_status[:pact_edited].include?(issue_edit) && !issue_edit[:pact_status]
        new_issues = []
        removed_issues = []
      end
    end

    # return if no edits, removals, or additions
    return if (mst_added + mst_removed + pact_added + pact_removed == 0) && removed_issues.empty? && new_issues.empty?

    message = []

    message << "#{pact_removed} #{'issue'.pluralize(pact_removed)} unmarked as PACT" unless pact_removed == 0
    message << "#{mst_removed} #{'issue'.pluralize(mst_removed)} unmarked as MST" unless mst_removed == 0
    message << "#{mst_added} #{'issue'.pluralize(mst_added)} marked as MST" unless mst_added == 0
    message << "#{pact_added} #{'issue'.pluralize(pact_added)} marked as PACT" unless pact_added == 0

    # add in removed message and added message, if any
    message << create_mst_pact_message_for_new_and_removed_issues(new_issues, "added") unless new_issues.empty?
    message << create_mst_pact_message_for_new_and_removed_issues(removed_issues, "removed") unless removed_issues.empty?

    message.flatten
  end

  # create MST/PACT message for added/removed issues
  def create_mst_pact_message_for_new_and_removed_issues(issues, type)
    special_issue_message = []
    # check if any added/removed issues have MST/PACT and get the count
    mst_count = issues.count { |issue| issue.mst_status && !issue.pact_status }
    pact_count = issues.count { |issue| issue.pact_status && !issue.mst_status }
    both_count = issues.count { |issue| issue.pact_status && issue.mst_status }
    none_count = issues.count { |issue| !issue.pact_status && !issue.mst_status }

    special_issue_message << "#{mst_count} #{'issue'.pluralize(mst_count)} with MST #{type}" unless mst_count == 0
    special_issue_message << "#{pact_count} #{'issue'.pluralize(pact_count)} with PACT #{type}" unless pact_count == 0
    special_issue_message << "#{both_count} #{'issue'.pluralize(both_count)} with MST and PACT #{type}" unless both_count == 0
    special_issue_message << "#{none_count} #{'issue'.pluralize(none_count)} #{type}" unless none_count == 0

    special_issue_message
  end

  # check if there is a change in mst/pact on legacy issue
  # if there is a change, creat an issue update task
  def legacy_mst_pact_updates
    legacy_issue_params[:request_issues].each do |current_issue|
      issue = appeal.issues.find { |i| i.vacols_sequence_id == current_issue[:vacols_sequence_id].to_i }

      # Check for changes in mst/pact status
      if issue.mst_status != current_issue[:mst_status] || issue.pact_status != current_issue[:pact_status]
        # If there is a change :
        # Create issue_update_task to populate casetimeline if there is a change
        create_legacy_issue_update_task(issue, current_issue)

        # Grab record from Vacols database to issue.
        # When updating an Issue, method in IssueMapper and IssueRepo requires the attrs show below in issue_attrs:{}
        record = VACOLS::CaseIssue.find_by(isskey: appeal.vacols_id, issseq: current_issue[:vacols_sequence_id])
        Issue.update_in_vacols!(
          vacols_id: appeal.vacols_id,
          vacols_sequence_id: current_issue[:vacols_sequence_id],
          issue_attrs: {
            mst_status: current_issue[:mst_status] ? "Y" : "N",
            pact_status: current_issue[:pact_status] ? "Y" : "N",
            program: record[:issprog],
            issue: record[:isscode],
            level_1: record[:isslev1],
            level_2: record[:isslev2],
            level_3: record[:isslev3]
          }
        )
      end
    end
    set_flash_mst_edit_message
    render json: { issues: json_issues }, status: :ok
  end

  def json_issues
    appeal.issues.map do |issue|
      ::WorkQueue::LegacyIssueSerializer.new(issue).serializable_hash[:data][:attributes]
    end
  end

  def legacy_issues_with_updated_mst_pact_status
    mst_edited = legacy_issue_params[:request_issues].find_all do |current_issue|
      issue = appeal.issues.find { |i| i.vacols_sequence_id == current_issue[:vacols_sequence_id].to_i }
      issue.mst_status != current_issue[:mst_status]
    end
    pact_edited = legacy_issue_params[:request_issues].find_all do |current_issue|
      issue = appeal.issues.find { |i| i.vacols_sequence_id == current_issue[:vacols_sequence_id].to_i }
      issue.pact_status != current_issue[:pact_status]
    end
    {mst_edited: mst_edited, pact_edited: pact_edited}
  end

  def legacy_issue_params
    # Checks the keys for each object in request_issues array
    request_issue_params = params.require("request_issues").each do |current_param|
      current_param.permit(:request_issue_id,
                           :withdrawal_date,
                           :vacols_sequence_id,
                           :mst_status,
                           :pact_status,
                           :mst_status_update_reason_notes,
                           :pact_status_update_reason_notes).to_h
    end

    # After check, recreate safe_params object and include vacols_uniq_id
    safe_params = {
      request_issues: request_issue_params,
      vacols_user_id: current_user.vacols_uniq_id
    }
    safe_params
  end

  def create_params
    legacy_issue_params.merge(vacols_id: appeal.vacols_id)
  end

  def create_legacy_issue_update_task(before_issue, current_issue)
    user = RequestStore[:current_user]

    # close out any tasks that might be open
    open_issue_task = Task.where(
      assigned_to: SpecialIssueEditTeam.singleton
    ).where(status: "assigned").where(appeal: appeal)
    open_issue_task[0].delete unless open_issue_task.empty?

    task = IssuesUpdateTask.create!(
      appeal: appeal,
      parent: appeal.root_task,
      assigned_to: SpecialIssueEditTeam.singleton,
      assigned_by: user,
      completed_by: user
    )
    # format the task instructions and close out
    task.format_instructions(
      "Edited Issue",
      [
        "Benefit Type: #{before_issue.labels[0]}\n",
        "Issue: #{before_issue.labels[1..-2].join("\n")}\n",
        "Code: #{[before_issue.codes[-1], before_issue.labels[-1]].join(" - ")}\n",
        "Note: #{before_issue.note}\n",
        "Disposition: #{before_issue.readable_disposition}\n"
      ].compact.join("\r\n"),
      "",
      before_issue.mst_status,
      before_issue.pact_status,
      current_issue[:mst_status],
      current_issue[:pact_status]
    )
    task.completed!

    # create SpecialIssueChange record to log the changes
    SpecialIssueChange.create!(
      issue_id: before_issue.id,
      appeal_id: appeal.id,
      appeal_type: "LegacyAppeal",
      task_id: task.id,
      created_at: Time.zone.now.utc,
      created_by_id: RequestStore[:current_user].id,
      created_by_css_id: RequestStore[:current_user].css_id,
      original_mst_status: before_issue.mst_status,
      original_pact_status: before_issue.pact_status,
      updated_mst_status: current_issue[:mst_status],
      updated_pact_status: current_issue[:pact_status],
      change_category: "Edited Issue"
    )
  end

  # updated flash message to show mst/pact message if mst/pact changes (not to legacy)
  def set_flash_success_message
    return set_flash_mst_edit_message if mst_pact_changes? &&
                                         (FeatureToggle.enabled?(:mst_identification, user: RequestStore[:current_user]) ||
                                         FeatureToggle.enabled?(:pact_identification, user: RequestStore[:current_user]))

    set_flash_edit_message
  end

  # create success message with added and removed issues
  def set_flash_mst_edit_message
    flash[:mst_pact_edited] = mst_and_pact_edited_issues
  end

  def set_flash_edit_message
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
