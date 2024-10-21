# frozen_string_literal: true

class SavedSearchSerializer
  include FastJsonapi::ObjectSerializer

  attribute :name
  attribute :description
  attribute :saved_search
  attribute :createdAt, &:created_at
  attribute :userCssId do |object|
    object.user.css_id
  end
  attribute :userFullName do |object|
    object.user.full_name
  end
  attribute :userId do |object|
    object.user.id
  end
end
