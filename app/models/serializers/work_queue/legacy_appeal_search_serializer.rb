# frozen_string_literal: true

class WorkQueue::LegacyAppealSearchSerializer
  include FastJsonapi::ObjectSerializer
  extend Helpers::AppealHearingHelper

  set_type :legacy_appeal

  attribute :assigned_attorney
  attribute :assigned_judge

  attribute :issues do |object|
    object.issues.map do |issue|
      WorkQueue::LegacyIssueSerializer.new(issue).serializable_hash[:data][:attributes]
    end
  end

  attribute :readable_hearing_request_type, &:readable_current_hearing_request_type

  attribute :readable_original_hearing_request_type, &:readable_original_hearing_request_type

  attribute :hearings do |object, params|
    hearings(object, params)
  end

  attribute :completed_hearing_on_previous_appeal?

  attribute :appellant_full_name, &:appellant_name

  attribute :assigned_to_location
  attribute :vbms_id, &:sanitized_vbms_id
  attribute :veteran_full_name
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

  attribute :mst, &:mst?

  attribute :pact, &:pact?

  attribute(:available_hearing_locations) { |object| available_hearing_locations(object) }

  attribute :docket_name do
    "legacy"
  end

  attribute :current_user_email do |_, params|
    params[:user]&.email
  end

  attribute :current_user_timezone do |_, params|
    params[:user]&.timezone
  end

  attribute :location_history do |object|
    object.location_history.map do |location|
      WorkQueue::PriorlocSerializer.new(location).serializable_hash[:data][:attributes]
    end
  end
end
