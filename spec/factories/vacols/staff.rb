FactoryBot.define do
  factory :staff, class: VACOLS::Staff do
    sequence(:stafkey)
    sequence(:slogid) { |n| "ID#{n}" }
    sequence(:sdomainid) { |n| "BVA#{n}" }

    trait :attorney_role do
      svlj "A"
      sattyid "123"
    end

    trait :judge_role do
      svlj "J"
    end

    trait :has_location_code do
      slogid "55"
    end
  end
end
