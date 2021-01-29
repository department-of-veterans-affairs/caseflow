# frozen_string_literal: true

class WorkQueue::UserSerializer
  include JSONAPI::Serializer
  attribute :css_id
  attribute :full_name
end
