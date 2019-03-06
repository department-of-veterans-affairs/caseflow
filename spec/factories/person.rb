# frozen_string_literal: true

FactoryBot.define do
  factory :person do
    sequence(:participant_id)
    date_of_birth { 30.years.ago }
  end
end
