# frozen_string_literal: true

class AppellantSubstitutionHistory < CaseflowRecord
  belongs_to :original_appellant_veteran_participant,
             class_name: "Person", primary_key: :participant_id, optional: true
  belongs_to :current_appellant_substitute_participant,
             class_name: "Person", primary_key: :participant_id, optional: true
  belongs_to :original_appellant_substitute_participant,
             class_name: "Person", primary_key: :participant_id, optional: true
  belongs_to :current_appellant_veteran_participant,
             class_name: "Person", primary_key: :participant_id, optional: true
  belongs_to :appellant_substitution
  belongs_to :created_by, class_name: "User", optional: false
end
