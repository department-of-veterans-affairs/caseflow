# frozen_string_literal: true

FactoryBot.define do
  factory :brieff, class: VACOLS::Brieff do
    transient do
      generated_bfkey do
        new_bfkey = generate(:bfkey)

        new_bfkey = generate(:bfkey) while VACOLS::Brieff.exists?(bfkey: new_bfkey)

        new_bfkey
      end
    end

    sequence(:bfkey) do
      generated_bfkey
    end
    sequence(:bfcorlid) { |n| "CORLID#{n}" }
    bfd19 { Faker::Date.backward(days: 365) } # Random date within the past year
    bfmpro { "HIS" } # Example value
    bfac { "Original" } # Example value
    bfmemid { association :user, :judge } # Assuming bfmemid is a user id of a judge
    bfattid { association :user, :attorney } # Assuming bfattid is a user id of an attorney
    bfddec { Faker::Date.backward(days: 30) } # Random date within the past month

    trait :priority do
      # Set specific attributes for priority cases
      aod { true }
    end

    trait :non_priority do
      # Set specific attributes for non-priority cases
      aod { false }
    end



  #   transient do
  #     user { nil }

  #     generated_sattyid do
  #       new_sattyid = generate(:sattyid)

  #       new_sattyid = generate(:sattyid) while VACOLS::Staff.exists?(sattyid: new_sattyid)

  #       new_sattyid
  #     end

  #     judge do
  #       judge_staff = VACOLS::Staff.find_by(slogid: "STAFF_FCT_JUDGE") ||
  #                     create(:staff, :judge_role, slogid: "STAFF_FCT_JUDGE")
  #       judge_staff
  #     end

  #     generated_smemgrp_not_equal_to_sattyid do
  #       judge.sattyid
  #     end
  #   end

  #   sequence(:stafkey) do |n|
  #     #  STAFKEY has maximum size of 16
  #     if user && user.css_id.size <= 16
  #       user.css_id
  #     else
  #       n
  #     end
  #   end
  #   sequence(:slogid) do |n|
  #     # Some tests use this for DECASS.DEMDUSR which has max size of 12
  #     if user && user.css_id.size <= 12
  #       user.css_id
  #     else
  #       "ID#{n}"
  #     end
  #   end
  #   sequence(:sdomainid) do |n|
  #     if user
  #       user.css_id
  #     else
  #       "BVA#{n}"
  #     end
  #   end

  #   sactive { "A" }

  #   trait :inactive do
  #     sactive { "I" }
  #   end

  #   trait :attorney_role do
  #     sactive { "A" }
  #     sattyid { generated_sattyid }
  #   end

  #   trait :titled_attorney_role do
  #     attorney_role
  #     stitle { "D#{Random.rand(1..5)}" }
  #   end

  #   # I'm not sure if this reflects real data but it's required for SCM users to see legacy tasks in tests
  #   trait :scm_role do
  #     sattyid { generated_sattyid }
  #   end

  #   trait :hearing_judge do
  #     stitle { "D#{Random.rand(1..5)}" }
  #     svlj { "A" }
  #     sattyid { generated_sattyid }
  #   end

  #   trait :judge_role do
  #     svlj { "J" }
  #     sactive { "A" }
  #     sattyid { generated_sattyid }
  #   end

  #   trait :inactive_judge do
  #     svlj { "J" }
  #     sactive { "I" }
  #     sattyid { generated_sattyid }
  #   end

  #   trait :inactive_judge do
  #     svlj { "J" }
  #     sactive { "I" }
  #   end

  #   trait :hearing_coordinator do
  #     sdept { "HRG" }
  #     sactive { "A" }
  #     sequence(:snamel) { |n| "Smith#{n}" }
  #     sequence(:snamef) { |n| "John#{n}" }
  #     snamemi { "" }
  #   end

  #   trait :attorney_judge_role do
  #     svlj { "A" }
  #     sactive { "A" }
  #     sattyid { generated_sattyid }
  #   end

  #   trait :colocated_role do
  #     stitle { %w[A1 A2].sample }
  #     sactive { "A" }
  #     sattyid { nil }
  #   end

  #   trait :dispatch_role do
  #     sdept { "DSP" }
  #     sactive { "A" }
  #     sattyid { nil }
  #   end

  #   trait :has_location_code do
  #     slogid { "55" }
  #   end

  #   trait :has_sattyid do
  #     svlj { nil }
  #     sattyid { generated_sattyid }
  #   end

  #   trait :non_ssc_avlj do
  #     svlj { "A" }
  #     sattyid { generated_sattyid }
  #     smemgrp { generated_smemgrp_not_equal_to_sattyid }
  #   end

  #   after(:build) do |staff, evaluator|
  #     if evaluator.user&.full_name
  #       staff.snamef = evaluator.user.full_name.split(" ").first
  #       staff.snamel = evaluator.user.full_name.split(" ").last
  #     end
  #   end
  # end
end
