# frozen_string_literal: true

class WorkQueue::AppellantSubstitutionSerializer
  include FastJsonapi::ObjectSerializer

  attribute :claimant_type
  attribute :substitution_date
  attribute :substitute_participant_id
  attribute :poa_participant_id
  attribute :target_appeal_id

  attribute :created_at
  attribute :created_by do |object|
    object.created_by&.full_name
  end

  attribute :substitute_full_name do |object|
    object.target_appeal&.claimant&.name
  end

  attribute :original_appellant_full_name do |object|
    object.source_appeal&.claimant&.name
  end

  # Uncomment the following as needed and write corresponding tests

  # attribute :source_appeal_uuid do |object|
  #   object.source_appeal&.uuid
  # end
  attribute :target_appeal_uuid do |object|
    object.target_appeal&.uuid
  end

  # attribute :source_decision_issues do |object|
  #   object.source_appeal&.decision_issues
  # end
end
