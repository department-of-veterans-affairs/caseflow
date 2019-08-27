# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    text { "hello world" }
    association :user
  end
end
