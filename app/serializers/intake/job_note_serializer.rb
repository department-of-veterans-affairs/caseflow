# frozen_string_literal: true

class Intake::JobNoteSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :created_at
  attribute :note
  attribute :send_to_intake_user

  attribute :user do |object|
    object.user.css_id
  end
end
