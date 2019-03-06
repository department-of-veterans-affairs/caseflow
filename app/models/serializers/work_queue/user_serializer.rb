# frozen_string_literal: true

class WorkQueue::UserSerializer < ActiveModel::Serializer
  attribute :css_id
  attribute :full_name
end
