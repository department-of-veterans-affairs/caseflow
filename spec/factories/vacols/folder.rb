# frozen_string_literal: true

FactoryBot.define do
  factory :folder, class: VACOLS::Folder do
    sequence(:ticknum)
    sequence(:tinum)

    trait :paper_case do
      tivbms { "N" }
      tisubj2 { "N" }
    end
  end
end
