# frozen_string_literal: true

class WorkQueue::AppealSearchSerializer
  include FastJsonapi::ObjectSerializer
  extend Helpers::AppealHearingHelper

  set_type :appeal

  RESTRICTED_STATUSES =
    [
      :distributed_to_judge,
      :ready_for_signature,
      :on_hold,
      :misc,
      :unknown,
      :assigned_to_attorney
    ].freeze

  attribute :contested_claim, &:contested_claim?

  attribute :mst, &:mst?

  attribute :pact, &:pact?

  attribute :issues do |object|
    object.request_issues.active_or_decided_or_withdrawn.includes(:remand_reasons).map do |issue|
      {
        id: issue.id,
        program: issue.benefit_type,
        description: issue.description,
        notes: issue.notes,
        diagnostic_code: issue.contested_rating_issue_diagnostic_code,
        remand_reasons: issue.remand_reasons,
        closed_status: issue.closed_status,
        decision_date: issue.decision_date,
        mst_status: FeatureToggle.enabled?(:mst_identification) ? issue.mst_status : false,
        pact_status: FeatureToggle.enabled?(:pact_identification) ? issue.pact_status : false,
        mst_justification: issue&.mst_status_update_reason_notes,
        pact_justification: issue&.pact_status_update_reason_notes
      }
    end
  end

  attribute :status

  attribute :decision_issues do |object, params|
    if params[:user].nil?
      fail Caseflow::Error::MissingRequiredProperty, message: "Params[:user] is required"
    end

    decision_issues = AppealDecisionIssuesPolicy.new(appeal: object, user: params[:user]).visible_decision_issues
    decision_issues.uniq.map do |issue|
      {
        id: issue.id,
        disposition: issue.disposition,
        description: issue.description,
        benefit_type: issue.benefit_type,
        remand_reasons: issue.remand_reasons,
        diagnostic_code: issue.diagnostic_code,
        request_issue_ids: issue.request_decision_issues.pluck(:request_issue_id),
        mst_status: FeatureToggle.enabled?(:mst_identification) ? issue.mst_status : false,
        pact_status: FeatureToggle.enabled?(:pact_identification) ? issue.pact_status : false
      }
    end
  end

  attribute(:hearings) do |object, params|
    # For substitution appeals after death dismissal, we need to show hearings from the source appeal
    # in addition to those on the new/target appeal; this avoids copying them to new appeal stream
    associated_hearings = []

    if object.separate_appeal_substitution?
      associated_hearings = hearings(object.appellant_substitution.source_appeal, params)
    end

    associated_hearings + hearings(object, params)
  end

  attribute :withdrawn, &:withdrawn?

  attribute :overtime, &:overtime?

  attribute :veteran_appellant_deceased, &:veteran_appellant_deceased?

  attribute :assigned_to_location do |object, params|
    if RESTRICTED_STATUSES.include?(object&.status&.status)
      unless params[:user]&.vso_employee?
        object.assigned_to_location
      end
    # if not in a restricted status, show assigned location to all users
    else
      object.assigned_to_location
    end
  end

  attribute :distributed_to_a_judge, &:distributed_to_a_judge?

  attribute :appellant_full_name do |object|
    object.claimant&.name
  end

  attribute :appellant_first_name do |object|
    object.claimant&.first_name
  end

  attribute :appellant_middle_name do |object|
    object.claimant&.middle_name
  end

  attribute :appellant_last_name do |object|
    object.claimant&.last_name
  end

  attribute :appellant_suffix do |object|
    object.claimant&.suffix
  end

  attribute :veteran_death_date

  attribute :veteran_file_number

  attribute :veteran_full_name do |object|
    object.veteran ? object.veteran.name.formatted(:readable_full) : "Cannot locate"
  end

  attribute :closest_regional_office

  attribute :closest_regional_office_label

  attribute :external_id, &:uuid

  attribute :type
  attribute :vacate_type
  attribute :aod, &:advanced_on_docket?
  attribute :docket_name
  attribute :docket_number
  attribute :docket_range_date
  attribute :decision_date
  attribute :nod_date, &:receipt_date
  attribute :withdrawal_date

  attribute :paper_case do
    false
  end

  attribute :regional_office do
  end

  attribute :caseflow_veteran_id do |object|
    object.veteran ? object.veteran.id : nil
  end

  attribute :readable_hearing_request_type, &:readable_current_hearing_request_type

  attribute :readable_original_hearing_request_type, &:readable_original_hearing_request_type
end
