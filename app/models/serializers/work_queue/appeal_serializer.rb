# frozen_string_literal: true

class WorkQueue::AppealSerializer
  include FastJsonapi::ObjectSerializer
  extend Helpers::AppealHearingHelper

  attribute :assigned_attorney
  attribute :assigned_judge

  attribute :issues do |object|
    object.request_issues.active_or_decided.includes(:remand_reasons).map do |issue|
      {
        id: issue.id,
        program: issue.benefit_type,
        description: issue.description,
        notes: issue.notes,
        diagnostic_code: issue.contested_rating_issue_diagnostic_code,
        remand_reasons: issue.remand_reasons
      }
    end
  end

  attribute :decision_issues do |object|
    object.decision_issues.uniq.map do |issue|
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

  attribute :can_edit_request_issues do |object, params|
    params[:user]&.can_edit_request_issues?(object)
  end

  attribute(:hearings) { |object| hearings(object) }

  attribute :withdrawn, &:withdrawn?

  attribute :assigned_to_location

  attribute :completed_hearing_on_previous_appeal? do
    false
  end

  attribute :appellant_full_name do |object|
    object.claimants[0].name if object.claimants&.any?
  end

  attribute :appellant_address do |object|
    if object.claimants&.any?
      object.claimants[0].address
    end
  end

  attribute :appellant_relationship do |object|
    object.claimants[0].relationship if object.claimants&.any?
  end

  attribute :veteran_file_number

  attribute :veteran_full_name do |object|
    object.veteran ? object.veteran.name.formatted(:readable_full) : "Cannot locate"
  end

  attribute :closest_regional_office

  attribute(:available_hearing_locations) { |object| available_hearing_locations(object) }

  attribute :external_id, &:uuid

  attribute :type do
    "Original"
  end

  attribute :aod, &:advanced_on_docket
  attribute :docket_name
  attribute :docket_number
  attribute :docket_range_date
  attribute :decision_date
  attribute :nod_date, &:receipt_date

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
    {
      overtime: object.latest_attorney_case_review&.overtime,
      note_from_attorney: object.latest_attorney_case_review&.note,
      untimely_evidence: object.latest_attorney_case_review&.untimely_evidence
    }
  end

  attribute :can_edit_document_id do |object, params|
    AmaDocumentIdPolicy.new(
      user: params[:user],
      case_review: object.latest_attorney_case_review
    ).editable?
  end
end
