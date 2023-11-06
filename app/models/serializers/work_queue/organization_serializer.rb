# frozen_string_literal: true

class WorkQueue::OrganizationSerializer
  include JSONAPI::Serializer
  attribute :id
  attribute :name
end
