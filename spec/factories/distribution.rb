# frozen_string_literal: true

FactoryBot.define do
  factory :distribution do
    judge { create(:user) }
  end
end
