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
      cssId: user.try(:css_id),
      fullName: user.try(:full_name),
      id: user.id
    }
  end
end
