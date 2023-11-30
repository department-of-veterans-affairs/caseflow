# frozen_string_literal: true

class Intake::RatingSerializer
  include FastJsonapi::ObjectSerializer
  set_id(&:profile_date)

  attribute :participant_id
  attribute :profile_date
  attribute :promulgation_date
  attribute :issues do |object|
    object.issues.map(&:serialize)
  end

  attribute :decisions do |object|
    object.decisions.map(&:serialize)
  end
end
