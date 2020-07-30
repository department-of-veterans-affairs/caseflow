# frozen_string_literal: true

FactoryBot.define do
  factory :mail, class: VACOLS::Mail do
    mltype { "02" }

    trait :blocking do
      mltype { "03" }
      mlcompdate { nil }
    end

    trait :non_blocking do
      mltype { "03" }
      mlcompdate { Time.zone.now.to_date }
    end
  end
end
