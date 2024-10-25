# frozen_string_literal: true

class SavedSearchSerializer
  include FastJsonapi::ObjectSerializer

  attribute :name
  attribute :description
  attribute :savedSearch, &:saved_search
  attribute :createdAt, &:created_at

  attribute :user do |object|
    user = object.try(:user)
    {
      css_id: user.try(:css_id),
      full_name: user.try(:full_name),
      id: user.id
    }
  end
end
