# frozen_string_literal: true

class WorkQueue::UserSerializer
  include FastJsonapi::ObjectSerializer
  attribute :css_id
  attribute :full_name
  attribute :email
end
