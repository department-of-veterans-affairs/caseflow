# frozen_string_literal: true

class WorkQueue::NodDateUpdateSerializer
  include FastJsonapi::ObjectSerializer

  attribute :old_date
  attribute :new_date
  attribute :change_reason
  attribute :updated_at
  attribute :updated_by do |object|
    object.user.full_name
  end
end
