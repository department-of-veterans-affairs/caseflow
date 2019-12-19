# frozen_string_literal: true

class Intake::IntakeSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :form_type
  attribute :veteran_file_number
  attribute :completed_at

  attribute :veteran_form_name do |object|
    object.veteran&.name&.formatted(:form)
  end

  attribute :veteran_name do |object|
    object.veteran&.name&.formatted(:readable_short)
  end

  attribute :veteran_is_deceased do |object|
    object.veteran&.deceased?
  end

  attribute :relationships do |object|
    object.veteran&.relationships&.map(&:serialize)
  end
end
