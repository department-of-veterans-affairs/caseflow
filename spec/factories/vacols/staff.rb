FactoryBot.define do
  factory :staff, class: VACOLS::Staff do
    transient do
      user nil
    end

    sequence(:stafkey)
    sequence(:slogid) { |n| "ID#{n}" }
    sequence(:sdomainid) do |n|
      if user
        user.css_id
      else
        "BVA#{n}"
      end
    end

    trait :attorney_role do
      sattyid "123"
      sactive "A"
    end

    trait :judge_role do
      svlj "J"
      sactive "A"
    end

    trait :attorney_judge_role do
      svlj "A"
      sattyid "123"
      sactive "A"
    end

    trait :has_location_code do
      slogid "55"
    end

    after(:build) do |staff, evaluator|
      if evaluator.user && evaluator.user.full_name
        staff.snamef, staff.snamel = evaluator.user.full_name.split(" ")
      end
    end
  end
end
