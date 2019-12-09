# frozen_string_literal: true

class Intake::JobNoteSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :created_at
  attribute :note

  attribute :user do |object|
    object.user.css_id
  end
end
