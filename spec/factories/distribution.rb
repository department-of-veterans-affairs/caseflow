# frozen_string_literal: true

FactoryBot.define do
  factory :distribution do
    association :judge, factory: :user
  end
end
