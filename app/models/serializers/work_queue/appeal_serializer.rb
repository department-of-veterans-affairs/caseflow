# frozen_string_literal: true

class WorkQueue::AppealSerializer
  include FastJsonapi::ObjectSerializer
  extend Helpers::AppealHearingHelper

  attribute :assigned_attorney
  attribute :assigned_judge

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
        decision_date: issue.decision_date
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
        request_issue_ids: issue.request_decision_issues.pluck(:request_issue_id)
      }
    end
  end

  attribute :nod_date_updates do |object|
    object.nod_date_updates.map do |nod_date_update|
      WorkQueue::NodDateUpdateSerializer.new(nod_date_update).serializable_hash[:data][:attributes]
    end
  end

  attribute :can_edit_request_issues do |object, params|
    AppealRequestIssuesPolicy.new(user: params[:user], appeal: object).editable?
  end

  attribute(:hearings) { |object| hearings(object) }

  attribute :withdrawn, &:withdrawn?

  attribute :removed, &:removed?

  attribute :overtime, &:overtime?

  attribute :veteran_appellant_deceased, &:veteran_appellant_deceased?

  attribute :assigned_to_location

  attribute :distributed_to_a_judge, &:distributed_to_a_judge?

  attribute :completed_hearing_on_previous_appeal? do
    false
  end

  attribute :appellant_is_not_veteran

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
    object.claimant.is_a?(OtherClaimant) ? object.claimant&.suffix : nil
  end

  attribute :appellant_address do |object|
    object.claimant&.address
  end

  attribute :appellant_phone_number do |object|
    object.claimant.is_a?(OtherClaimant) ? object.claimant&.phone_number : nil
  end

  attribute :appellant_email_address do |object|
    object.claimant&.email_address
  end

  attribute :appellant_tz, &:appellant_tz

  attribute :appellant_relationship, &:appellant_relationship

  attribute :appellant_type do |appeal|
    appeal.claimant&.type
  end

  attribute :appellant_party_type do |appeal|
    appeal.claimant.is_a?(OtherClaimant) ? appeal.claimant&.party_type : nil
  end

  attribute :unrecognized_appellant_id do |appeal|
    appeal.claimant.is_a?(OtherClaimant) ? appeal.claimant&.unrecognized_appellant&.id : nil
  end

  attribute :cavc_remand do |object|
    if object.cavc_remand
      WorkQueue::CavcRemandSerializer.new(object.cavc_remand).serializable_hash[:data][:attributes]
    end
  end

  attribute :remand_source_appeal_id do |appeal|
    appeal.cavc_remand&.source_appeal&.uuid
  end

  attribute :remand_judge_name do |appeal|
    appeal.cavc_remand&.source_appeal&.reviewing_judge_name
  end

  attribute :appellant_substitution do |object|
    if object.appellant_substitution
      WorkQueue::AppellantSubstitutionSerializer.new(object.appellant_substitution)
        .serializable_hash[:data][:attributes]
    end
  end

  attribute :substitutions do |object|
    object.substitutions.map do |substitution|
      WorkQueue::AppellantSubstitutionSerializer.new(substitution).serializable_hash[:data][:attributes]
    end
  end

  attribute :veteran_death_date

  attribute :veteran_file_number

  attribute :veteran_full_name do |object|
    object.veteran ? object.veteran.name.formatted(:readable_full) : "Cannot locate"
  end

  attribute :closest_regional_office

  attribute :closest_regional_office_label

  attribute(:available_hearing_locations) { |object| available_hearing_locations(object) }

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

  attribute :certification_date do
    nil
  end

  attribute :paper_case do
    false
  end

  attribute :regional_office do
  end

  attribute :caseflow_veteran_id do |object|
    object.veteran ? object.veteran.id : nil
  end

  attribute :document_id do |object|
    object.latest_attorney_case_review&.document_id
  end

  attribute :attorney_case_review_id do |object|
    object.latest_attorney_case_review&.id
  end

  attribute :attorney_case_rewrite_details do |object|
    if FeatureToggle.enabled?(:overtime_revamp, user: RequestStore.store[:current_user])
      {
        note_from_attorney: object.latest_attorney_case_review&.note,
        untimely_evidence: object.latest_attorney_case_review&.untimely_evidence
      }
    else
      {
        overtime: object.latest_attorney_case_review&.overtime,
        note_from_attorney: object.latest_attorney_case_review&.note,
        untimely_evidence: object.latest_attorney_case_review&.untimely_evidence
      }
    end
  end

  attribute :can_edit_document_id do |object, params|
    AmaDocumentIdPolicy.new(
      user: params[:user],
      case_review: object.latest_attorney_case_review
    ).editable?
  end

  attribute :readable_hearing_request_type, &:readable_current_hearing_request_type

  attribute :readable_original_hearing_request_type, &:readable_original_hearing_request_type

  attribute :docket_switch do |object|
    if object.docket_switch
      WorkQueue::DocketSwitchSerializer.new(object.docket_switch).serializable_hash[:data][:attributes]
    end
  end

  attribute :switched_dockets do |object|
    object.switched_dockets.map do |docket_switch|
      WorkQueue::DocketSwitchSerializer.new(docket_switch).serializable_hash[:data][:attributes]
    end
  end
end
