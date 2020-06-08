# frozen_string_literal: true

FactoryBot.define do
  factory :staff, class: VACOLS::Staff do
    transient do
      user { nil }
      sequence(:generated_slogid) { |n| "ID#{n}" }
    end

    sequence(:stafkey)
    slogid { generated_slogid }
    sequence(:sdomainid) do |n|
      if user
        user.css_id
      else
        "BVA#{n}"
      end
    end

    sactive { "A" }

    trait :attorney_role do
      sactive { "A" }
      sequence(:sattyid)
    end

    trait :hearing_judge do
      stitle { "D#{Random.rand(1..5)}" }
      svlj { "A" }
    end

    trait :judge_role do
      svlj { "J" }
      sactive { "A" }
      sequence(:sattyid)
    end

    trait :hearing_coordinator do
      sdept { "HRG" }
      sactive { "A" }
      sequence(:snamel) { |n| "Smith#{n}" }
      sequence(:snamef) { |n| "John#{n}" }
      snamemi { "" }
    end

    trait :attorney_judge_role do
      svlj { "A" }
      sactive { "A" }
      sequence(:sattyid)
    end

    trait :colocated_role do
      stitle { %w[A1 A2].sample }
      sactive { "A" }
      sattyid { nil }
    end

    trait :dispatch_role do
      sdept { "DSP" }
      sactive { "A" }
      sattyid { nil }
    end

    trait :has_location_code do
      slogid { "55" }
    end

    after(:build) do |staff, evaluator|
      if evaluator.user&.full_name
        staff.snamef = evaluator.user.full_name.split(" ").first
        staff.snamel = evaluator.user.full_name.split(" ").last
      end
    end
  end
end
