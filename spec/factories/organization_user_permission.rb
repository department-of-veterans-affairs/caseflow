# frozen_string_literal: true

FactoryBot.define do
  factory :organization_user_permission do
    permitted { false }

    association :organization_permission, factory: :organization_permission
    association :organizations_user, factory: :organizations_user
  end
end
