# frozen_string_literal: true

class Intake::RelationshipSerializer
  include FastJsonapi::ObjectSerializer
  set_id(&:participant_id)

  attribute :participant_id
  attribute :first_name
  attribute :last_name
  attribute :relationship_type
  attribute :default_payee_code
end
