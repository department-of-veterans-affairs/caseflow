# frozen_string_literal: true

FactoryBot.define do
  factory :mail, class: VACOLS::Mail do
    mltype { "02" }

    trait :blocking do
      mltype { "03" }
    end

    trait :completed do
      mlcompdate { Time.zone.now.to_date }
    end

    trait :incomplete do
      mlcompdate { nil }
    end
  end
end
