# frozen_string_literal: true

class WorkQueue::CavcRemandsAppellantSubstitutionSerializer
  include FastJsonapi::ObjectSerializer

  attribute :substitution_date
  attribute :participant_id
  attribute :is_appellant_substituted
end
