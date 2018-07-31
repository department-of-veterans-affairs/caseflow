FactoryBot.define do
  factory :task do
    assigned_at { rand(30..35).days.ago }
    assigned_by { create(:user) }
    assigned_to { create(:user) }
    appeal { create(:legacy_appeal, vacols_case: create(:case)) }
    appeal_type "LegacyAppeal"

    trait :in_progress do
      status "in_progress"
      started_at { rand(1..10).days.ago }
    end

    trait :on_hold do
      status "on_hold"
      started_at { rand(20..30).days.ago }
      placed_on_hold_at { rand(1..10).days.ago }
      on_hold_duration [30, 60, 90].sample
    end

    trait :completed do
      status "completed"
      started_at { rand(20..30).days.ago }
      placed_on_hold_at { rand(1..10).days.ago }
      on_hold_duration [30, 60, 90].sample
      completed_at Time.zone.now
    end

    factory :colocated_task do
      type "ColocatedTask"
      title { Constants::CO_LOCATED_ADMIN_ACTIONS.keys.sample }
      instructions "poa is missing"
    end

    factory :ama_colocated_task do
      type "ColocatedTask"
      title { Constants::CO_LOCATED_ADMIN_ACTIONS.keys.sample }
      instructions "poa is missing"
      appeal_type "Appeal"
      appeal { create(:appeal) }
    end

    factory :ama_judge_task do
      type "JudgeTask"
      appeal_type "Appeal"
      assigned_by nil
      appeal { create(:appeal) }
    end

    factory :ama_attorney_task do
      type "AttorneyTask"
      appeal_type "Appeal"
      appeal { create(:appeal) }
    end
  end
end
