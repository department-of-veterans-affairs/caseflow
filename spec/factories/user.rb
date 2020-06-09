# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:css_id) { |n| "CSS_ID#{n}" }

    station_id { User::BOARD_STATION_ID }
    full_name { "Lauren Roth" }

    transient do
      vacols_uniq_id { nil }
    end

    factory :default_user do
      css_id { "DEFAULT_USER" }
      full_name { "Lauren Roth" }
      email { "test@example.com" }
      roles { ["Certify Appeal"] }
    end

    factory :hearings_coordinator do
      css_id { "BVATWARNER" }
      full_name { "Thomas Warner" }
      email { "thomas.warner@example.com" }
      roles { ["Assign Hearings"] }
    end

    factory :intake_user do
      css_id { "BVATWARNER" }
      full_name { "Sandra Warner" }
      email { "sandra.warner@example.com" }
      roles { ["Mail Intake"] }
    end

    trait :inactive do
      status { "inactive" }
    end

    trait :vso_role do
      roles { ["VSO"] }
    end

    trait :judge do
      roles { ["Hearing Prep"] }
    end

    trait :with_vacols_judge_record do
      after(:create) do |user|
        create(:staff, :judge_role, user: user)
      end
    end

    trait :with_vacols_attorney_record do
      after(:create) do |user|
        create(:staff, :attorney_role, user: user)
      end
    end

    trait :with_vacols_acting_judge_record do
      after(:create) do |user|
        create(:staff, :attorney_judge_role, user: user)
      end
    end

    after(:create) do |user, evaluator|
      if evaluator.vacols_uniq_id
        create(:staff, slogid: evaluator.vacols_uniq_id, user: user)
      end
    end
  end
end
