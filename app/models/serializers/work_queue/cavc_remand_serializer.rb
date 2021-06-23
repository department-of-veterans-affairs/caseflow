# frozen_string_literal: true

class WorkQueue::CavcRemandSerializer
  include FastJsonapi::ObjectSerializer

  attribute :cavc_decision_type
  attribute :cavc_docket_number
  attribute :cavc_judge_full_name
  attribute :decision_date
  attribute :decision_issue_ids
  attribute :federal_circuit
  attribute :instructions
  attribute :judgement_date
  attribute :mandate_date
  attribute :remand_appeal_id
  attribute :remand_subtype
  attribute :represented_by_attorney

  attribute :source_appeal_uuid do |object|
    object.source_appeal&.uuid
  end
  attribute :remand_appeal_uuid do |object|
    object.remand_appeal&.uuid
  end

  attribute :source_decision_issues do |object|
    object.source_appeal&.decision_issues
  end

  attribute :created_by do |object|
    object.created_by&.full_name
  end

  attribute :updated_by do |object|
    object.updated_by&.full_name
  end
end
