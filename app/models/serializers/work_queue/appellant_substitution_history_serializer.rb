# frozen_string_literal: true

class WorkQueue::AppellantSubstitutionHistorySerializer
  include FastJsonapi::ObjectSerializer

  attribute :substitution_date
  attribute :original_appellant_veteran_participant_id
  attribute :current_appellant_substitute_participant_id
  attribute :original_appellant_substitute_participant_id
  attribute :current_appellant_veteran_participant_id

  attribute :created_at
  attribute :created_by do |object|
    object.created_by&.full_name
  end

  attribute :original_appellant_full_name do |object|
    object.original_appellant_veteran_participant&.name
  end

  attribute :current_appellant_substitute_full_name do |object|
    object.current_appellant_substitute_participant&.name
  end

  attribute :original_appellant_substitute_full_name do |object|
    object.original_appellant_substitute_participant&.name
  end

  attribute :current_appellant_full_name do |object|
    object.current_appellant_veteran_participant&.name
  end
end
