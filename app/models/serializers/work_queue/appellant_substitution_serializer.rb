# frozen_string_literal: true

class WorkQueue::AppellantSubstitutionSerializer
  include FastJsonapi::ObjectSerializer

  attribute :claimant_type
  attribute :substitution_date
  attribute :substitute_participant_id
  attribute :poa_participant_id
  attribute :target_appeal_id

  # Uncomment the following as needed and write corresponding tests

  # attribute :source_appeal_uuid do |object|
  #   object.source_appeal&.uuid
  # end
  # attribute :target_appeal_uuid do |object|
  #   object.target_appeal&.uuid
  # end

  # attribute :source_decision_issues do |object|
  #   object.source_appeal&.decision_issues
  # end

  # attribute :created_by do |object|
  #   object.created_by&.full_name
  # end
end
