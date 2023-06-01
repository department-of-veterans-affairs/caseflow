# frozen_string_literal: true

class WorkQueue::LegacyAppealSerializer
  include FastJsonapi::ObjectSerializer
  extend Helpers::AppealHearingHelper

  attribute :assigned_attorney
  attribute :assigned_judge

  attribute :readable_hearing_request_type, &:readable_current_hearing_request_type

  attribute :readable_original_hearing_request_type, &:readable_original_hearing_request_type

  attribute :issues do |object|
    object.issues.map do |issue|
      WorkQueue::LegacyIssueSerializer.new(issue).serializable_hash[:data][:attributes]
    end
  end

  attribute :hearings do |object, params|
    hearings(object, params)
  end

  attribute :completed_hearing_on_previous_appeal?

  attribute :appellant_is_not_veteran, &:appellant_is_not_veteran

  attribute :appellant_full_name, &:appellant_name

  attribute :appellant_address, &:appellant_address

  attribute :appellant_tz, &:appellant_tz

  attribute :appellant_relationship
  attribute :assigned_to_location
  attribute :vbms_id, &:sanitized_vbms_id
  attribute :veteran_full_name
  attribute :veteran_death_date
  attribute :veteran_appellant_deceased, &:veteran_appellant_deceased?
  # Aliasing the vbms_id to make it clear what we're returning.
  attribute :veteran_file_number, &:sanitized_vbms_id
  attribute :veteran_participant_id do |object|
    object&.veteran&.participant_id
  end
  attribute :efolder_link do
    ENV["CLAIM_EVIDENCE_EFOLDER_BASE_URL"]
  end
  attribute :external_id, &:vacols_id
  attribute :type
  attribute :aod
  attribute :docket_number
  attribute :docket_range_date, &:docket_date
  attribute :status
  attribute :decision_date
  attribute :form9_date
  attribute :nod_date
  attribute :certification_date
  attribute :paper_case, &:paper_case?
  attribute :overtime, &:overtime?
  attribute :caseflow_veteran_id do |object|
    object.veteran ? object.veteran.id : nil
  end

  attribute :closest_regional_office

  attribute :closest_regional_office_label

  attribute :mst, &:mst?

  attribute :pact, &:pact?

  attribute(:available_hearing_locations) { |object| available_hearing_locations(object) }

  attribute :docket_name do
    "legacy"
  end

  attribute :regional_office do |object|
    {
      key: object.regional_office&.key,
      city: object.regional_office&.city,
      state: object.regional_office&.state
    }
  end

  attribute :document_id do |object|
    latest_vacols_attorney_case_review(object)&.document_id
  end

  attribute :can_edit_document_id do |object, params|
    LegacyDocumentIdPolicy.new(
      user: params[:user],
      case_review: latest_vacols_attorney_case_review(object)
    ).editable?
  end

  attribute :can_edit_request_issues do |object, params|
    AppealRequestIssuesPolicy.new(user: params[:user], appeal: object).editable?
  end

  attribute :attorney_case_review_id do |object|
    latest_vacols_attorney_case_review(object)&.vacols_id
  end

  attribute :current_user_email do |_, params|
    params[:user]&.email
  end

  attribute :current_user_timezone do |_, params|
    params[:user]&.timezone
  end

  attribute :has_notifications do |object|
    @all_notifications = Notification.where(appeals_id: object.vacols_id.to_s, appeals_type: "LegacyAppeal")
    @allowed_notifications = @all_notifications.where(email_notification_status: nil)
      .or(@all_notifications.where.not(email_notification_status: ["No Participant Id Found", "No Claimant Found", "No External Id"]))
      .merge(@all_notifications.where(sms_notification_status: nil)
      .or(@all_notifications.where.not(sms_notification_status: ["No Participant Id Found", "No Claimant Found", "No External Id"]))).any?
  end

  attribute :location_history do |object|
    object.location_history.map do |location|
      WorkQueue::PriorlocSerializer.new(location).serializable_hash[:data][:attributes]
    end
  end

  def self.latest_vacols_attorney_case_review(object)
    VACOLS::CaseAssignment.latest_task_for_appeal(object.vacols_id)
  end
end
