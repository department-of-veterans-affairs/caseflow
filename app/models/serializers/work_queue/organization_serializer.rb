# frozen_string_literal: true

class WorkQueue::OrganizationSerializer
  include FastJsonapi::ObjectSerializer
  attribute :id
  attribute :name
end
