# frozen_string_literal: true

FactoryBot.define do
  factory :staff, class: VACOLS::Staff do
    transient do
      user { nil }

      generated_sattyid do
        new_sattyid = generate(:sattyid)

        new_sattyid = generate(:sattyid) while VACOLS::Staff.exists?(sattyid: new_sattyid)

        new_sattyid
      end

      judge do
        judge_staff = VACOLS::Staff.find_by(slogid: "STAFF_FCT_JUDGE") ||
                      create(:staff, :judge_role, slogid: "STAFF_FCT_JUDGE")
        judge_staff
      end

      generated_smemgrp_not_equal_to_sattyid do
        judge.sattyid
      end
    end

    sequence(:stafkey) do |n|
      #  STAFKEY has maximum size of 16
      if user && user.css_id.size <= 16
        user.css_id
      else
        n
      end
    end
    sequence(:slogid) do |n|
      # Some tests use this for DECASS.DEMDUSR which has max size of 12
      if user && user.css_id.size <= 12
        user.css_id
      else
        "ID#{n}"
      end
    end
    sequence(:sdomainid) do |n|
      if user
        user.css_id
      else
        "BVA#{n}"
      end
    end

    sactive { "A" }

    trait :inactive do
      sactive { "I" }
    end

    trait :attorney_role do
      sactive { "A" }
      sattyid { generated_sattyid }
    end

    trait :titled_attorney_role do
      attorney_role
      stitle { "D#{Random.rand(1..5)}" }
    end

    # I'm not sure if this reflects real data but it's required for SCM users to see legacy tasks in tests
    trait :scm_role do
      sattyid { generated_sattyid }
    end

    trait :hearing_judge do
      stitle { "D#{Random.rand(1..5)}" }
      svlj { "A" }
      sattyid { generated_sattyid }
    end

    trait :judge_role do
      svlj { "J" }
      sactive { "A" }
      sattyid { generated_sattyid }
    end

    trait :inactive_judge do
      svlj { "J" }
      sactive { "I" }
      sattyid { generated_sattyid }
    end

    trait :inactive_judge do
      svlj { "J" }
      sactive { "I" }
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
      sattyid { generated_sattyid }
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

    trait :has_sattyid do
      svlj { nil }
      sattyid { generated_sattyid }
    end

    trait :non_ssc_avlj do
      svlj { "A" }
      sattyid { generated_sattyid }
      smemgrp { generated_smemgrp_not_equal_to_sattyid }
    end

    trait :inactive_non_ssc_avlj do
      svlj { "A" }
      sactive { "I" }
      sattyid { generated_sattyid }
      smemgrp { generated_smemgrp_not_equal_to_sattyid }
    end

    trait :ssc_avlj do
      svlj { "A" }
      sattyid { generated_sattyid }
      smemgrp { sattyid }
    end

    trait :vlj do
      svlj { "J" }
      sattyid { generated_sattyid }
      smemgrp { sattyid }
    end

    after(:build) do |staff, evaluator|
      if evaluator.user&.full_name
        staff.snamef = evaluator.user.full_name.split(" ").first
        staff.snamel = evaluator.user.full_name.split(" ").last
      end
    end
  end
end
